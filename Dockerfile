FROM swift:latest

WORKDIR /package

COPY . ./

RUN swift package clean

CMD ["swift", "test"]