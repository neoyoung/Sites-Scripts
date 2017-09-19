#!/bin/bash

#-----------------------------------------------检查是否是root
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error:you must be root user"
    exit 1
fi

#----------------------------------------------检查nginx站点配置目录是否存在 并创建
if [ ! -d /www/nserver/nginx/conf/vhost ]; then
	mkdir /www/nserver/nginx/conf/vhost
fi

#-----------------------------------------输入域名
domain="www.sniu.com"
echo "Input you domain:"
read  domain
if [ "$domain" = "" ]; then
	domain="www.sniu.com"
fi


if [ ! -f "/www/nserver/nginx/conf/vhost/$domain.conf" ]; then
	echo "==========================="
	echo "You Domain Is $domain"
	echo "===========================" 
	else
	echo "==========================="
	echo "$domain is exist!"
	echo "==========================="	
fi

echo "Do you need input  more domans? (y/n)"
read add_more_domainame

if [ "$add_more_domainame" == 'y' ]; then
	  echo "input other domain:"
	  read moredomain
          echo "==========================="
          echo domain list="$moredomain"
          echo "==========================="
	  moredomainame=" $moredomain"
fi


#---------------------------------------根据域名创建目录
vhostdir="/www/web/$domain"
express -e $vhostdir
chmod -R 755 $vhostdir
chown -R www:www $vhostdir

#-------------------------------------输入监听端口
echo "Please input the express listen port"
read node_port

echo "Create site now ……"

#-----------------------------------建立nginx配置文件
cat >/www/nserver/nginx/conf/vhost/$domain.conf<<eof
$alf
server
	{
		listen       80;
		server_name $domain $moredomainame;
		root  $vhostdir;


		location / {
                     proxy_pass              http://127.0.0.1:$node_port/;
                     proxy_redirect          off;
                     proxy_set_header        X-Real-IP       \$remote_addr;
                     proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
               }

		location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
		{
				expires      30d;
		}

		location ~ .*\.(js|css)?$
		{
				expires      12h;
		}

		$al
	}
eof

#-----------------------------修改express的bin/www文件  主要是给个端口号
rm -rf  $vhostdir/bin/www
cat >$vhostdir/bin/www<<eof
#!/usr/bin/env node
var debug = require('debug')('my-application');
var app = require('../app');

app.set('port', process.env.PORT || $node_port);

var server = app.listen(app.get('port'), function() {
  debug('Express server listening on port ' + server.address().port);
});

eof

#-----------------------------------重启nginx
/www/nserver/nginx/sbin/nginx -t
/www/nserver/nginx/sbin/nginx -s reload

#--------------------------------npm install
cd $vhostdir
npm install


#------------------------------pm2启动 并加入启动服务
pm2 start -f $vhostdir/bin/www

env PATH=$PATH:/usr/local/bin pm2 startup centos -u root

echo "All complete........."
