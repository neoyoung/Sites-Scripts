#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


#---------------------------------------------------这里是安装软件下载地址 自行更换   更换后记得检查对应的解压和cd命令
#prel 8.12
pcre_url=http://libo2452.googlecode.com/files/pcre-8.12.tar.gz

#nginx 1.2.9
nginx_url=http://nginx.org/download/nginx-1.2.9.tar.gz

#python 2.7.6
python_url=https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz

#node.js 0.10.28
node_url=http://nodejs.org/dist/v0.10.28/node-v0.10.28.tar.gz

#mongodb 2.4.10 32 bit
mongodb_url=http://fastdl.mongodb.org/linux/mongodb-linux-i686-2.4.10.tgz


#-----------------------------------------------检查是否是root用户
# check root user
if [ $(id -u) != "0" ]; then
    echo "Error:you must be root user"
    exit 1
fi

clear
echo "========================================================================="
echo "NServer V1.0 for CentOS By MagicFat"
echo "========================================================================="
echo "It will install Nginx+Mongodb+Node.js+PM2+Express "
echo ""
echo "========================================================================="

cur_dir=$(pwd)


#--------------------------------------------安装一些初始环境
echo "=========Install gcc-c++ openssl-devel curl git-core build-essential libssl-dev==========="
yum install -y gcc-c++ openssl-devel curl git-core build-essential libssl-dev bzip2-devel



#create dir
mkdir -p  /www
mkdir -p  /www/nserver

#---------------------------------------安装pcre   prel一个标准库
echo "========================Install pcre 8.12 Now==============================="
groupadd www
useradd -s /sbin/nologin -g www www
cd $cur_dir
wget $pcre_url
tar zxvf pcre-8.12.tar.gz
cd pcre-8.12/
./configure
make && make install
cd ../

ldconfig

#------------------------------------有些centos 会默认安装apache  防止占用80端口 移除之
yum remove -y httpd


#------------------------------------安装nginx
mkdir -p /www/nserver/nginx
chmod -R 777 /www/nserver/nginx
mkdir -p /www/web
chmod +w /www/web
chown -R www:www /www/web

echo "========================Install Nginx 1.2.9 Now==============================="
wget  $nginx_url
tar zxvf nginx-1.2.9.tar.gz
cd nginx-1.2.9/
./configure --user=www --group=www --prefix=/www/nserver/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-ipv6
 make && make install
 ln -s /www/nserver/nginx/sbin/nginx /usr/bin/nginx
 cd ../


cp init.d.nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
sed -i '$!N;$!P;$!D;s/\(\n\)/include vhost\/*.conf;\n/' /www/nserver/nginx/conf/nginx.conf
/www/nserver/nginx/sbin/nginx -c  /www/nserver/nginx/conf/nginx.conf
chkconfig --level 345 nginx on


#------------------------------------------------转移vhost.sh  
cd $cur_dir
cp vhost.sh /root/vhost.sh
chmod +x /root/vhost.sh


#-----------------------------------------------检查python版本是不是大于2.7  如果小于  更新之
PYTHON=/usr/bin/python
PYTHON_VERSION=`$PYTHON -c 'import sys; print(".".join(map(str, sys.version_info[:2])))'`
PYTHON_OK=`$PYTHON -c 'import sys
print (sys.version_info >= (2, 7) and "1" or "0")'`
if [ "$PYTHON_OK" = '0' ]; then
    echo "============================Install Python2.7.6 now================================="
    mkdir -p /www/nserver/python
    wget  --no-check-certificate $python_url
    tar zxvf Python-2.7.6.tgz
    cd Python-2.7.6
    ./configure --prefix=/www/nserver/python
    make && make install
    export PATH=$PATH:/www/nserver/python/bin
    rm -rf /usr/bin/python
    ln -s /www/nserver/python/bin/python /usr/bin/python
    cd ../
    sed -i '1s/\/usr\/bin\/python/\/usr\/bin\/python'"$PYTHON_VERSION"'/1' /usr/bin/yum
fi

#---------------------------------------------安装node.js
echo "============================Install node.js 0.10.28 now================================="
mkdir -p /www/nserver/nodejs
mkdir -p /usr/local/ssl/lib/ 
mkdir -p /usr/local/ssl/include/
wget $node_url
tar zxvf node-v0.10.28.tar.gz
cd  node-v0.10.28
./configure --prefix=/www/nserver/nodejs
make && make install
ln -s /www/nserver/nodejs/bin/node  /usr/bin/node
export PATH=$PATH:/www/nserver/nodejs/bin
cd ../


#--------------------------------------------安装 npm express4 pm2
echo "============================Install npm exprees pm2 now================================="
curl https://www.npmjs.org/install.sh | sh
npm install -g express-generator
npm install -g pm2


#------------------------------------------------安装mongodb
echo "============================Install mongodb 2.4.10 32 bit now================================="
wget   $mongodb_url
tar zxvf mongodb-linux-i686-2.4.10.tgz
cd mongodb-linux-i686-2.4.10
mkdir -p /www/nserver/mongodb
chmod -R 777 /www/nserver/mongodb
cp -r ./* /www/nserver/mongodb
mkdir -p /www/nserver/mongodb/data
mkdir -p /www/nserver/mongodb/logs
touch /www/nserver/mongodb/logs/mogodb.log
/www/nserver/mongodb/bin/mongod --dbpath=/www/nserver/mongodb/data --logpath=/www/nserver/mongodb/logs/mogodb.log --fork
echo "/www/nserver/mongodb/bin/mongod --dbpath=/www/nserver/mongodb/data --logpath=/www/nserver/mongodb/logs/mogodb.log --fork" >> /etc/rc.local
cd ../

#---------------------------------------------加入环境变量
echo "export PATH=$PATH:/www/nserver/python/bin" >> /etc/profile
echo "export PATH=$PATH:/www/nserver/nodejs/bin" >> /etc/profile
echo "export PATH=$PATH:/www/nserver/mongodb/bin" >> /etc/profile
echo "export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE INPUTRC" >> /etc/profile
source /etc/profile 


echo "Install complete........."




