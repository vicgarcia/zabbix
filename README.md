## Zabbix Scripts

### zserver.sh

This script gives you access to a one-liner to install a fully functional
zabbix server setup.  This script is intended to be run on a Ubuntu 12.04
server, ideally a clean virtual server instance.  The script will install
and configure Postgresql, Nginx, PHP, and Zabbix.

Simply switch to root and run this command.  It will download the latest
script, run it, and log the output to the file install.log as well as
display it on screen.

```
    curl -s http://rockst4r.net/zserver.sh | bash | tee install.log
```

### zagent.sh

This script will install and configure the necessary setup for the Zabbix
agent on a Ubuntu 12.04 server.  This will allow the server to be monitored
by a Zabbix server.  The agent configurations and monitoring scripts that
are part of this repository will automatically be installed by running this
script as well.

```
    curl -s http://rockst4r.net/zagent.sh | bash | tee install.log
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


vic garcia | vicg4rcia.com
