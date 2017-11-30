#!/usr/bin/env python3
import time, sys

from pprint import pprint

from lib.brex           import BittrexClient
from lib.notify         import Notifier
from lib.crycompare     import Price, History

def notify_percents(bittrexClient, notifyClient):
    btc     = 0
    summary = ''
    balances = bittrexClient.get_balances()['result']

    percents = dict()

    for balance in balances:
        if float(balance['Balance']['Balance']) > 0:
            pprint(balance)
            name     = balance['Currency']['Currency']
            nshares  = balance['Balance']['Balance']
            if name == 'BTC':
                pershare = 1
            else:
                if balance['BitcoinMarket'] is not None:
                    pershare = balance['BitcoinMarket']['Last']
                else:
                    pershare = 0

            amount = nshares * pershare
            percents[name] = amount

            btc     += amount
            #summary += '{} : {}\n    @{}/share\n'.format(name, nshares, pershare)
    for k, v in sorted(percents.items(), key=lambda kv : kv[1], reverse=True):
        summary += '{}: {}%\n'.format(k, round(v / btc * 100, 2))
    summary += 'Total BTC: {}\n'.format(btc)
    notifyClient.notify(summary)

def main(args):
    price         = Price
    history       = History
    bittrexClient = BittrexClient()
    notifyClient  = Notifier()

    while True:
        notify_percents(bittrexClient, notifyClient)
        for i in range(3600):
            print('.', end='')
            time.sleep(1)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
