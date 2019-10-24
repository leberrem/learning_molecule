#!/bin/bash

if [ -z $1 ]; then
    echo "please enter certificate name as parameter"
    echo "create_certificate.sh default"
    exit 1
else
    name=$1
fi

validity=11499

openssl genrsa -out ${name}.key 2048
openssl req -new -key ${name}.key -out ${name}.csr -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=${name}.com"
openssl x509 -req -days ${validity} -in ${name}.csr -signkey ${name}.key -out ${name}.crt
cat ${name}.key ${name}.crt > ${name}.pem

rm -f ${name}.crt ${name}.csr ${name}.key

openssl x509 -enddate -noout -in ${name}.pem