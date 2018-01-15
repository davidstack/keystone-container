#!/usr/bin/env bash
HTTP="http"

if [ -z $KEYSTONE_DB_HOST ]; then
  echo "Please set KEYSTONE_DB_HOST when running a container."
  exit 1;
else
    if [ -z $KEYSTONE_DB_ROOT_PASSWD_IF_REMOTED ]; then
        echo "Your'are using Remote MySQL Database; "
        echo "Please set KEYSTONE_DB_ROOT_PASSWD_IF_REMOTED when running a container."
        exit 1;
    else
        KEYSTONE_DB_ROOT_PASSWD=$KEYSTONE_DB_ROOT_PASSWD_IF_REMOTED
    fi
fi


# Keystone Database and user init
if [ ! -f "/etc/keystone/initial" ]; then
        echo "init keystone..."
	sed -i 's|KEYSTONE_DB_PASSWD|'"$KEYSTONE_DB_PASSWD"'|g' /root/keystone.sql
	mysql -uroot -p$KEYSTONE_DB_ROOT_PASSWD_IF_REMOTED -h $KEYSTONE_DB_HOST < /root/keystone.sql
	# Update keystone.conf
	sed -i "s/KEYSTONE_DB_PASSWORD/$KEYSTONE_DB_PASSWD/g" /etc/keystone/keystone.conf
	sed -i "s/KEYSTONE_DB_HOST/$KEYSTONE_DB_HOST/g" /etc/keystone/keystone.conf
	echo "keystone-manage db_sync...."
        su -s /bin/sh -c 'keystone-manage db_sync' keystone
	echo "fernet_setup..."
        keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
        echo "credential_setup..."
        keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
	# Populate keystone database
	#change admin project to kube-system
    
    echo "bootstrap..."
	keystone-manage bootstrap --bootstrap-password $KEYSTONE_ADMIN_PASSWORD \
	  --bootstrap-admin-url http://$HOSTNAME:35357/v3/ \
	  --bootstrap-internal-url http://$HOSTNAME:5000/v3/ \
	  --bootstrap-public-url http://$HOSTNAME:5000/v3/ \
	  --bootstrap-region-id RegionOne
        echo "touch init file"
        touch /etc/keystone/initial
	
	mysql -uroot -p$KEYSTONE_DB_ROOT_PASSWD_IF_REMOTED -h $KEYSTONE_DB_HOST < /root/project.sql

fi

echo "ServerName $HOSTNAME" >> /etc/httpd/conf/httpd.conf
echo "set openrc"
cat > /root/openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=kube-system
export OS_USERNAME=admin
export OS_PASSWORD=${KEYSTONE_ADMIN_PASSWORD}
export OS_AUTH_URL=$HTTP://${HOSTNAME}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

/usr/sbin/httpd

while true;do
 sleep 60
done
# ensite keystone and start apache2
# systemctl enable httpd.service
# systemctl start httpd.service
