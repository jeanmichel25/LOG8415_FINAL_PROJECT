import requests
import paramiko
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

def get_gatekeeper_ip():
    gatekeeper = ec2_resource.instances.filter(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': ['gatekeeper']}
        ]
    )
    for instance in gatekeeper:
        gatekeeper_ip = instance.public_ip_address
    return gatekeeper_ip

def create_ssh_tunnel_and_send_request(gatekeeper_ip, trusted_host_ip, req_type, query):
    print(f"Creating SSH tunnel to {trusted_host_ip}...")
    print(f"gatekeeper_ip: {gatekeeper_ip}")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    private_key = paramiko.RSAKey.from_private_key_file('final_project_kp.pem')
    client.connect(gatekeeper_ip, username='ubuntu', pkey=private_key)

    # Use the SSH transport to establish a tunnel
    transport = client.get_transport()
    local_port = 9000
    channel = transport.open_channel("direct-tcpip", (trusted_host_ip, 5000), ("127.0.0.1", local_port))

    # Send the request through the tunnel
    response = requests.get(f"http://127.0.0.1:{local_port}/{req_type}?query={query}")

    # Close the channel and the client
    channel.close()
    client.close()

    return response.text

@app.route('/')
def default():
    return "Hello World!"

@app.route('/direct', methods=['GET'])
def direct():
    query = request.args.get('query')
    res = create_ssh_tunnel_and_send_request(get_gatekeeper_ip(), get_trusted_host_ip(), 'direct', query)
    print(res)
    return res

@app.route('/random', methods=['GET'])
def random_hit():
    query = request.args.get('query')
    res = create_ssh_tunnel_and_send_request(get_gatekeeper_ip(), get_trusted_host_ip(), 'random', query)
    print(res)
    return res

@app.route('/customized', methods=['GET'])
def custom_hit():
    query = request.args.get('query')
    res = create_ssh_tunnel_and_send_request(get_gatekeeper_ip(), get_trusted_host_ip(), 'customized', query)
    print(res)
    return res

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)