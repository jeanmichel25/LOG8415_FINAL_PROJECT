#!/bin/bash

exec > /home/ubuntu/startup.log 2>&1

sudo apt-get update
sudo apt-get install -y unzip expect sysbench

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
ndbd -c ip-172-31-19-0.ec2.internal:1186

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

# read write test
echo "Read-Write Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_write.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_write.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_write.lua cleanup

# read only test
echo "Read-Only Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua cleanup

# write only test
echo "Write-Only Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_write_only.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_write_only.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 --rand-type=uniform /usr/share/sysbench/oltp_write_only.lua cleanup

# insert test
echo "Insert Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_insert.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_insert.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_insert.lua cleanup

# update index test
echo "Update Index Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_index.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_index.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_index.lua cleanup

# update non index test
echo "Update Non-Index Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_non_index.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_non_index.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_update_non_index.lua cleanup

# point select test
echo "Point Select Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=1 --events=0 --time=60 /usr/share/sysbench/oltp_point_select.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=1 --events=0 --time=60 /usr/share/sysbench/oltp_point_select.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=1 --events=0 --time=60 /usr/share/sysbench/oltp_point_select.lua cleanup

# delete test
echo "Delete Test"
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_delete.lua prepare
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_delete.lua run
sysbench --db-driver=mysql --mysql-host=ip-172-31-19-0.ec2.internal --mysql_storage_engine=ndbcluster --mysql-user=root --mysql-db=sakila --table_size=10000 --threads=6 --events=0 --time=60 /usr/share/sysbench/oltp_delete.lua cleanup
