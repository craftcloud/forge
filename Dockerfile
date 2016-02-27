FROM java:8

MAINTAINER XiNGRZ <xxx@oxo.ooo>

ENV APT_GET_UPDATE 2015-10-03
RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libmozjs-24-bin imagemagick lsof && apt-get clean
RUN update-alternatives --install /usr/bin/js js /usr/bin/js24 100

RUN wget -O /usr/bin/jsawk https://github.com/micha/jsawk/raw/master/jsawk
RUN chmod +x /usr/bin/jsawk

COPY start-minecraft.sh /start-minecraft

RUN mkdir /data && mkdir /mods && mkdir /config

VOLUME ["/data"]
VOLUME ["/mods"]
VOLUME ["/config"]

COPY server.properties /tmp/server.properties

EXPOSE 25565
WORKDIR /data

CMD [ "/start-minecraft" ]
