#!/usr/bin/env python3
import time, sys

from pprint import pprint

from lib.brex           import BittrexClient
from lib.notify         import Notifier
from lib.crycompare     import Price, History

def show_balances(bittrexClient, notifyClient):
    btc     = 0
    summary = ''
    for balance in bittrexClient.get_balances()['result']:
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

            btc     += nshares * pershare
            summary += '{} : {}\n    @{}/share\n'.format(name, nshares, pershare)
    summary += 'Total BTC: {}\n'.format(btc)
    notifyClient.notify(summary)

def main(args):
    price         = Price
    history       = History
    bittrexClient = BittrexClient()
    notifyClient  = Notifier()

    while True:
        #print(coinbaseClient.get_sell_price('BTC'))
        #print(coinbaseClient.get_sell_price('LTC'))
        #print(dir(bittrexClient))
        #pprint(bittrexClient.get_balances()['result'][0])
        #1/0
        #pprint(bittrexClient.get_markets())
        #print(dir(bittrexClient))
        #print(bittrexClient.get_currencies())
        #print(bittrexClient.get_market_history('USDT-BTC'))
        #show_balances(bittrexClient, notifyClient)
        #print(price.priceHistorical('USD', 'BTC'))
        print(history.histoDay('BTC', 'USD'))
        for i in range(3600):
            print('.', end='')
            time.sleep(1)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
