#!/bin/bash

echo "Preparing environment..."

DEBIAN_FRONTEND="noninteractive"

apt-get update
apt-get install -y libmozjs-24-bin imagemagick lsof && apt-get clean
update-alternatives --install /usr/bin/js js /usr/bin/js24 100

wget -O /usr/bin/jsawk "https://github.com/micha/jsawk/raw/master/jsawk"
chmod +x /usr/bin/jsawk

VERSIONS_VANILLA="https://s3.amazonaws.com/Minecraft.Download/versions/versions.json"
VERSIONS_FORGE="http://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json"

echo "Checking version information..."
case "X$VERSION" in
  X[1-9]*)
    VANILLA_VERSION=$VERSION
  ;;
  XSNAPSHOT|Xsnapshot)
    VANILLA_VERSION=`wget -O - $VERSIONS_VANILLA | jsawk -n 'out(this.latest.snapshot)'`
  ;;
  *)
    VANILLA_VERSION=`wget -O - $VERSIONS_VANILLA | jsawk -n 'out(this.latest.release)'`
  ;;
esac

echo "Checking Forge version information for $VANILLA_VERSION..."
case "X$FORGEVERSION" in
    X|XRECOMMENDED)
	    FORGE_VERSION=`wget -O - $VERSIONS_FORGE | jsawk -n "out(this.promos['$VANILLA_VERSION-recommended'])"`
    ;;
    *)
	    FORGE_VERSION=$FORGEVERSION
    ;;
esac

# URL format changed for 1.7.10 from 10.13.2.1300
sorted=$((echo $FORGE_VERSION; echo 10.13.2.1300) | sort -V | head -1)
if [[ $VANILLA_VERSION == '1.7.10' && $sorted == '10.13.2.1300' ]]; then
    # if $FORGEVERSION >= 10.13.2.1300
    forge="$VANILLA_VERSION-$FORGE_VERSION-$VANILLA_VERSION"
else
    forge="$VANILLA_VERSION-$FORGE_VERSION"
fi

FORGE_INSTALLER="forge-$forge-installer.jar"
FORGE_SERVER="forge-$forge-universal.jar"

echo "Downloading $FORGE_INSTALLER ..."
wget "http://files.minecraftforge.net/maven/net/minecraftforge/forge/$forge/$FORGE_INSTALLER"
echo "Installing $FORGE_SERVER"
java -jar "$FORGE_INSTALLER" --installServer

rm -f "$FORGE_INSTALLER"
rm -f "$FORGE_INSTALLER.log"
mv -f "$FORGE_SERVER" "server.jar"
