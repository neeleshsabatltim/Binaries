#!/bin/bash

read -p "Are you working with Java or Python or powershell? (java/python/powershell): " MODULE_TYPE

PASSWORD="changeit"


####### powershell Certificate Generation #######

if [[ "$MODULE_TYPE" == "powershell" ]]; then
  if [ ! -f powershell-modules.txt ]; then
    echo "❌ powershell-modules.txt not found. Exiting."
    exit 1
  fi

  echo "🔧 Processing powershell modules..."
  while IFS= read -r MODULE_NAME; do
    DIR="/app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/${MODULE_NAME}_ssl_cert"
    ALIAS="${MODULE_NAME}_alias"
    CONF_FILE="${DIR}/${MODULE_NAME}.conf"
    CLIENT_KEY="${DIR}/${MODULE_NAME}-client.key"
    CLIENT_CSR="${DIR}/${MODULE_NAME}-client.csr"
    CLIENT_CRT="${DIR}/${MODULE_NAME}-client.crt"
    CLIENT_PFX="${DIR}/${MODULE_NAME}-client.pfx"
    SERVER_KEY="${DIR}/${MODULE_NAME}-server.key"
    SERVER_CSR="${DIR}/${MODULE_NAME}-server.csr"
    SERVER_CRT="${DIR}/${MODULE_NAME}-server.crt"
    SERVER_PFX="${DIR}/${MODULE_NAME}-server.pfx"
    SECRET_NAME="${MODULE_NAME}-cert"

    # Skip if all files already exist
    if [ -d "$DIR" ] && [ -f "$CONF_FILE" ] && [ -f "$KEY_FILE" ] && [ -f "$CSR_FILE" ] && [ -f "$CRT_FILE" ] && [ -f "$P12_FILE" ] && [ -f "$JKS_FILE" ]; then
      echo "All required files already exist for $MODULE_NAME. Skipping..."
      continue
    fi

    mkdir -p "$DIR"

    echo "🔧 Generating config for $MODULE_NAME..."

    cat > "$CONF_FILE" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = IN
ST = Karnataka
L = Bangalore
O = LTIMINDTREE
OU = AINATIVE
CN = ${MODULE_NAME}

[v3_req]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:TRUE
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${MODULE_NAME}
EOF

    echo "🔐 Generating certificate for $MODULE_NAME..."

    openssl genrsa -out "$CLIENT_KEY" 2048
    
    openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -config "$CONF_FILE"
    
    openssl x509 -req -in "$CLIENT_CSR" -CA /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt -CAkey /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.key -CAcreateserial -out "$CLIENT_CRT" -days 365 -sha256 -extfile "$CONF_FILE" -extensions v3_req
    
    openssl pkcs12 -export -out "$CLIENT_PFX" -inkey "$CLIENT_KEY" -in "$CLIENT_CRT" -certfile /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt -password pass:"$PASSWORD"
    
    
    openssl genrsa -out "$SERVER_KEY" 2048
    
    openssl req -new -key "$SERVER_KEY" -out "$SERVER_CSR" -config "$CONF_FILE"
    
    openssl x509 -req -in "$SERVER_CSR" -CA /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt -CAkey /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.key -CAcreateserial -out "$SERVER_CRT" -days 365 -sha256 -extfile "$CONF_FILE" -extensions v3_req
    
    openssl pkcs12 -export -out "$SERVER_PFX" -inkey "$SERVER_KEY" -in "$SERVER_CRT" -certfile /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt -password pass:"$PASSWORD"
    
    
    echo "📦 Creating Kubernetes secret for $MODULE_NAME..."
    
    kubectl create secret generic "$SECRET_NAME" --from-file=server.pfx="$SERVER_PFX" --from-file=client.pfx="$CLIENT_PFX" --from-file=ca.crt=/app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt --from-literal=SERVER_PFX_PASSWORD="$PASSWORD" --from-literal=CLIENT_PFX_PASSWORD="$PASSWORD"
    
    echo "✅ poweshell secret created for module: $MODULE_NAME"
  
  done < powershell-modules.txt


####### Java Certificate Generation #######

elif [[ "$MODULE_TYPE" == "java" ]]; then
  if [ ! -f java-modules.txt ]; then
    echo "❌ java-modules.txt not found. Exiting."
    exit 1
  fi

  echo "🔧 Processing Java modules..."
  while IFS= read -r MODULE_NAME; do
    DIR="/app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/${MODULE_NAME}_ssl_cert"
    ALIAS="${MODULE_NAME}_alias"
    CONF_FILE="${DIR}/${MODULE_NAME}.conf"
    KEY_FILE="${DIR}/${MODULE_NAME}.key"
    CSR_FILE="${DIR}/${MODULE_NAME}.csr"
    CRT_FILE="${DIR}/${MODULE_NAME}.crt"
    P12_FILE="${DIR}/${MODULE_NAME}.p12"
    JKS_FILE="${DIR}/${MODULE_NAME}-keystore.jks"
    SECRET_NAME="${MODULE_NAME}-keystore"

    # Skip if all files already exist
    if [ -d "$DIR" ] && [ -f "$CONF_FILE" ] && [ -f "$KEY_FILE" ] && [ -f "$CSR_FILE" ] && [ -f "$CRT_FILE" ] && [ -f "$P12_FILE" ] && [ -f "$JKS_FILE" ]; then
      echo "All required files already exist for $MODULE_NAME. Skipping..."
      continue
    fi

    mkdir -p "$DIR"

    echo "🔧 Generating config for $MODULE_NAME..."

    cat > "$CONF_FILE" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = IN
ST = Karnataka
L = Bangalore
O = LTIMINDTREE
OU = AINATIVE
CN = ${MODULE_NAME}

