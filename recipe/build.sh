#!/bin/bash

set -ex

export CGO_ENABLED=0

# dynamically generate content
GOARCH="" GOOS="" go generate ./...

# set variables for build
CONFIG_PKG="github.com/pelicanplatform/pelican/version"
LDFLAGS="
  -s
  -w
  -X ${CONFIG_PKG}.version=${PKG_VERSION}
  -X ${CONFIG_PKG}.commit=v${PKG_VERSION}
  -X ${CONFIG_PKG}.date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  -X ${CONFIG_PKG}.builtBy=conda-forge
"

# build client
go build \
  -a \
  -ldflags "${LDFLAGS}" \
  -tags forceposix,client \
  -p ${CPU_COUNT} \
  -v \
  -o "${PREFIX}/bin/pelican" \
  ./cmd

# build server
go build \
  -a \
  -ldflags "${LDFLAGS}" \
  -tags "forceposix,server" \
  -p ${CPU_COUNT} \
  -v \
  -o "${PREFIX}/bin/pelican-server" \
  ./cmd

# generate the license pack
go get ./...
for tag in client server; do
  export GOFLAGS="-tags=forceposix,${tag}"
  go-licenses save \
    --ignore "modernc.org/mathutil" \
    --ignore "github.com/jmespath/go-jmespath" \
    --ignore "go.opentelemetry.io/otel/exporters/jaeger/internal/third_party/thrift/lib/go/thrift" \
    --save_path ${tag}-licenses \
    ./cmd
done
