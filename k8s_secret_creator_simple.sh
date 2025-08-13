continue=1
while [ $continue -eq 1 ]
do
        read -p "Enter the name of secret: " secretname
        read -p "Enter key: " key
        read -p "Is this a password field(0/1)?: " ispass
        if [ $ispass -eq 1 ]
        then
                echo "Generating password please wait..."
                sleep 1
                value=$(date +%s | sha256sum | base64 | head -c 30 )
        else
                read -p "Enter value: " value
        fi
        #echo "key: ${key}"
        #echo "value: ${value}"
        kubectl get secret ${secretname} &> /dev/null
        if [ $? -eq 0 ]
        then
                echo "Secret already exists..."
                kubectl describe secret ${secretname} | grep ${key}: &> /dev/null
                if [ $? -eq 0 ]
                then
                        read -p "key already exists, would you like to patch it(0/1)?: " keyoverwrite
                        if [ $keyoverwrite -eq 1 ]
                        then
                                kubectl patch secret ${secretname} -p="{\"data\":{\"${key}\": \"`echo -n ${value} | base64`\"}}"
                        else
                                echo "Not patching Secret"
                        fi
                else
                        kubectl patch secret ${secretname} -p="{\"data\":{\"${key}\": \"`echo -n ${value} | base64`\"}}"
                fi
        else
                echo "Creating secret, please wait...."
                kubectl create secret generic ${secretname} --from-literal=${key}=${value}
        fi
        echo "------------------------------------------------"
        echo ""
        read -p "Do you want to continue(0/1)?: " continue
        echo ""
        echo "------------------------------------------------"
done

##### EOF #####

