generate certs: `openssl req  -nodes -new -x509  -keyout pomerium.key -out pomerium.cert
`

generate shared_secret: `head -c32 /dev/urandom | base64 > shared_secret.txt`
