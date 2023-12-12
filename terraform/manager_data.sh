#!/bin/bash

exec > /home/ubuntu/startup.log 2>&1 # tail -f startup.log

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
hostname=ip-172-31-23-1.ec2.internal
nodeid=2

[ndbd]
hostname=ip-172-31-23-2.ec2.internal
nodeid=3

[ndbd]
hostname=ip-172-31-23-3.ec2.internal
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

# Secure install mysql
tee ~/install_mysql.sh > /dev/null << EOF
spawn $(which mysql_secure_installation)
expect "Enter current password for root (enter for none):"
send "root\r"
expect "Set root password? \\[Y/n\\]"
send "n\r"
expect "Remove anonymous users? \\[Y/n\\]"
send "y\r"
expect "Disallow root login remotely? \\[Y/n\\]"
send "y\r"
expect "Remove test database and access to it? \\[Y/n\\]"
send "y\r"
expect "Reload privilege tables now? \\[Y/n\\]"
send "y\r"
EOF

sudo chown root.root ~/install_mysql.sh
sudo chmod 4755 ~/install_mysql.sh

rm -f -v ~/install_mysql.sh

# wait for mysqld to start
while ! mysqladmin ping --silent; do
    sleep 1
done

# install sakila database
cd /home/ubuntu
wget https://downloads.mysql.com/docs/sakila-db.zip
unzip sakila-db.zip
cd sakila-db

mysql -u root -e "SOURCE sakila-schema.sql;"
mysql -u root -e "SOURCE sakila-data.sql;"

# test to see if sakila database is installed
mysql -u root -e "USE sakila; SHOW FULL TABLES;"
mysql -u root -e "USE sakila; SELECT COUNT(*) FROM film;"
mysql -u root -e "USE sakila; SELECT COUNT(*) FROM film_text;"