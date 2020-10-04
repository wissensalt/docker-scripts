FROM golang:alpine

# update and upgrade base image
RUN apk update
RUN apk upgrade

# add git into image, this git is used by [go get] command
RUN apk add git

ENV GOBIN /go/bin

COPY main.go /bin/app/main.go
WORKDIR /bin/app

RUN go get .

ENTRYPOINT ["go", "run", "main.go"]
EXPOSE 8081/tcp