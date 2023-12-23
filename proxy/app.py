import math
import random
import time
import boto3
import pymysql
import os
from flask import Flask, request, jsonify
from sshtunnel import SSHTunnelForwarder

from credentials import *

app = Flask(__name__)

session = boto3.Session(
    aws_access_key_id = access_key,
    aws_secret_access_key = secret_key,
    aws_session_token = token,
    region_name= "us-east-1"
)
ec2_resource = session.resource('ec2')

def get_manager_ip():
    manager = ec2_resource.instances.filter(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': ['manager']}
        ]
    )
    for instance in manager:
        manager_ip = instance.public_ip_address
    return manager_ip


def get_worker_ips():
    workers = ec2_resource.instances.filter(Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': ['worker']}        
        ]
    )
    worker_ips = []
    for worker in workers:
        worker_ips.append(worker.public_ip_address)
    return worker_ips

def send_request(worker_ip, query):
    manager_ip = get_manager_ip()
    with SSHTunnelForwarder((worker_ip, 22), ssh_username='ubuntu', ssh_pkey='final_project_kp.pem', remote_bind_address=(manager_ip, 3306)) as tunnel:
        connection = pymysql.connect(host=manager_ip, port=3306, user='root', password='', db='sakila')
        cursor = connection.cursor()
        cursor.execute(query)
        data = cursor.fetchall()
        connection.close()
        return data

def direct_hit(query):
    # send sql request to manager instance
    manager_ip = get_manager_ip()
    data = send_request(manager_ip, query)
    print(f"Sending request to manager, ip: {manager_ip}")
    return data
    

def send_request_to_random_worker(query):
    worker_ips = get_worker_ips()
    random_worker_ip = random.choice(worker_ips)
    # send sql request to random worker instance
    data = send_request(random_worker_ip, query)
    print(f"Sending request to random worker, ip: {random_worker_ip}")
    return data

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
    data = send_request(min_ping_ip, query)
    print(f"Sending request to instance with fastest ping: {min_ping_ip}")
    return data

@app.route('/')
def default():
    return "Hello World!"

@app.route('/direct', methods=['GET'])
def direct():
    query = request.args.get('query')
    answer = direct_hit(query)
    return jsonify(answer)

@app.route('/random', methods=['GET'])
def random_hit():
    query = request.args.get('query')
    answer = send_request_to_random_worker(query)
    return jsonify(answer)

@app.route('/customized', methods=['GET'])
def custom_hit():
    query = request.args.get('query')
    answer = customized(query)
    return jsonify(answer)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)