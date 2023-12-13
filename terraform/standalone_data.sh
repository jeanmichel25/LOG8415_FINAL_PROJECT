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
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_write.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_write.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_write.lua cleanup

# read only test
echo "Read-Only Test"
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua cleanup

# write only test
echo "Write-Only Test"
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_write_only.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_write_only.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_write_only.lua cleanup

# insert test
echo "Insert Test"
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_insert.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_insert.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_insert.lua cleanup

# update index test
echo "Update Index Test"
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_index.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_index.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_index.lua cleanup

# update non index test
echo "Update Non-Index Test"
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_non_index.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_non_index.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_non_index.lua cleanup

# point select test
echo "Point Select Test"
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=1 --events=0 --time=60 /usr/share/sysbench/oltp_point_select.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=1 --events=0 --time=60 /usr/share/sysbench/oltp_point_select.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=1 --events=0 --time=60 /usr/share/sysbench/oltp_point_select.lua cleanup

# delete test
echo "Delete Test"
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_delete.lua prepare
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_delete.lua run
sudo sysbench --db-driver=mysql --mysql-user=root --mysql-db=sakila --table_size=1000000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_delete.lua cleanup

