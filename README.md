## Zabbix Scripts

These scripts are for use with the Zabbix monitoring system.

### zserver.sh

This script gives you access to a one-liner to install a fully functional
zabbix server setup.  This script is intended to be run on a Ubuntu 12.04
server, ideally a clean virtual server instance.  The script will install
and configure Postgresql, Nginx, PHP, and Zabbix.

Simply switch to root and run this command.  It will download the latest
script, run it, and log the output to the file install.log as well as
display it on screen.

```
  curl -s http://rockst4r.net/zserver.sh | bash | install.log
```

### zagent.sh

This script will install and configure the necessary setup for the Zabbix
agent on a Ubuntu 12.04 server.  This will allow the server to be monitored
by a Zabbix server.

### Templates

These are for use within the zabbix UI, for monitoring different services.

### Configurations

These are used by Zabbix agent to configure monitoring of various services.

### Monitoring Scripts

These are used by Zabbix agent to monitor various services.


vic garcia | vicg4rcia.com
