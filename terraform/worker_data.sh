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

# worker code
mkdir -p /opt/mysqlcluster/deploy/ndb_data
ndbd -c ip-172-31-23-0.ec2.internal:1186

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