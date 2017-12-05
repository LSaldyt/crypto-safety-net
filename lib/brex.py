from bittrex import Bittrex, API_V2_0
from .get import *

def BittrexClient(filename='etc/.brex'):
    with open(filename, 'r') as infile:
        lines = [line for line in infile]
    key    = str(lines[0]).strip()
    secret = str(lines[1]).strip()
    return Bittrex(key, secret, api_version=API_V2_0)
