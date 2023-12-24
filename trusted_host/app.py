import requests
from sshtunnel import SSHTunnelForwarder
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


def get_proxy_ip():
    proxy = ec2_resource.instances.filter(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': ['proxy']}
        ]
    )
    for instance in proxy:
        proxy_ip = instance.public_ip_address
    return proxy_ip

def send_request(proxy_ip, req_type, query):
    proxy_dns = format_ip(proxy_ip)
    with SSHTunnelForwarder(
        (proxy_dns, 22), 
        ssh_username='ubuntu', 
        ssh_pkey='final_project_kp.pem', 
        remote_bind_address=(proxy_dns, 80),
        local_bind_address=("127.0.0.1", 80)
    ) as tunnel:
        response = requests.get(f'http://{proxy_dns}/{req_type}?query={query}')
        return response.text

@app.route('/')
def default():
    return "Hello World!"

@app.route('/direct', methods=['GET'])
def direct():
    query = request.args.get('query')
    res = send_request(get_proxy_ip(), 'direct', query)
    return res

@app.route('/random', methods=['GET'])
def random_hit():
    query = request.args.get('query')
    res = send_request(get_proxy_ip(), 'random', query)
    return res

@app.route('/customized', methods=['GET'])
def custom_hit():
    query = request.args.get('query')
    res = send_request(get_proxy_ip(), 'customized', query)
    return res

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)