NOTE: private keys in this directory are just for demonstration purposes. DO NOT use for other purposes.



Created with:

```
docker compose run --rm alpine openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout certs/server.key -out certs/server.crt -subj "/CN=example.com" -addext subjectAltName=DNS:example.com
```
