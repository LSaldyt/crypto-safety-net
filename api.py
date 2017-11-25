from coinbase.wallet.client import Client

def init_client(filename='etc/.api'):
    with open(filename, 'r') as infile:
        lines = [line for line in infile]
    key    = str(lines[0]).strip()
    secret = str(lines[1]).strip()

    client = Client(key, secret, api_version='2017-10-09')
    return client
