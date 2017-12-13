from bittrex import Bittrex

def BittrexClient(filename='etc/.brex'):
    with open(filename, 'r') as infile:
        lines = [line for line in infile]
    key    = str(lines[0]).strip()
    secret = str(lines[1]).strip()
    return Bittrex(key, secret)
