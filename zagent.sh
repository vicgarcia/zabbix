#!/bin/bash
# zagent.sh : install and configure zabbix agent components

# get settings to use to configure the agent from user

echo -e "What's the IP for the Zabbix server?"
read ZABBIX_SERVER_IP < /dev/tty

echo -e "What's the IP for this server to listen on?"
read THIS_SERVER_IP < /dev/tty

echo -e "What's this server's hostname that Zabbix uses?"
read THIS_SERVER_HOSTNAME < /dev/tty

# official zabbix 3.0 for ubuntu 14.04
pushd /tmp
wget --quiet http://repo.zabbix.com/zabbix/3.0/debian/pool/main/z/zabbix-release/zabbix-release_3.0-1+wheezy_all.deb
dpkg -i zabbix-release_3.0-1+wheezy_all.deb
apt-get -qq -y update
popd

# install zabbix agent
apt-get -qq -y install zabbix-agent

# add zabbix user to the 'adm' group (necessary for log monitoring)
usermod -a -G adm zabbix

# add configure zabbix agent
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.default
cat > /etc/zabbix/zabbix_agentd.conf << DELIM
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Hostname=$THIS_SERVER_HOSTNAME
SourceIP=$THIS_SERVER_IP
ListenIP=$THIS_SERVER_IP
ListenPort=10050
Server=$ZABBIX_SERVER_IP
ServerActive=$ZABBIX_SERVER_IP
Include=/etc/zabbix/zabbix_agentd.d/
DELIM

# create location for zabbix monitor scripts
mkdir -p /etc/zabbix/scripts

# remove default mysql agent config (if it's there)
rm -f /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf

# clone my zabbix-scripts repo
pushd /tmp
rm -rf zabbix-scripts
git clone https://github.com/vicgarcia/zabbix-scripts.git zabbix-scripts

# install redis monitoring
cp zabbix-scripts/config-redis.conf /etc/zabbix/zabbix_agentd.d/redis.conf
cp zabbix-scripts/monitor-redis.pl /etc/zabbix/scripts/monitor-redis.pl
chmod +x /etc/zabbix/scripts/monitor-redis.pl

# install nginx monitoring (nginx site config must be installed manually)
cp zabbix-scripts/config-nginx.conf /etc/zabbix/zabbix_agentd.d/nginx.conf
cp zabbix-scripts/monitor-nginx.sh /etc/zabbix/scripts/monitor-nginx.sh
chmod +x /etc/zabbix/scripts/monitor-nginx.sh
cp zabbix-scripts/nginx-stats-site.conf /etc/zabbix/scripts/nginx-stats-site.conf

# install mysql monitoring (must create mysql user for zabbix agent manually)
cp zabbix-scripts/config-mysql.conf /etc/zabbix/zabbix_agentd.d/mysql.conf

# install postgres monitoring
cp zabbix-scripts/config-pgsql.conf /etc/zabbix/zabbix_agentd.d/pgsql.conf
cp zabbix-scripts/monitor-pgsql-find-dbname.sh /etc/zabbix/scripts/monitor-pgsql-find-dbname.sh
chmod +x /etc/zabbix/scripts/monitor-pgsql-find-dbname.sh
cp zabbix-scripts/monitor-pgsql-find-dbname-table.sh /etc/zabbix/scripts/monitor-pgsql-find-dbname-table.sh
chmod +x /etc/zabbix/scripts/monitor-pgsql-find-dbname-table.sh

popd

# make sure z-agent starts on reboot, recommend a reboot to verify this

# references
#   http://www.badllama.com/content/monitor-mysql-zabbix
#   http://addmoremem.blogspot.com/2010/10/zabbixs-template-to-monitor-redis.html
#   https://github.com/jizhang/zabbix-templates
#   http://www.hjort.co/2009/12/postgresql-monitoring-on-zabbix.html
#   http://pg-monz.github.io/pg_monz/index-en.html
#
