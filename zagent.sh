#!/bin/bash

# zagent.sh - install and configure zabbix agent

# install apt-add-repository tool
apt-get -qq -y install python-software-properties

# install zabbix agent
apt-add-repository ppa:pbardov/zabbix -y && apt-get -qq -y update
apt-get -y install zabbix-agent

# add zabbix user to the 'adm' group (necessary for log monitoring)
usermod -a -G adm zabbix

# create location for zabbix monitor scripts
mkdir -p /etc/zabbix/scripts

# install redis monitor script from git repo with curl
curl -o /etc/zabbix/scripts/monitor-redis.pl \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-redis.pl
chmod +x /etc/zabbix/scripts/monitor-redis.pl

# install nginx monitor script from git repo with curl
curl -o /etc/zabbix/scripts/monitor-nginx.sh \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-nginx.sh
chmod +x /etc/zabbix/scripts/monitor-nginx.sh

# install zabbix monitoring configurations for individual services
curl -o /etc/zabbix/zabbix_agentd.conf.d/config-nginx.conf \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/config-nginx.conf
curl -o /etc/zabbix/zabbix_agentd.conf.d/config-redis.conf \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/config-redis.conf
curl -o /etc/zabbix/zabbix_agentd.conf.d/config-mysql.conf \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/config-mysql.conf

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
ServerActive=$ZABBIX_SERVER_IP
Include=/etc/zabbix/zabbix_agentd.conf.d/
DELIM

# restart zabbix agent with new settings
service zabbix-agent restart

# references
#   http://www.badllama.com/content/monitor-mysql-zabbix
#   http://addmoremem.blogspot.com/2010/10/zabbixs-template-to-monitor-redis.html
#   https://github.com/jizhang/zabbix-templates
#   http://www.hjort.co/2009/12/postgresql-monitoring-on-zabbix.html
#
