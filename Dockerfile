FROM swift:latest

WORKDIR /package

COPY . ./

RUN ls

RUN dpkg --add-architecture i386
RUN apt-get update
RUN DEBIAN_FRONTEND='noninteractive' apt-get install openssl libssl-dev -y

RUN swift package clean

RUN swift build

CMD ["swift", "test"]
