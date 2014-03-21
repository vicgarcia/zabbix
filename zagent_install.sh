#!/bin/bash

# zinstall.sh : install zabbix agent on a ubuntu system (exec as root)

# get settings to use to configure the agent from user
echo -e "What's the IP for the Zabbix server?"
read ZABBIX_SERVER_IP
echo -e "What's the IP for this server to listen on?"
read THIS_SERVER_IP
echo -e "What's this server's hostname that Zabbix uses?"
read THIS_SERVER_HOSTNAME
echo -e ""

# install zabbix agent
add-apt-repository ppa:pbardov/zabbix -y && apt-get -qq -y update
apt-get -y install zabbix-agent

# create location for zabbix monitor scripts
mkdir -p /etc/zabbix/scripts

# install fpm monitoring script
cat > /etc/zabbix/scripts/phpfpm.sh << DELIM
#!/bin/bash

# Zabbix requested parameter
ZBX_REQ_DATA="\$1"
ZBX_REQ_DATA_URL="\$2"

# Nginx defaults
PHPFPM_STATUS_DEFAULT_URL="http://localhost:80/php-fpm_status"
WGET_BIN="/usr/bin/wget"

# Error handling:
ERROR_NO_ACCESS_FILE="-0.9900"
ERROR_NO_ACCESS="-0.9901"
ERROR_WRONG_PARAM="-0.9902"
ERROR_DATA="-0.9903" # either can not connect / bad host / bad port

# Handle host and port if non-default
if [ ! -z "\$ZBX_REQ_DATA_URL" ]; then
    URL="\$ZBX_REQ_DATA_URL"
else
    URL="\$PHPFPM_STATUS_DEFAULT_URL"
fi

# save the nginx stats in a variable for future parsing
PHPFPM_STATS=\$(\$WGET_BIN -q \$URL -O - 2> /dev/null)

# error during retrieve
if [ \$? -ne 0 -o -z "\$PHPFPM_STATS" ]; then
    echo \$ERROR_DATA
    exit 1
fi

# Extract data from nginx stats
RESULT=\$(echo "\$PHPFPM_STATS" | awk 'match($0, "^'"\$ZBX_REQ_DATA"':[[:space:]]+(.*)", a) { print a[1] }')
if [ \$? -ne 0 -o -z "\$RESULT" ]; then
    echo \$ERROR_WRONG_PARAM
    exit 1
fi

echo \$RESULT

exit 0
DELIM
chmod +x /etc/zabbix/scripts/phpfpm.sh

# install nginx monitoring script
cat > /etc/zabbix/scripts/nginx.sh << DELIM
#!/bin/bash

# Zabbix requested parameter
ZBX_REQ_DATA="\$1"
ZBX_REQ_DATA_URL="\$2"

# Nginx defaults
NGINX_STATUS_DEFAULT_URL="http://localhost:80/nginx_status"
WGET_BIN="/usr/bin/wget"

# Error handling
ERROR_NO_ACCESS_FILE="-0.9900"
ERROR_NO_ACCESS="-0.9901"
ERROR_WRONG_PARAM="-0.9902"
ERROR_DATA="-0.9903" # either can not connect /	bad host / bad port

# Handle host and port if non-default
if [ ! -z "\$ZBX_REQ_DATA_URL" ]; then
    URL="\$ZBX_REQ_DATA_URL"
else
    URL="\$NGINX_STATUS_DEFAULT_URL"
fi

# save the nginx stats in a variable for future parsing
NGINX_STATS=\$(\$WGET_BIN -q \$URL -O - 2> /dev/null)

# error during retrieve
if [ \$? -ne 0 -o -z "\$NGINX_STATS" ]; then
    echo \$ERROR_DATA
    exit 1
fi

# Extract data from nginx stats
case \$ZBX_REQ_DATA in
    active_connections)   echo "\$NGINX_STATS" | head -1             | cut -f3 -d' ';;
    accepted_connections) echo "\$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f2 -d' ';;
    handled_connections)  echo "\$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f3 -d' ';;
    handled_requests)     echo "\$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f4 -d' ';;
    reading)              echo "\$NGINX_STATS" | tail -1             | cut -f2 -d' ';;
    writing)              echo "\$NGINX_STATS" | tail -1             | cut -f4 -d' ';;
    waiting)              echo "\$NGINX_STATS" | tail -1             | cut -f6 -d' ';;
    *)                    echo \$ERROR_WRONG_PARAM; exit 1;;
esac

exit 0
DELIM
chmod +x /etc/zabbix/scripts/nginx.sh

# add configure zabbix agent
cat > /etc/zabbix/zabbix_agentd.conf << DELIM
# This is a config file for Zabbix Agent (Unix)
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix-agent/zabbix_agentd.log
LogFileSize=0
Hostname=$THIS_SERVER_HOSTNAME
SourceIP=$THIS_SERVER_IP
ListenIP=$THIS_SERVER_IP
ListenPort=10050
Server=$ZABBIX_SERVER_IP

UserParameter=nginx[*],/etc/zabbix/scripts/nginx.sh "\$1" "\$2"
UserParameter=php-fpm[*],/etc/zabbix/scripts/phpfpm.sh "\$1" "\$2"
DELIM

# add zabbix user to the 'adm' group (necessary for log monitoring)
usermod -a -G adm zabbix

# restart zabbix agent with new settings
service zabbix-agent restart

