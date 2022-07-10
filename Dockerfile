FROM ubuntu:latest

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install curl unzip
RUN curl -L https://tarantool.io/release/2/installer.sh | bash && DEBIAN_FRONTEND=noninteractive apt-get -y install tarantool
WORKDIR /app

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libvips libvips-dev
RUN tarantoolctl rocks install --server=https://luarocks.org/ multipart && tarantoolctl rocks install http && tarantoolctl rocks install --server=https://luarocks.org/ lua-vips

COPY main.lua ./
COPY public public/

CMD ["/bin/tarantool", "/app/main.lua"]
