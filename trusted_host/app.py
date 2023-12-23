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

def get_proxy_dns():
    proxy = ec2_resource.instances.filter(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': ['proxy']}
        ]
    )
    for instance in proxy:
        proxy_ip = instance.public_ip_address
    dns = "http://" + proxy_ip
    return dns

@app.route('/')
def default():
    return "Hello World!"

@app.route('/direct', methods=['GET'])
def direct():
    query = request.args.get('query')
    dns = get_proxy_dns()
    res = requests.get(f"{dns}/direct?query={query}")
    print(res)
    return res.text

@app.route('/random', methods=['GET'])
def random_hit():
    query = request.args.get('query')
    dns = get_proxy_dns()
    res = requests.get(f"{dns}/random?query={query}")
    print(res)
    return res.text

@app.route('/customized', methods=['GET'])
def custom_hit():
    query = request.args.get('query')
    dns = get_proxy_dns()
    res = requests.get(f"{dns}/customized?query={query}")
    return res.text

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)