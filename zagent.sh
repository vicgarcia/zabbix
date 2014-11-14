#!/bin/bash
# zagent.sh : install and configure zabbix agent components
#

# official zabbix 2.2 (lts version) supported sources for ubuntu 14.04
pushd /tmp
wget --quiet http://repo.zabbix.com/zabbix/2.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_2.2-1+trusty_all.deb
dpkg -i zabbix-release_2.2-1+trusty_all.deb
apt-get -qq -y update
popd

# install zabbix agent
apt-get -qq -y install zabbix-agent

# add zabbix user to the 'adm' group (necessary for log monitoring)
usermod -a -G adm zabbix

# create location for zabbix monitor scripts
mkdir -p /etc/zabbix/scripts

# install redis monitor script from git repo with curl

# install redis monitoring ...
curl -o /etc/zabbix/zabbix_agentd.conf.d/config-redis.conf \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/config-redis.conf
curl -o /etc/zabbix/scripts/monitor-redis.pl \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-redis.pl
chmod +x /etc/zabbix/scripts/monitor-redis.pl

# install nginx monitoring ...
curl -o /etc/zabbix/zabbix_agentd.conf.d/config-nginx.conf \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/config-nginx.conf
curl -o /etc/zabbix/scripts/monitor-nginx.sh \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-nginx.sh
chmod +x /etc/zabbix/scripts/monitor-nginx.sh

# install mysql monitoring ...
curl -o /etc/zabbix/zabbix_agentd.conf.d/config-mysql.conf \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/config-mysql.conf

# install postgres monitoring ...
curl -o /etc/zabbix/zabbix_agentd.conf.d/config-pgsql.conf \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/config-pgsql.conf
curl -o /etc/zabbix/scripts/monitor-pgsql-find-dbname.sh \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-pgsql-find-dbname.sh
curl -o /etc/zabbix/scripts/monitor-pgsql-find-dbname-table.sh \
    https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/monitor-pgsql-find-dbname-table.sh
chmod +x /etc/zabbix/scripts/monitor-pgsql-find-dbname.sh
chmod +x /etc/zabbix/scripts/monitor-pgsql-find-dbname-table.sh

# get settings to use to configure the agent from user
read -p "What's the IP for the Zabbix server?" -r -t 20 ZABBIX_SERVER_IP && echo
read -p "What's the IP for this server to listen on?" -r -t 20 THIS_SERVER_IP && echo
read -p "What's this server's hostname that Zabbix uses?" -r -t 20 THIS_SERVER_HOSTNAME && echo

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

# enable zabbix agent start on boot
update-rc.d zabbix-server defaults

# restart zabbix agent with new settings
service zabbix-agent restart

# references
#   http://www.badllama.com/content/monitor-mysql-zabbix
#   http://addmoremem.blogspot.com/2010/10/zabbixs-template-to-monitor-redis.html
#   https://github.com/jizhang/zabbix-templates
#   http://www.hjort.co/2009/12/postgresql-monitoring-on-zabbix.html
#   http://pg-monz.github.io/pg_monz/index-en.html
#
