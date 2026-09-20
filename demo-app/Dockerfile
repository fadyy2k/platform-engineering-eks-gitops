# syntax=docker/dockerfile:1.7
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY main.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/platform-demo ./main.go

FROM scratch
COPY --from=build /out/platform-demo /platform-demo
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/platform-demo"]
