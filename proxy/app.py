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
    """
    Retrieves the IP address of the manager instance.

    Returns:
        str: The IP address of the manager instance.
    """
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
    """
    Retrieves the IP addresses of the worker instances.

    Returns:
        list: The IP addresses of the worker instances.
    """
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
    """
    Sends a request to the worker instance.

    Args:
        worker_ip (str): The IP address of the worker instance.
        query (str): The query to send with the request.

    Returns:
        tuple: The response from the worker instance.
    """
    manager_ip = get_manager_ip()
    # Establish an SSH tunnel to the worker instance
    with SSHTunnelForwarder((worker_ip, 22), ssh_username='ubuntu', ssh_pkey='final_project_kp.pem', remote_bind_address=(manager_ip, 3306)) as tunnel:
        # Connect to the MySQL database on the manager instance
        connection = pymysql.connect(host=manager_ip, port=3306, user='root', password='', db='sakila')
        cursor = connection.cursor()
        cursor.execute(query) # Execute the SQL query
        data = cursor.fetchall() # Fetch all the rows from the result of the query
        connection.close() # Close the database connection
        return data

def direct_hit(query):
    """
    Sends a SQL request to the manager instance.

    Args:
        query (str): The SQL query to send.

    Returns:
        tuple: The response from the manager instance.
    """
    manager_ip = get_manager_ip()
    data = send_request(manager_ip, query)
    print(f"Sending request to manager, ip: {manager_ip}")
    return data
    

def send_request_to_random_worker(query):
    """
    Sends a SQL request to a random worker instance.

    Args:
        query (str): The SQL query to send.

    Returns:
        tuple: The response from the worker instance.
    """
    worker_ips = get_worker_ips()
    random_worker_ip = random.choice(worker_ips)
    data = send_request(random_worker_ip, query)
    print(f"Sending request to random worker, ip: {random_worker_ip}")
    return data

def ping(ip):
    """
    Pings the instance and returns true if it is up, false otherwise.

    Args:
        ip (str): The IP address of the instance.

    Returns:
        bool: True if the instance is up, False otherwise.
    """
    return os.system("ping -c 1 " + ip) == 0

def ping_time(ip):
    """
    Measures the time it takes to ping the instance.

    Args:
        ip (str): The IP address of the instance.

    Returns:
        float: The time it takes to ping the instance.
    """
    start = time.time()
    result = ping(ip)
    duration = time.time() - start

    if result:
        return duration
    else:
        return math.inf

def get_fastest_ping():
    """
    Measures the ping of each instance and returns the instance with the smallest ping.

    Returns:
        str: The IP address of the instance with the smallest ping.
    """
    print("Getting fastest ping...")
    worker_ips = get_worker_ips()
    min_ping = math.inf
    min_ping_ip = ""
    for ip in worker_ips:
        ping = ping_time(ip)
        if ping < min_ping:
            min_ping = ping
            min_ping_ip = ip # updates the ip with the smallest ping
    return min_ping_ip

def customized(query):
    """
    Sends a SQL request to the instance with the smallest ping.

    Args:
        query (str): The SQL query to send.

    Returns:
        tuple: The response from the instance.
    """
    min_ping_ip = get_fastest_ping()
    data = send_request(min_ping_ip, query)
    print(f"Sending request to instance with fastest ping: {min_ping_ip}")
    return data

@app.route('/')
def default():
    """
    The default route that returns a greeting.

    Returns:
        str: A greeting message.
    """
    return "Hello World!"

@app.route('/direct', methods=['GET'])
def direct():
    """
    The route for direct requests. Calls the direct_hit function which sends a SQL request to the manager instance.

    Returns:
        json: The response from the manager instance.
    """
    query = request.args.get('query')
    answer = direct_hit(query)
    return jsonify(answer) # response from the query converted to json

@app.route('/random', methods=['GET'])
def random_hit():
    """
    The route for random requests. Calls the send_request_to_random_worker function which sends a SQL request to a random worker instance.

    Returns:
        json: The response from a random worker instance.
    """
    query = request.args.get('query')
    answer = send_request_to_random_worker(query)
    return jsonify(answer) # response from the query converted to json

@app.route('/customized', methods=['GET'])
def custom_hit():
    """
    The route for customized requests. Calls the customized function which sends a SQL request to the instance with the smallest ping.

    Returns:
        json: The response from the instance with the smallest ping.
    """
    query = request.args.get('query')
    answer = customized(query)
    return jsonify(answer) # response from the query converted to json

if __name__ == "__main__":
    """
    The main entry point for the application.
    """
    app.run(host='0.0.0.0', port=5000)
