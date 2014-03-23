#!/bin/bash
#
#   zserver.sh - install zabbix server on ubuntu 12.04 vm w/ nginx/fpm and postgres
#                more info availabile at https://github.com/vicgarcia/zabbix-scripts
#

# update apt, don't upgrade, it tends to break things on certain vms
echo -e "\nupdate and upgrade..."
apt-get -qq -y update && apt-get -qq -y upgrade

# install apt-add-repository tool, apg (used below)
apt-get -qq -y install python-software-properties apg

# add cron task to sync time every hour
echo -e "\nconfigure cron for time sync via net..."
echo "48 * * * * /usr/sbin/ntpdate -s us.pool.ntp.org" | crontab

# install postgresql
echo -e "\ninstall postgres..."
apt-get -qq -y install postgresql postgresql-client

# install latest php on ubuntu 12.04
echo -e "\ninstall php..."
add-apt-repository ppa:ondrej/php5 -y && apt-get -qq -y update
apt-get -qq -y install php5-fpm php5-cli php5-dev php5-pgsql php5-gd

# add configurations in php.ini (necessary for zabbix web ui)
sed -i 's/post_max_size = 8M/post_max_size = 32M/gi' /etc/php5/fpm/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/gi' /etc/php5/fpm/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/gi' /etc/php5/fpm/php.ini
sed -i 's/;date.timezone =/date.timezone = America\/Chicago/gi' /etc/php5/fpm/php.ini

# install nginx
echo -e "\ninstall nginx..."
apt-get -qq -y install nginx

# nginx server config
cat > /etc/nginx/nginx.conf << DELIM
user www-data;
worker_processes 4;
pid /var/run/nginx.pid;

events {
    worker_connections 768;
    # multi_accept on;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # MIME Types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging Settings
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip Settings
    gzip on;
    gzip_disable "msie6";

    # Additional Configs
    include /etc/nginx/conf.d/*.conf;

    # Sites Config
    include /etc/nginx/sites.conf;
}
DELIM

# nginx sites config
rm -rf /etc/nginx/sites-available
rm -rf /etc/nginx/sites-enabled
cat > /etc/nginx/sites.conf << DELIM
## stats for nginx + fpm server for use with zabbix agent
server {
    listen 10061;

    location /nginx {
        allow 127.0.0.1;
        deny all;
        stub_status on;
        access_log off;
    }

    location /fpm {
        allow 127.0.0.1;
        deny all;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}

## zabbix frontend
server {
    listen 80;
    root /opt/zabbix-ui;

    index           index.php;
    error_page      403 404 502 503 504  /zabbix/index.php;

    location ~ \\.php$ {
        if (!-f \$request_filename) { return 404; }
        include         /etc/nginx/fastcgi_params;
        fastcgi_index   index.php;
        fastcgi_pass    unix:/var/run/php5-fpm.sock;
    }

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|swf)$ {
        access_log  off;
        expires     33d;
    }
}
DELIM

# install zabbix server
echo -e "\ninstall zabbix..."
add-apt-repository ppa:pbardov/zabbix -y > /dev/null && apt-get -qq -y update
apt-get -qq -y install zabbix-server-pgsql      # also create zabbix linux user and group

# generate random password and set env vars for remainder of script
ZABBIX_DB_PASSWORD=`apg -n 1`
export PGPASSWORD=$ZABBIX_DB_PASSWORD

# add zabbix db and db user
sudo -u postgres psql -c "create user zabbix with password '$ZABBIX_DB_PASSWORD'"
sudo -u postgres psql -c "create database zabbix"
sudo -u postgres psql -c "grant all privileges on database zabbix to zabbix"

# add this to pg_hba.conf for zabbix
echo 'local   zabbix      zabbix                            md5' >> /etc/postgresql/9.1/main/pg_hba.conf

# add zabbix initial content to db (password? it's later) (also, stole this somewhere)
pushd /usr/share/zabbix-server-pgsql/
gunzip *.gz
psql -h 127.0.0.1 -U zabbix zabbix < schema.sql
psql -h 127.0.0.1 -U zabbix zabbix < images.sql
psql -h 127.0.0.1 -U zabbix zabbix < data.sql
popd

# XXX todo : use database backups if they've been copied to the server
#            this script will be all in one install/restore

# add zabbkit push notification script
cat > /etc/zabbix/alert.d/zabbkit-push << DELIM
#!/bin/bash
curl -X POST\
  -H "Content-type:application/json"\
  -d "{Id:'\$1', text:'\$2', triggerId:'\$3', playSound:true}"\
  http://zabbkit.inside.cactussoft.biz/api/messages
DELIM
chmod +x /etc/zabbix/alert.d/zabbkit-push

# configure server to use database (password)
sed -i "s/# DBPassword=/DBPassword=$ZABBIX_DB_PASSWORD/gi" /etc/zabbix/zabbix_server.conf

# setup autostart for zabbix
sed -i 's/START=no/START=yes/gi' /etc/default/zabbix-server

# install zabbix web ui
mkdir -p /tmp/zabbix-ui
pushd /tmp/zabbix-ui
apt-get download zabbix-frontend-php
ar vx zabbix-frontend-php_2.0.5+dfsg-1ubuntu1ppa1~precise_all.deb
tar -xJf data.tar.xz
cp -r usr/share/zabbix /opt/zabbix-ui
popd
rm -rf /tmp/zabbix-ui

# fix ui font path see https://www.zabbix.com/forum/showthread.php?p=91923
sed -i "s/realpath('fonts')/'\/usr\/share\/fonts\/truetype\/ttf-dejavu'/gi" /opt/zabbix-ui/include/defines.inc.php

# create zabbix ui config
cat > /etc/zabbix/zabbix.conf.php << DELIM
<?php
// Zabbix GUI configuration file
global \$DB;

\$DB['TYPE']     = 'POSTGRESQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '$ZABBIX_DB_PASSWORD';


// SCHEMA is relevant only for IBM_DB2 database
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
DELIM

# configure firewall
ufw allow 80/tcp        # nginx / web
ufw allow 22/tcp        # ssh
ufw allow 10051/tcp     # zabbix-server

# install complete, notify user
echo -e "\nInstall complete!"
echo -e "\nGet started by loading this server in the browser to access the Zabbix UI."
echo -e "\nThe default username and password is :  Admin : zabbix"
echo -e "\nYour postgres zabbix user password is :  $ZABBIX_DB_PASSWORD"
echo -e "\nIn order to continue, you will need to enable the firewall and reboot"
echo -e "\nthe server.  You can do this by running this command :"
echo
echo -e "\n  ufw enable && shutdown -r now"
echo

#  vic garcia | vicg4rcia.com
#  references :
#    https://www.zabbix.com/wiki/howto/db/postgres
#    http://www.v12n.com/mediawiki/index.php/Ubuntu_Zabbix
#    https://www.zabbix.com/forum/showthread.php?p=136028
#    https://delicious.com/vicg4rcia/zabbix
#
