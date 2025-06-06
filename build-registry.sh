#!/bin/bash

set -ex

NAMESPACE="example"
PROVIDER="hello"
VERSION="1.0.0"

# サービスディスカバリーの設定
# https://developer.hashicorp.com/terraform/internals/provider-registry-protocol#service-discovery
mkdir -p registry/.well-known || true
cat <<EOF >registry/.well-known/terraform.json
{
  "providers.v1": "/providers/"
}
EOF

# GPG 鍵の生成
# (これはデモだから都度生成しているが、実際には一度生成した鍵を厳重に管理して利用する)
GPG_USER_ID="Provider Demo <ikedam@example.com>"
gpg --batch --quick-generate-key --passphrase "" \
    "${GPG_USER_ID}" \
    default \
    sign \
    0

GPG_KEY_ID="$(gpg --list-signatures --with-colons "${GPG_USER_ID}"|grep sig |cut -d':' -f5)"
gpg --export-secret-keys --armor "${GPG_KEY_ID}" >/tmp/gpg-private-key.asc

# プロバイダーのビルド
for arch in amd64 arm64; do
  basename="terraform-provider-${PROVIDER}_v${VERSION}_linux_${arch}"
  CGO_ENABLED=0 GOOS=linux GOARCH=${arch} go build \
    -o "build/${basename}" \
    main.go
done

# terraform registry builder でイメージをビルドする
ARCH="$(go env GOARCH)"
curl -Lso /tmp/terraform-registry-builder \
  https://github.com/ikedam/terraform-registry-builder/releases/latest/download/terraform-registry-builder-linux-"${ARCH}"

chmod 755 /tmp/terraform-registry-builder

TFREGBUILDER_GPG_KEY_FILE="/tmp/gpg-private-key.asc" \
  /tmp/terraform-registry-builder \
  build \
  registry/providers/example
