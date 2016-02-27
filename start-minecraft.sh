#!/bin/bash

umask 002

if [ ! -e /data/eula.txt ]; then
  if [ "$EULA" != "" ]; then
    echo "# Generated via Docker on $(date)" > eula.txt
    echo "eula=$EULA" >> eula.txt
  else
    echo ""
    echo "Please accept the Minecraft EULA at"
    echo "  https://account.mojang.com/documents/minecraft_eula"
    echo "by adding the following immediately after 'docker run':"
    echo "  -e EULA=TRUE"
    echo ""
    exit 1
  fi
fi

echo "Checking version information."
case "X$VERSION" in
  X|XLATEST|Xlatest)
    VANILLA_VERSION=`wget -O - https://s3.amazonaws.com/Minecraft.Download/versions/versions.json | jsawk -n 'out(this.latest.release)'`
  ;;
  XSNAPSHOT|Xsnapshot)
    VANILLA_VERSION=`wget -O - https://s3.amazonaws.com/Minecraft.Download/versions/versions.json | jsawk -n 'out(this.latest.snapshot)'`
  ;;
  X[1-9]*)
    VANILLA_VERSION=$VERSION
  ;;
  *)
    VANILLA_VERSION=`wget -O - https://s3.amazonaws.com/Minecraft.Download/versions/versions.json | jsawk -n 'out(this.latest.release)'`
  ;;
esac

cd /data

echo "Checking Forge version information."
case "X$FORGEVERSION" in
    X|XRECOMMENDED)
	    FORGE_VERSION=`wget -O - http://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json | jsawk -n "out(this.promos['$VANILLA_VERSION-recommended'])"`
    ;;

    *)
	    FORGE_VERSION=$FORGEVERSION
    ;;
esac

# URL format changed for 1.7.10 from 10.13.2.1300
sorted=$((echo $FORGE_VERSION; echo 10.13.2.1300) | sort -V | head -1)
if [[ $VANILLA_VERSION == '1.7.10' && $sorted == '10.13.2.1300' ]]; then
    # if $FORGEVERSION >= 10.13.2.1300
    forgeVersion="$VANILLA_VERSION-$FORGE_VERSION-$VANILLA_VERSION"
else
    forgeVersion="$VANILLA_VERSION-$FORGE_VERSION"
fi

FORGE_INSTALLER="forge-$forgeVersion-installer.jar"
SERVER="forge-$forgeVersion-universal.jar"

if [ ! -e "$SERVER" ]; then
  echo "Downloading $FORGE_INSTALLER ..."
  wget -q http://files.minecraftforge.net/maven/net/minecraftforge/forge/$forgeVersion/$FORGE_INSTALLER
  echo "Installing $SERVER"
  java -jar $FORGE_INSTALLER --installServer
fi


# If supplied with a URL for a world, download it and unpack
if [[ "$WORLD" ]]; then
case "X$WORLD" in
  X[Hh][Tt][Tt][Pp]*)
    echo "Downloading world via HTTP"
    echo "$WORLD"
    wget -q -O - "$WORLD" > /data/world.zip
    echo "Unzipping word"
    unzip -q /data/world.zip
    rm -f /data/world.zip
    if [ ! -d /data/world ]; then
      echo World directory not found
      for i in /data/*/level.dat; do
        if [ -f "$i" ]; then
          d=`dirname "$i"`
          echo Renaming world directory from $d
          mv -f "$d" /data/world
        fi
      done
    fi
    if [ "$TYPE" = "SPIGOT" ]; then
      # Reorganise if a Spigot server
      echo "Moving End and Nether maps to Spigot location"
      [ -d "/data/world/DIM1" ] && mv -f "/data/world/DIM1" "/data/world_the_end"
      [ -d "/data/world/DIM-1" ] && mv -f "/data/world/DIM-1" "/data/world_nether"
    fi
    ;;
  *)
    echo "Invalid URL given for world: Must be HTTP or HTTPS and a ZIP file"
    ;;
esac
fi

# If supplied with a URL for a modpack (simple zip of jars), download it and unpack
if [[ "$MODPACK" ]]; then
case "X$MODPACK" in
  X[Hh][Tt][Tt][Pp]*[Zz][iI][pP])
    echo "Downloading mod/plugin pack via HTTP"
    echo "$MODPACK"
    wget -q -O /tmp/modpack.zip "$MODPACK"
    if [ "$TYPE" = "SPIGOT" ]; then
      mkdir -p /data/plugins
      unzip -d /data/plugins /tmp/modpack.zip
    else
      mkdir -p /data/mods
      unzip -d /data/mods /tmp/modpack.zip
    fi
    rm -f /tmp/modpack.zip
    ;;
  *)
    echo "Invalid URL given for modpack: Must be HTTP or HTTPS and a ZIP file"
    ;;
esac
fi

if [ -n "$ICON" -a ! -e server-icon.png ]; then
  echo "Using server icon from $ICON..."
  # Not sure what it is yet...call it "img"
  wget -q -O /tmp/icon.img $ICON
  specs=$(identify /tmp/icon.img | awk '{print $2,$3}')
  if [ "$specs" = "PNG 64x64" ]; then
    mv /tmp/icon.img /data/server-icon.png
  else
    echo "Converting image to 64x64 PNG..."
    convert /tmp/icon.img -resize 64x64! /data/server-icon.png
  fi
fi

# If any modules have been provided, copy them over
[ -d /data/mods ] || mkdir /data/mods
for m in /mods/*.jar
do
  if [ -f "$m" ]; then
    echo Copying mod `basename "$m"`
    cp -f "$m" /data/mods
  fi
done
[ -d /data/config ] || mkdir /data/config
for c in /config/*
do
  if [ -f "$c" ]; then
    echo Copying configuration `basename "$c"`
    cp -rf "$c" /data/config
  fi
done

exec java $JVM_OPTS -jar $SERVER
