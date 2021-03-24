FROM swift:latest

WORKDIR /package

COPY . ./

RUN ls

RUN swift package clean

RUN swift build

CMD ["swift", "test"]
