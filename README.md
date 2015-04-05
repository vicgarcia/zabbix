## Zabbix Scripts

### zagent.sh

This script will install and configure the necessary setup for the Zabbix
agent on a Ubuntu server.  This will allow the server to be monitored
by a Zabbix server.  The agent configurations and monitoring scripts that
are part of this repository will automatically be installed by running this
script as well.

This should be run as the root user.

```
    curl -s https://raw.githubusercontent.com/vicgarcia/zabbix-scripts/master/zagent.sh | bash
```

### Zabbix UI Templates

Templates are collections of zabbix server configurations for monitoring a
given application or service.  XML files prefixed with 'template-' in this
repository are templates.  Import these via the Zabbix web UI.  Delete the
existing Linux and MySQL templates before importing the onces included here.

### Agent Configs and Monitoring Scripts

Configurations are for use by zabbix agent for monitoring a specific app
or service.  They define the items on the agent side that the Zabbix server
will be monitoring.  Files prefixed with 'config-' should be installed in
/etc/zabbix/zabbix_agentd.conf.d/

Monitoring scripts are also sometimes used by the zabbix agent to retrieve
data.  These scripts can be written in any shell scripting language, the
obvious requirement is that the language is installed on the agent side
server.  Files prefixed with 'monitor-' should be installed in
/etc/zabbix/scripts/


## Monitoring Configurations

After you've run the zagent.sh script, which installs the basic zabbix agent and
configures it for basic monitoring. In order to use some of the templates for 
monitoring services provided in the repo, there are some additional configurations
that will have to be made beyond what is done by the zagent.sh installer.

### Nginx

In /etc/zabbix/scripts/, the nginx-stats-site.conf file contains the necessary
nginx site/server configuration used by zabbix to collect stats from nginx.
The configuration creates a special nginx 'site' that can be accessed on a specific
local ip port.  The nginx monitoring scripts will then get data from this.

In order to monitor nginx on a server, you will have to incorporate this nginx
site config into your server.  This could be copying this config file to your
/etc/nginx/sites-enabled/ or copying the contents to /etc/nginx/nginx.conf.

### MySQL

In order to collect data from mysql, you will need to create a mysql user account
for the zabbix agent to use. On the server you're monitoring, run something like this:  

echo "grant usage on *.* to 'zagent'@'localhost' identified by '<PASSWORD_HERE>'" \
  | mysql -u root -p<MYSQL_ROOT_PASSWORD>

Once the user is setup, you will need to provide the username and password as macros
within the zabbix UI.  The macros for the host will be {$MYSQL_USER} and {$MYSQL_PASS}.
I typically use the username 'zagent', since it's fairly descriptive.

### PostgreSQL

The scripts I'm using are slightly modified from pg_monz, a comprehensive monitoring
solution for Postgres w/ Zabbix.  You use the components provided here like so.

In order to use this toolchain, the zabbix user, which is created when installing 
the zabbix agent, will need to have a home directory in which we will store a 
.pgpass file.

first, we need to stop the zabbix agent (we're going to be root here) :

  service zabbix-agent stop

then, modify the zabbix user :

  usermod -d /home/zabbix zabbix

create a postgresql superuser (this will prompt for password) :

  su postgres

  createuser -s -P zagent 

add .pgpass with password for zagent postgresql user :

  echo "*:*:*:zagent:<password>" > /home/zabbix/.pgpass

Once the postgres and zabbix accounts are configured as necessary on the monitored
server, the configuration will need to be completed on the zabbix server ui by
setting macros.  There are many configurations which can handled thru macros, but
the minimal ones we will need to set are :

{$PGSQL_USER} : typically 'zagent', the postgres user account created above

{$PGSQL_LOGDIR} : location of postgres log files, often /var/log/postgresql

{$PGSQL_SCRIPTDIR} : location of zabbix agent scripts, /etc/zabbix/scripts

Once Postgresql monitoring is properly configured, it may take a little bit (due
to discovery time lag) in order for the automatic discovery configuration to fill
in the server monitoring items.



vic garcia | vicg4rcia.com
