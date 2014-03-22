#!/bin/bash

# zagent.sh - install zabbix agent on a ubuntu system (run this as root)

# install zabbix agent
add-apt-repository ppa:pbardov/zabbix -y && apt-get -qq -y update
apt-get -y install zabbix-agent

# add zabbix user to the 'adm' group (necessary for log monitoring)
usermod -a -G adm zabbix

# create location for zabbix monitor scripts
mkdir -p /etc/zabbix/scripts

# install redis monitor script from git repo with curl
curl -o /etc/zabbix/scripts/monitor-redis.pl https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-redis.pl
chmod +x /etc/zabbix/scripts/monitor-redis.pl

# install nginx monitor script from git repo with curl
curl -o /etc/zabbix/scripts/monitor-nginx.sh https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-nginx.sh
chmod +x /etc/zabbix/scripts/monitor-nginx.sh

# get settings to use to configure the agent from user
echo -e "What's the IP for the Zabbix server?"
read ZABBIX_SERVER_IP
echo -e "What's the IP for this server to listen on?"
read THIS_SERVER_IP
echo -e "What's this server's hostname that Zabbix uses?"
read THIS_SERVER_HOSTNAME
echo -e ""

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

UserParameter=nginx[*],/etc/zabbix/scripts/monitor-nginx.sh "\$1" "\$2"
UserParameter=redis_stats[*],/etc/zabbix/scripts/monitor-redis.pl "\$1" "\$2" "\$3"

Include=/etc/zabbix/zabbix_agentd.conf.d/
DELIM

# restart zabbix agent with new settings
service zabbix-agent restart
