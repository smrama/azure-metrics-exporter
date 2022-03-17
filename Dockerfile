FROM golang:1.17-alpine as build

USER root

# To be able to download `ca-certificates` with `apk add` command
# COPY /usr/local/share/ca-certificates/aks.crt /root/aks.crt
# COPY /usr/local/share/ca-certificates/maven_repo.crt /root/maven_repo.crt
# COPY /usr/local/share/ca-certificates/proxy_golang.crt /root/proxy_golang.crt
COPY ./zscaler-root.crt /root/zscaler-root.crt

# RUN cat /root/aks.crt >> /etc/ssl/certs/ca-certificates.crt
# RUN cat /root/ca.crt >> /etc/ssl/certs/ca-certificates.crt
# RUN cat /root/my-root-ca.crt >> /etc/ssl/certs/ca-certificates.crt
RUN cat /root/zscaler-root.crt >> /etc/ssl/certs/ca-certificates.crt

# Add again root CA with `update-ca-certificates` tool
RUN apk --no-cache add ca-certificates \
    && rm -rf /var/cache/apk/*
COPY ./zscaler-root.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

RUN apk --no-cache add curl
RUN apk upgrade --no-cache --force
RUN apk add --update build-base make git

WORKDIR /go/src/github.com/webdevops/azure-metrics-exporter

# Compile
COPY ./ /go/src/github.com/webdevops/azure-metrics-exporter
RUN make dependencies
RUN make test
RUN make build
RUN ./azure-metrics-exporter --help

#############################################
# FINAL IMAGE
#############################################
FROM gcr.io/distroless/static
ENV LOG_JSON=1
COPY --from=build /go/src/github.com/webdevops/azure-metrics-exporter/azure-metrics-exporter /
USER 1000:1000
ENTRYPOINT ["/azure-metrics-exporter"]
