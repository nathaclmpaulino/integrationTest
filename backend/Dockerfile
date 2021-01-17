FROM golang

WORKDIR /usr/local/back

COPY . ./

RUN go get ./

RUN go build ./

ENTRYPOINT go run main.go