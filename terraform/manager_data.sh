#!/bin/bash

exec > /home/ubuntu/startup.log 2>&1

sudo apt-get update
sudo apt-get install -y unzip expect

# install mysql cluster
# common code
mkdir -p /opt/mysqlcluster/home
cd /opt/mysqlcluster/home
wget http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.2/mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz

tar xvf mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz
ln -s mysql-cluster-gpl-7.2.1-linux2.6-x86_64 mysqlc

echo 'export MYSQLC_HOME=/opt/mysqlcluster/home/mysqlc' > /etc/profile.d/mysqlc.sh
echo 'export PATH=$MYSQLC_HOME/bin:$PATH' >> /etc/profile.d/mysqlc.sh
source /etc/profile.d/mysqlc.sh
sudo apt-get update && sudo apt-get -y install libncurses5

# manager code
mkdir -p /opt/mysqlcluster/deploy
cd /opt/mysqlcluster/deploy
mkdir conf
mkdir mysqld_data
mkdir ndb_data
cd conf

echo -e "[mysqld]
ndbcluster
datadir=/opt/mysqlcluster/deploy/mysqld_data
basedir=/opt/mysqlcluster/home/mysqlc
port=3306" > my.cnf

echo -e "[ndb_mgmd]
hostname=ip-172-31-45-0.ec2.internal
datadir=/opt/mysqlcluster/deploy/ndb_data
nodeid=1

[ndbd default]
noofreplicas=3
datadir=/opt/mysqlcluster/deploy/ndb_data

[ndbd]
hostname=ip-172-31-45-1.ec2.internal
nodeid=2

[ndbd]
hostname=ip-172-31-45-2.ec2.internal
nodeid=3

[ndbd]
hostname=ip-172-31-45-3.ec2.internal
nodeid=4

[mysqld]
nodeid=50" > config.ini

cd /opt/mysqlcluster/home/mysqlc
scripts/mysql_install_db --no-defaults --datadir=/opt/mysqlcluster/deploy/mysqld_data

sudo chown -R mysql:mysql /opt/mysqlcluster/home/mysqlc

sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgmd -f /opt/mysqlcluster/deploy/conf/config.ini --initial --configdir=/opt/mysqlcluster/deploy/conf/

ndb_mgm -e show

mysqld --defaults-file=/opt/mysqlcluster/deploy/conf/my.cnf --user=root &

ndb_mgm -e show


# # Create a service unit file for MySQL
# echo -e "[Unit]
# Description=MySQL Server
# After=network.target

# [Service]
# ExecStart=/opt/mysqlcluster/home/mysqlc/bin/mysqld_safe
# User=mysql
# UMask=007
# SyslogIdentifier=mysql
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target" | sudo tee /etc/systemd/system/mysql.service

# # Reload the systemd daemon
# sudo systemctl daemon-reload

# # Start the MySQL server
# sudo service mysql start

# # install sakila database
# cd /home/ubuntu
# wget https://downloads.mysql.com/docs/sakila-db.zip
# unzip sakila-db.zip
# cd sakila-db

# sudo mysql -e "SOURCE sakila-schema.sql;"
# sudo mysql -e "SOURCE sakila-data.sql;"

# # test to see if sakila database is installed
# sudo mysql -e "USE sakila; SHOW FULL TABLES;"
# sudo mysql -e "USE sakila; SELECT COUNT(*) FROM film;"
# sudo mysql -e "USE sakila; SELECT COUNT(*) FROM film_text;"