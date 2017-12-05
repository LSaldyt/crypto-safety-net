def get_marks(client):
    balances = client.get_balances()['result']
    btcmarks = get_btcmarks(balances)
    btcprice = get_btc_price(balances)
    usdmarks = {k : v * btcprice for k, v in btcmarks.items()}
    return btcmarks, usdmarks

def get_btcmarks(balances, market='BitcoinMarket'):
    btcmarks = dict()
    for balance in balances:
        nshares = balance['Balance']['Balance']
        name    = balance['Currency']['Currency']
        if float(nshares) > 0:
            if name == 'BTC':
                pershare = 1
            else:
                if balance[market] is not None:
                    pershare = balance[market]['Last']
                else:
                    pershare = 0

            amount = nshares * pershare

            btcmarks[name] = amount
    return btcmarks

def get_btc_price(balances):
    for balance in balances:
        name = balance['Currency']['Currency']
        if name == 'USDT':
            return float(balance['FiatMarket']['Last'])
