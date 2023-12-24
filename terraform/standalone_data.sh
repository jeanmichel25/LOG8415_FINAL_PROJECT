#!/bin/bash

exec > /home/ubuntu/startup.log 2>&1 # tail -f startup.log

sudo apt-get update
sudo apt-get install -y unzip sysbench

# install mysql
sudo apt-get install -y mysql-server

# install sakila database
cd /home/ubuntu
wget https://downloads.mysql.com/docs/sakila-db.zip
unzip sakila-db.zip
cd sakila-db

sudo mysql -e "SOURCE sakila-schema.sql;"
sudo mysql -e "SOURCE sakila-data.sql;"

# test to see if sakila database is installed
sudo mysql -e "USE sakila; SHOW FULL TABLES;"
sudo mysql -e "USE sakila; SELECT COUNT(*) FROM film;"
sudo mysql -e "USE sakila; SELECT COUNT(*) FROM film_text;"

# read write test
echo "Read-Write Test"
sudo sysbench /usr/share/sysbench/oltp_read_write.lua prepare --db-driver=mysql --mysql-db=sakila --mysql-user=root --mysql-password --table-size=1000000 
sudo sysbench /usr/share/sysbench/oltp_read_write.lua run --db-driver=mysql --mysql-db=sakila --mysql-user=root --mysql-password --table-size=1000000 --threads=6 --time=60 --events=0
sudo sysbench /usr/share/sysbench/oltp_read_write.lua cleanup --db-driver=mysql --mysql-db=sakila --mysql-user=root --mysql-password --table-size=1000000 --threads=6 --time=60 --events=0
