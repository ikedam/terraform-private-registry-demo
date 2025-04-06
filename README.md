# 静的コンテンツのサイトによる Terraform のプライベートレジストリーデモ

プライベートレジストリーの構築のデモです。

## 概要

* 独自プロバイダー `example.com/example/hello` をプライベートレジストリーからダウンロードして使用する terraform のデモです。
* `example.com/example/hello` は、 `hello_world` データソースを提供し、 `message` で `Hello, World!` というメッセージを取得できるというシンプルなプロバイダーです。
* 以下の主要なディレクトリー・ファイル構成になっています:
    * [certs](./certs/) : HTTPS サーバーを動作させるための自己署名証明書
        * 本デモのためだけに提供しているので、他の用途に使用しないでください。
    * [example-terraform](./example-terraform/) : 独自プロバイダーを使用する Terraform テンプレート
    * [registry](./registry) : 独自プロバイダーを提供する Web サイト
* プライベートレジストリーは HTTPS で動作している必要があるため、以下のようにしています:
    * docker compose を使用し、 `example.com` というサイトを提供する `nginx` サービスを動作させる。
    * certs/ 以下に生成済みの自己署名証明書を使って HTTPS を動作させる。
    * terraform のコンテナーでは、自己署名証明書を CA 証明書として事前にインストールしておく。
* プライベートレジストリーになる Web サイトを提供する nginx は以下の設定になっています:
    * certs/ 以下に生成済みの自己署名証明書を使って HTTPS を動作させる。
    * `index.json` をインデックスファイルとして使用し、 `https://example.com/providers/example/hello/versions/` などで応答するようにする。
    * `.json` ファイルの Content-Type を `application/json` で応答するように、デフォルトの Content-Type を `application/json` にする。
        * これもっと本当は適当な設定があるような気がする。


## Terraform の動作確認

```
docker compose run --rm terraform init
```

```
docker compose run --rm terraform plan
```

以下のような出力を得られます:

```hcl
Changes to Outputs:
  + message = "Hello, World!"
```

## プライベートレジストリーの再生成

`registry` 以下がプライベートレジストリーとして動作するサイトのコンテンツです。
`build-registry.sh` で生成できます:

```
docker compose run --rm alpine /bin/bash build-registry.sh
```

上記を実行した場合、zip ファイルの署名が変わって lock ファイルと一致しなくなるため、 `example-terraform/.terraform` (あれば) と `example-terraform/.terraform.lock.hcl` を削除してロックファイルを再生成してください:

```
docker compose run --rm terraform providers lock -platform=linux_arm64 -platform=linux_amd64
```
