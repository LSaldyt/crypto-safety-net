from pprint import pprint

def get_marks(client):
    btcmarks = get_btcmarks(client)
    btcprice = float(client.get_ticker('USDT-BTC')['result']['Last'])
    usdmarks = {k : v * btcprice for k, v in btcmarks.items()}
    return btcmarks, usdmarks

def get_btcmarks(client):
    balances = client.get_balances()['result']
    pprint(balances)
    btcmarks = dict()
    for balance in balances:
        nshares = balance['Balance']
        name    = balance['Currency']
        if float(nshares) > 0:
            if name == 'BTC':
                pershare = 1
            else:
                market = client.get_ticker('BTC-{}'.format(name))['result']
                if market is None:
                    pershare = 0
                else:
                    pershare = market['Last']

            amount = nshares * pershare

            btcmarks[name] = amount
    return btcmarks
