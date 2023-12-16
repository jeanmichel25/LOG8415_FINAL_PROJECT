import math
import random
import time
import boto3
import pymysql
import os
import sys
from sshtunnel import SSHTunnelForwarder

from credentials import *

session = boto3.Session(
    aws_access_key_id = access_key,
    aws_secret_access_key = secret_key,
    aws_session_token = token,
    region_name= "us-east-1"
)
ec2_resource = session.resource('ec2')

def get_manager_ip():
    manager = ec2_resource.instances.filter(Filters=[{'Name': 'tag:Name', 'Values': ['manager']}])
    for instance in manager:
        manager_ip = instance.public_ip_address
    return manager_ip

def get_worker_ips():
    workers = ec2_resource.instances.filter(Filters=[{'Name': 'tag:Name', 'Values': ['worker']}])
    worker_ips = []
    for worker in workers:
        worker_ips.append(worker.public_ip_address)
    return worker_ips

def send_request(worker_ip, query):
    manager_ip = get_manager_ip()
    with SSHTunnelForwarder(worker_ip, ssh_username='ubuntu', ssh_pkey='vockey.pem', remote_bind_address=(manager_ip, 3306)) as tunnel:
        connection = pymysql.connect(host=manager_ip, port=3306, user='root', password='', db='sakila')
        cursor = connection.cursor()
        cursor.execute(query)
        data = cursor.fetchall()
        connection.close()
        return data

def direct_hit(query):
    # send sql request to manager instance
    manager_ip = get_manager_ip()
    return send_request(manager_ip, query)
    

def send_request_to_random_worker(query):
    print("Sending request to random worker")
    worker_ips = get_worker_ips()
    random_worker_ip = random.choice(worker_ips)
    # send sql request to random worker instance
    return send_request(random_worker_ip, query)

def ping(ip):
    # ping the instance and return true if it is up, false otherwise.
    return os.system("ping -c 1 " + ip) == 0

def ping_time(ip):
    # measure the time it takes to ping the instance
    start = time.time()
    result = ping(ip)
    duration = time.time() - start

    if result:
        # the instance is up
        return duration
    else:
        # the instance is not responding
        return math.inf

# measure the ping of each instance and return the instance with the smallest ping
def get_fastest_ping():
    print("Getting fastest ping...")
    worker_ips = get_worker_ips()
    min_ping = math.inf
    min_ping_ip = ""
    for ip in worker_ips:
        ping = ping_time(ip)
        if ping < min_ping:
            min_ping = ping
            min_ping_ip = ip
    return min_ping_ip

# send request to instance with smallest ping
def customized(query):
    min_ping_ip = get_fastest_ping()
    print("Sending request to instance with fastest ping: {min_ping_ip}")
    return send_request(min_ping_ip, query)

if __name__ == "__main__":
    req_type = sys.argv[1]
    query = sys.argv[2]
    answer = ""

    if req_type == "direct":
        answer = direct_hit(query)
    elif req_type == "random":
        answer = send_request_to_random_worker(query)
    elif req_type == "customized":
        answer = customized(query)

    print(answer)