[v3_req]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:TRUE
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${MODULE_NAME}
EOF

    echo "🔐 Generating certificate for $MODULE_NAME..."
    openssl genrsa -out "$KEY_FILE" 2048 || exit 1
    openssl req -new -key "$KEY_FILE" -out "$CSR_FILE" -config "$CONF_FILE" || exit 1
    openssl x509 -req -in "$CSR_FILE" -CA /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt \
      -CAkey /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.key -CAcreateserial \
      -out "$CRT_FILE" -days 365 -sha256 -extfile "$CONF_FILE" -extensions v3_req || exit 1
    openssl pkcs12 -export -in "$CRT_FILE" -inkey "$KEY_FILE" -out "$P12_FILE" -name "$ALIAS" -password pass:$PASSWORD || exit 1
    keytool -importkeystore -srckeystore "$P12_FILE" -srcstoretype PKCS12 -destkeystore "$JKS_FILE" -deststoretype JKS \
      -srcstorepass "$PASSWORD" -deststorepass "$PASSWORD" || exit 1

    echo "📦 Creating Kubernetes secret for $MODULE_NAME..."
    kubectl create secret generic "$SECRET_NAME" --from-file="$JKS_FILE" --from-literal=keystore-password="$PASSWORD" || exit 1

    echo "✅ Java keystore and secret created for module: $MODULE_NAME"
  done < java-modules.txt

####### Python Certificate Generation #######

elif [[ "$MODULE_TYPE" == "python" ]]; then
  if [ ! -f python-modules.txt ]; then
    echo "❌ python-modules.txt not found. Exiting."
    exit 1
  fi

  echo "🐍 Processing Python modules..."
  read -p "Is the CA full bundle PEM already generated? (yes/no): " PEM_EXISTS
  keystorepass=$(kubectl get secret ainative-internal-truststore -o yaml | grep "password:" | cut -f 2 -d ":" | sed 's/ //g' | base64 -d) || exit 1

  if [[ "$PEM_EXISTS" =~ ^[Nn][Oo]$ ]]; then
    keytool -importkeystore -srckeystore "ainative-internal-truststore.jks" -destkeystore ainative-internal-truststore.p12 \
      -srcstoretype JKS -deststoretype PKCS12 -srcstorepass "$keystorepass" -deststorepass "$keystorepass" || exit 1
    openssl pkcs12 -in ainative-internal-truststore.p12 -nokeys -out full-ca-bundle.pem -passin pass:"$keystorepass" || exit 1
    kubectl create secret generic ainative-internal-truststore-pem --from-file=./full-ca-bundle.pem || exit 1
    echo "✅ CA full bundle PEM generated and secret created."
  fi

  while IFS= read -r MODULE_NAME; do
    DIR="/app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/${MODULE_NAME}_ssl_cert"
    ALIAS="${MODULE_NAME}_alias"
    CONF_FILE="${DIR}/${MODULE_NAME}.conf"

    # Skip if all files already exist
    if [ -d "$DIR" ] && [ -f "$CONF_FILE" ] && [ -f "$KEY_FILE" ] && [ -f "$CSR_FILE" ] && [ -f "$CRT_FILE" ] && [ -f "$P12_FILE" ] && [ -f "$JKS_FILE" ]; then
      echo "All required files already exist for $MODULE_NAME. Skipping..."
      continue
    fi

    mkdir -p "$DIR"

    echo "🔧 Generating config for $MODULE_NAME..."

    cat > "$CONF_FILE" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = IN
ST = Karnataka
L = Bangalore
O = LTIMINDTREE
OU = AINATIVE
CN = ${MODULE_NAME}

[v3_req]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:TRUE
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${MODULE_NAME}
EOF

    echo "🔐 Generating certificate for $MODULE_NAME..."
    openssl genrsa -out "$DIR/${MODULE_NAME}.key" 2048 || exit 1
    openssl req -new -key "$DIR/${MODULE_NAME}.key" -out "$DIR/${MODULE_NAME}.csr" -config "$CONF_FILE" || exit 1
    openssl x509 -req -in "$DIR/${MODULE_NAME}.csr" -CA "/app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt" \
      -CAkey "/app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.key" -CAcreateserial \
      -out "$DIR/${MODULE_NAME}.crt" -days 365 -sha256 -extfile "$CONF_FILE" -extensions v3_req || exit 1
    openssl pkcs12 -export -in "$DIR/${MODULE_NAME}.crt" -inkey "$DIR/${MODULE_NAME}.key" \
      -out "$DIR/${MODULE_NAME}.p12" -name "$ALIAS" -password pass:$PASSWORD || exit 1
    openssl pkcs12 -in "$DIR/${MODULE_NAME}.p12" -nodes -out "$DIR/${MODULE_NAME}-full.pem" -passin pass:$PASSWORD || exit 1
    openssl pkey -in "$DIR/${MODULE_NAME}-full.pem" -out "$DIR/${MODULE_NAME}-key.pem" || exit 1
    openssl crl2pkcs7 -nocrl -certfile "$DIR/${MODULE_NAME}-full.pem" | openssl pkcs7 -print_certs -out "$DIR/${MODULE_NAME}-crt.pem" || exit 1

    kubectl create secret generic "${MODULE_NAME}-crt-keystore" --from-file="$DIR/${MODULE_NAME}-crt.pem" || exit 1
    kubectl create secret generic "${MODULE_NAME}-key-keystore" --from-file="$DIR/${MODULE_NAME}-key.pem" || exit 1
    echo "✅ Python PEM and secrets created for module: $MODULE_NAME"
  done < python-modules.txt

else
  echo "❌ Invalid module type. Please enter 'java' or 'python'."
  exit 1
fi

