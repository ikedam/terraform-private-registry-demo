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

# バージョン一覧ファイル
# https://developer.hashicorp.com/terraform/internals/provider-registry-protocol#list-available-versions
mkdir -p "registry/providers/${NAMESPACE}/${PROVIDER}/versions" || true
cat <<EOF >"registry/providers/${NAMESPACE}/${PROVIDER}/versions/index.json"
{
  "versions": [
    {
      "version": "${VERSION}",
      "protocols": ["6.0"],
      "platforms": [
        {"os": "linux", "arch": "amd64"},
        {"os": "linux", "arch": "arm64"}
      ]
    }
  ]
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
GPG_ASCII_ARMOR="$(gpg --armor --export "${GPG_USER_ID}" | jq -Rs -c .)"

# プロバイダーの作成とパッケージ情報
# https://developer.hashicorp.com/terraform/internals/provider-registry-protocol#find-a-provider-package
for arch in amd64 arm64; do
  archdir="registry/providers/${NAMESPACE}/${PROVIDER}/${VERSION}/download/linux/${arch}"
  basename="terraform-provider-${PROVIDER}_${VERSION}_linux_${arch}"
  mkdir -p "${archdir}" || true
  CGO_ENABLED=0 GOOS=linux GOARCH=${arch} go build \
    -o "${archdir}/${basename}" \
    main.go
  pushd "${archdir}"
  zip "${basename}.zip" "${basename}"
  sha256sum "${basename}.zip" > "${basename}_SHA256SUMS"
  gpg --batch --yes --output "${basename}_SHA256SUMS.sig" --detach-sig "${basename}_SHA256SUMS"
  cat <<EOF >index.json
{
  "protocols": [
    "6.0"
  ],
  "os": "linux",
  "arch": "${arch}",
  "filename": "${basename}.zip",
  "download_url": "${basename}.zip",
  "shasums_url": "${basename}_SHA256SUMS",
  "shasums_signature_url": "${basename}_SHA256SUMS.sig",
  "shasum": "$(cat ${basename}_SHA256SUMS| awk '{print $1}')",
  "signing_keys": {
    "gpg_public_keys": [
      {
        "key_id": "${GPG_KEY_ID}",
        "ascii_armor": ${GPG_ASCII_ARMOR}
      }
    ]
  }
}
EOF
  popd
done
