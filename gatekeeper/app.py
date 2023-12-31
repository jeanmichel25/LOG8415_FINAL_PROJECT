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
    """
    Formats the given IP address to be used in an EC2 hostname.

    Args:
        ip_address (str): The IP address to format.

    Returns:
        str: The formatted hostname.
    """
    formatted = ip_address.replace(".", "-")
    return f"ec2-{formatted}.compute-1.amazonaws.com"


def get_trusted_host_ip():
    """
    Retrieves the IP address of the trusted host.

    Returns:
        str: The IP address of the trusted host.
    """
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
    """
    Sends a request to the trusted host.

    Args:
        trusted_host_ip (str): The IP address of the trusted host.
        req_type (str): The type of request to send.
        query (str): The query to send with the request.

    Returns:
        Response: The response from the trusted host.
    """
    trusted_host_dns = format_ip(trusted_host_ip) # format the IP address to be in dns format
    # create a tunnel to the trusted host
    with SSHTunnelForwarder(
        (trusted_host_dns, 22), 
        ssh_username='ubuntu', 
        ssh_pkey='final_project_kp.pem', 
        remote_bind_address=(trusted_host_dns, 80),
        local_bind_address=("127.0.0.1", 80)
    ) as tunnel:
        response = requests.get(f'http://{trusted_host_dns}/{req_type}?query={query}')
        return response

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
    The route for direct requests.

    Returns:
        str: The response text from the trusted host.
    """
    query = request.args.get('query')
    trusted_host_ip = get_trusted_host_ip()
    response = send_request(trusted_host_ip, 'direct', query)
    return response.text # response from the trusted host, which is the response from the query. Converted to text.

@app.route('/random', methods=['GET'])
def random_hit():
    """
    The route which sends requests to a random worker node.

    Returns:
        str: The response text from the trusted host.
    """
    query = request.args.get('query')
    trusted_host_ip = get_trusted_host_ip()
    response = send_request(trusted_host_ip, 'random', query)
    return response.text # response from the trusted host, which is the response from the query. Converted to text.

@app.route('/customized', methods=['GET'])
def custom_hit():
    """
    The route which sends the request to the fastest worker node.

    Returns:
        str: The response text from the trusted host.
    """
    query = request.args.get('query')
    trusted_host_ip = get_trusted_host_ip()
    response = send_request(trusted_host_ip, 'customized', query)
    return response.text # response from the trusted host, which is the response from the query. Converted to text.

if __name__ == "__main__":
    """
    The main entry point for the application.
    """
    app.run(host='0.0.0.0', port=5000)
