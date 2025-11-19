```shell
cd lab-certs
ls 
# you should see some pre-configured files and rootCA
# (rootCA.key rootCA.pem server_openssl.cnf v3ext.cnf)
# and later you have to modify those files to generate your own certificates

# create a server key
openssl genrsa -out server.key 2048

# generate CSR
# modify file server_openssl.cnf, and replace <server_ip> with your actual server's ip
[ req ]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = req_ext
prompt = no

[ req_distinguished_name ]
C = LU
ST = Luxembourg
L = Luxembourg
O = SECAN-Lab
CN = victim.com

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = victim.com
IP.1  = <server_ip>

# create csr
openssl req -new -key server.key -out server.csr -config server_openssl.cnf

# (optional) verify the name is correct
openssl req -in server.csr -noout -text | grep -A2 "Subject Alternative Name"

# modify file v3ext.cnf, and replace <server_ip> with your actual server's ip
subjectAltName = @alt_names
[alt_names]
DNS.1 = victim.com
IP.1  = <server_ip>

# sign
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key \
  -CAcreateserial -out server.crt -days 365 -sha256 -extfile v3ext.cnf

# (optional) verify the signature is correct
openssl x509 -in server.crt -noout -subject -issuer -dates
openssl x509 -in server.crt -noout -text | grep -A2 "Subject Alternative Name"
openssl verify -CAfile rootCA.pem server.crt   # should print: server.crt: OK

# copy these self-signed certificates into nginx
sudo mkdir -p /etc/nginx/ssl
# assume server.crt, server.key, rootCA.pem are in ~/lab-certs
sudo cp ~/lab-certs/server.crt /etc/nginx/ssl/
sudo cp ~/lab-certs/server.key  /etc/nginx/ssl/
sudo cp ~/lab-certs/rootCA.pem  /etc/nginx/ssl/
sudo chown root:root /etc/nginx/ssl/*
sudo chmod 600 /etc/nginx/ssl/server.key

# create a https entry in nginx server
sudo vim /etc/nginx/sites-available/lab-https.conf
# add followings to the .conf
server {
    listen 443 ssl;
    server_name victim.com;

    ssl_certificate     /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_pass http://127.0.0.1:8000;
    }
}

# reload nginx
sudo ln -s /etc/nginx/sites-available/lab-https.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```
