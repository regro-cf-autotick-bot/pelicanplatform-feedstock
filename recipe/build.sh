#!/bin/bash

set -ex

export CGO_ENABLED=0
export CLIENT_TAGS="forceposix,client"

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

# build and install
go build \
  -a \
  -ldflags "${LDFLAGS}" \
  -tags ${CLIENT_TAGS} \
  -p ${CPU_COUNT} \
  -v \
  -o "${PREFIX}/bin/pelican" \
  ./cmd

# generate the license pack
export GOFLAGS="-tags=${CLIENT_TAGS}"
go get ./...
go-licenses save \
  --ignore "modernc.org/mathutil" \
  --ignore "github.com/jmespath/go-jmespath" \
  --ignore "go.opentelemetry.io/otel/exporters/jaeger/internal/third_party/thrift/lib/go/thrift" \
  --save_path license-files \
  ./cmd
