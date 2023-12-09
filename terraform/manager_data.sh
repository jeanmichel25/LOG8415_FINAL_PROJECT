#!/bin/bash

exec > /home/ubuntu/startup.log 2>&1

sudo apt-get update
sudo apt-get install -y unzip

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
datadir=/opt/mysqlcluster/home/mysqlc/bin/
basedir=/opt/mysqlcluster/home/mysqlc
port=3306" > my.cnf

echo -e "[ndb_mgmd]
hostname=ip-172-31-30-0.ec2.internal
datadir=/opt/mysqlcluster/deploy/ndb_data
nodeid=1

[ndbd default]
noofreplicas=3
datadir=/opt/mysqlcluster/home/mysqlc/bin/

[ndbd]
hostname=ip-172-31-30-1.ec2.internal
nodeid=2

[ndbd]
hostname=ip-172-31-30-2.ec2.internal
nodeid=3

[ndbd]
hostname=ip-172-31-30-3.ec2.internal
nodeid=4

[mysqld]
nodeid=50" > config.ini

cd /opt/mysqlcluster/home/mysqlc
scripts/mysql_install_db --no-defaults --datadir=/opt/mysqlcluster/deploy/mysqld_data

ndb_mgmd -f /opt/mysqlcluster/deploy/conf/config.ini --initial --configdir=/opt/mysqlcluster/deploy/conf

# install sakila database
cd /home/ubuntu
wget https://downloads.mysql.com/docs/sakila-db.zip
unzip sakila-db.zip
cd sakila-db

sudo mysqld -e "SOURCE sakila-schema.sql;"
sudo mysqld -e "SOURCE sakila-data.sql;"

# test to see if sakila database is installed
sudo mysqld -e "USE sakila; SHOW FULL TABLES;"
sudo mysqld -e "USE sakila; SELECT COUNT(*) FROM film;"
sudo mysqld -e "USE sakila; SELECT COUNT(*) FROM film_text;"
