#!/bin/bash

set -e

logFile="truststore_update.log"


# Generate RSA key
echo "INFO $(date) Generating RSA key..."
openssl genrsa -out /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.key 4096 2> lastError
if [ $? -ne 0 ]; then
    echo "ERROR $(date) Failed to generate RSA key" | tee -a $logFile
    cat lastError >> $logFile
    exit 1
fi

# Generate CA certificate
echo "INFO $(date) Generating CA certificate..."
openssl req -x509 -new -nodes -key /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.key -sha256 -days 3650 -out /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt -subj /C=IN/ST=Karnataka/L=Bangalore/O=LTIMINDTREE/OU=AINATIVE/CN=ainativeops-absa.ltimindtree.info 2> lastError
if [ $? -ne 0 ]; then
    echo "ERROR $(date) Failed to generate CA certificate" | tee -a $logFile
    cat lastError >> $logFile
    exit 1
fi

# Backup truststore
echo "INFO $(date) Taking backup of truststore..."
cp ainative-internal-truststore.jks ainative-internal-truststore.jks.bkp-$(date +%m-%d) 2> lastError
if [ $? -ne 0 ]; then
    echo "ERROR $(date) Unable to take backup of truststore" | tee -a $logFile
    cat lastError >> $logFile
    exit 1
else
    echo "INFO $(date) Truststore backed up successfully" | tee -a $logFile
fi

# Backup truststore secret
echo "INFO $(date) Taking backup of truststore secret..."
kubectl get secret ainative-internal-truststore -o yaml > ainative-internal-truststore-secret-$(date +%m-%d).yaml.bkp 2> lastError
if [ $? -ne 0 ]; then
    echo "ERROR $(date) Unable to take backup of truststore secret" | tee -a $logFile
    cat lastError >> $logFile
    exit 1
else
    echo "INFO $(date) Truststore secret backed up successfully" | tee -a $logFile
fi

# Extract truststore password
echo "INFO $(date) Extracting truststore password..."
keystorepass=$(kubectl get secret ainative-internal-truststore -o yaml | grep "password:" | cut -f 2 -d ":" | sed 's/ //g' | base64 -d) 2> lastError
if [ $? -ne 0 ] || [ -z "$keystorepass" ]; then
    echo "ERROR $(date) Failed to extract truststore password" | tee -a $logFile
    cat lastError >> $logFile
    exit 1
fi

# Import CA certificate into truststore
echo "INFO $(date) Importing CA certificate into truststore..."
keytool -import -alias ainative-ca -file /app_data/DEPLOYMENTS/AINATIVE_SSL/CERTIFICATES/ca/ca.crt -keystore ainative-internal-truststore.jks -keypass $keystorepass -storepass $keystorepass -noprompt 2> lastError
if [ $? -ne 0 ]; then
    echo "ERROR $(date) Failed to import CA certificate into truststore" | tee -a $logFile
    cat lastError >> $logFile
    exit 1
else
    echo "✅ $(date) New CA certificate generated and imported into truststore." | tee -a $logFile
fi

## Patching the kubernetes secret ##

kubectl delete secret ainative-internal-truststore
kubectl create secret generic ainative-internal-truststore --from-file=ainative-internal-truststore.jks=ainative-internal-truststore.jks --from-literal=password=$keystorepass

echo "WARN `date` Truststore updated ..."

echo "WARN `date` Truststore updated ..." >> ${logFile}

