# from sshtunnel import SSHTunnelForwarder
from sshtunnel import SSHTunnelForwarder
import requests
import boto3
from flask import Flask, request

from credentials import *

app = Flask(__name__)

session = boto3.Session(
    aws_access_key_id = access_key,
    aws_secret_access_key = secret_key,
    aws_session_token = token,
    region_name= "us-east-1"
)
ec2_resource = session.resource('ec2')

def format_ip(ip_address):
    formatted = ip_address.replace(".", "-")
    return f"ec2-{formatted}.compute-1.amazonaws.com"

def get_trusted_host_ip():
    trusted_host = ec2_resource.instances.filter(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': ['trusted_host']}
        ]
    )
    for instance in trusted_host:
        trusted_host_ip = instance.public_ip_address
    return trusted_host_ip

def send_request(trusted_host_ip, req_type, query):
    trusted_host_dns = format_ip(trusted_host_ip)
    with SSHTunnelForwarder(
        (trusted_host_dns, 22), 
        ssh_username='ubuntu', 
        ssh_pkey='final_project_kp.pem', 
        remote_bind_address=(trusted_host_dns, 9000),
        local_bind_address=("127.0.0.1", 80)
    ) as tunnel:
        response = requests.get(f'http://{trusted_host_dns}/{req_type}?query={query}')
        return response.text

@app.route('/')
def default():
    return "Hello World!"

@app.route('/direct', methods=['GET'])
def direct():
    query = request.args.get('query')
    res = send_request(get_trusted_host_ip(), 'direct', query)
    print(res)
    return res

@app.route('/random', methods=['GET'])
def random_hit():
    query = request.args.get('query')
    res = send_request(get_trusted_host_ip(), 'random', query)
    print(res)
    return res

@app.route('/customized', methods=['GET'])
def custom_hit():
    query = request.args.get('query')
    res = send_request(get_trusted_host_ip(), 'customized', query)
    print(res)
    return res

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)