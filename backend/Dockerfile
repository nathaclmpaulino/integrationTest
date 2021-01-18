FROM golang

WORKDIR /usr/src/app

COPY . ./

RUN go get ./

RUN go build ./

ENTRYPOINT go run main.go