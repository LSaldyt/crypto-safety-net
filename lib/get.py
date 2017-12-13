from pprint import pprint

def get_usd_marks(brex, cbase):
    a = get_usd_marks_brex(brex)
    b = get_usd_marks_cbase(cbase, brex)
    d = {k : a.get(k, 0.0) + b.get(k, 0.0)
            for k in set(a.keys()) | set(b.keys())}
    return d

def brex_last(client, market):
    try:
        return float(client.get_ticker(market)['result']['Last'])
    except:
        return 0

def get_usd_marks_brex(client):
    btcmarks = get_btcmarks_brex(client)
    btcprice = brex_last(client, 'USDT-BTC')
    usdmarks = {k : v * btcprice for k, v in btcmarks.items()}
    return usdmarks

def get_usd_marks_cbase(cbase, brex):
    convert = lambda s : s.replace('Wallet', '').strip()
    extract = lambda d : float(d['balance'].amount)
    items   = cbase.accountDict.items()
    amounts = {convert(k) : extract(v) for k, v in items}
    usdmarks = {k : brex_last(brex, 'USDT-{}'.format(k)) * v
                for k, v in amounts.items()}
    return usdmarks

def get_btcmarks_brex(client):
    balances = client.get_balances()['result']
    btcmarks = dict()
    for balance in balances:
        nshares = balance['Balance']
        name    = balance['Currency']
        if float(nshares) > 0:
            if name == 'BTC':
                pershare = 1
            else:
                pershare = brex_last(client,'BTC-{}'.format(name))

            amount = nshares * pershare

            btcmarks[name] = amount
    return btcmarks
