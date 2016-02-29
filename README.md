A base image to setup a Minecraft Server (with Forge).

## To run with `docker` directly

```sh
docker run -i \
  -p 25565:25565 \
  -v /path/to/data:/data \
  -e 'EULA=TRUE' \
  craftcloud/forge:1.7.10
```

Options:

- `-p PORT:25565` - Forward port `25565` (which the game server listens on) to your host's `PORT`
- `-v PATH_TO_DATA:/data` - Mount `PATH_TO_DATA` on your host to `/data` in the container, which the game data (saves, configs) would be saved in
- `-e 'EULA=TRUE'` To tell you're accepting the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula)

## To build images based on this image

```Dockerfile
FROM craftcloud/forge:1.7.10

ENV EULA TRUE

# Use your custom server.properties
COPY server.properties /server.properties

# Add /mods of your repo into the image
COPY mods /mods
# or download a modpack
# ENV MODPACK "http://....."

# Download a world save
# ENV WORLD "http://...."
```

Remember to mount `/data` to a storage volume to persistent your saves!
