#!/bin/bash

# Set the specific domain name for the certificate
echo "Please Provide the KNIME Business HUB Domain Name. Example(hub.example.com), you can also refer the URL(domain name) from the KOTS console"
echo "Please enter the Domain Name:"
read domain
DOMAIN_NAME="$domain"

# Creating a Directory to place all the certificate files.
mkdir HUBCertificates
# Creating the CSR Config File with all the HUB domains  
echo  "[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
[ dn ]
C = EU
ST = EU
L = EU
O = KNIME
OU = KNIME
CN = $domain
[ req_ext ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = $domain
DNS.2 = auth.$domain
DNS.3 = api.$domain
DNS.4 = apps.$domain
DNS.5 = storage.$domain
DNS.6 = ws.$domain
DNS.7 = registry.$domain
DNS.8 = apps.$domain" > HUBCertificates/csr.conf



# Set the validity period of the certificate in days (default: 365)
VALIDITY_DAYS=365

#Generating the RootCA.crt and RootCA.key
sleep 2
echo "Generating the RootCA.crt and RootCA.key" 
openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -subj "/CN=$domain/C=EU/L=EU" -keyout HUBCertificates/rootCA.key -out HUBCertificates/rootCA.crt


# Generate a private key with 2048 bits
sleep 1
echo "Generate a private key with 2048 bits"
openssl genrsa -out HUBCertificates/server.key 2048

# Unencrypt the Keyfile
sleep 1
echo "Unencrypting the Keyfile"
openssl rsa -in HUBCertificates/server.key -out HUBCertificates/server.key

# Create a certificate signing request (CSR) for the specific domain
sleep 1
echo "Create a certificate signing request (CSR) for the provided domain name"
openssl req -new -key HUBCertificates/server.key -out HUBCertificates/server.csr -config HUBCertificates/csr.conf

# Generate a self-signed certificate for the specific domain
sleep 1
echo "Generate a self-signed certificate for the specific domain and the Subject alternative names"
openssl x509 -req -debug -in HUBCertificates/server.csr -CA HUBCertificates/rootCA.crt -CAkey HUBCertificates/rootCA.key -CAcreateserial -out HUBCertificates/server.crt -days 365 -sha256 -extensions req_ext -extfile HUBCertificates/csr.conf

# Display some information about the certificate
sleep 1
#echo "Displaying the contents of the certificate"
#openssl x509 -in server.crt -text -noout

# Converting the HUB Certificate into the PEM file
sleep 1
echo "Convert the HUB Certificate into the PEM file"
openssl x509 -in HUBCertificates/server.crt -out HUBCertificates/server.pem -outform PEM

# Converting the Root Certificate into the PEM file
sleep 1
echo "Convert the Root Certificate into the PEM file"
openssl x509 -in HUBCertificates/rootCA.crt -out HUBCertificates/rootCA.pem -outform PEM

# Creating the Chain.PEM file with the rootCA content
sleep 1
echo "creating the chain certificate"
cat HUBCertificates/server.pem HUBCertificates/rootCA.pem > HUBCertificates/HUBChainCert.pem

echo "Created self-signed certificate for: $DOMAIN_NAME"
echo "Validity: $VALIDITY_DAYS days"
echo "Certificate file: HUBChainCert.pem"
echo "Private key file: server.key"
sleep 5
echo "Displaying the Contents of the Certificate"
openssl x509 -noout -text -in HUBCertificates/server.pem | grep DNS:
sleep 5
echo "-------------------------------------------"

echo "**Important Note:**"
echo "This self-signed certificate will only be valid for '$DOMAIN_NAME'."
echo "Browsers might display warnings when accessing the website."
echo "In order to avoid browser showing the warnings, please install the Root and HUB certificate on your Local Machine's Trust Store"
echo "Next Steps would be to add the Certificates to the KOTS Admin console -> Network -> Enable TLS "

# Zipping the Certificates
echo "Creating the Zip Folder called HUBCerts.zip and its located at HUBCertificates Folder"
sleep 2
zip -q HUBCertificates/HUBCerts.zip HUBCertificates/HUBChainCert.pem HUBCertificates/server.key HUBCertificates/server.crt HUBCertificates/rootCA.crt



