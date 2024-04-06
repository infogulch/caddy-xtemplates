#!/usr/bin/env bash
set -ex

go tool dist list

rm -rf dist

GITVER="$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)"
VERSION="$(go list -f '{{.Version}}' -m github.com/infogulch/xtemplate@$GITVER)"
LDFLAGS="-X 'github.com/infogulch/xtemplate/app.version=$VERSION'"

GOOS=linux   GOARCH=amd64 go build -ldflags="$LDFLAGS" -buildmode exe -o ./dist/xtemplate-amd64-linux/xtemplate       ./cmd
GOOS=darwin  GOARCH=amd64 go build -ldflags="$LDFLAGS" -buildmode exe -o ./dist/xtemplate-amd64-darwin/xtemplate      ./cmd
GOOS=windows GOARCH=amd64 go build -ldflags="$LDFLAGS" -buildmode exe -o ./dist/xtemplate-amd64-windows/xtemplate.exe ./cmd

docker build -t "xtemplate:$VERSION" --build-arg LDFLAGS="$LDFLAGS" .

# Get version from image to spot check that the binary can run:
echo "Build docker image with version: $(docker run -i --rm "xtemplate:$VERSION" --version)"

cd dist

printf '%s\n' * | while read D; do
    cp ../README.md ../LICENSE "$D"
    tar czvf "${D}_$VERSION.tar.gz" "$D/"
    zip -r9 "${D}_$VERSION.zip" "$D/"
    rm -r "$D"
done

cd -

ls -lh dist/*
