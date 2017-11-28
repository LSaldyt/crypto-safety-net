#!/usr/bin/env python3
import sys
from coinbaseclient import CoinbaseClient
from notify         import Notifier


def main(args):
    coinbaseClient = CoinbaseClient()
    notifyClient   = Notifier()

    '''
    while True:
        print(coinbaseClient.get_sell_price('BTC'))
        print(coinbaseClient.get_sell_price('LTC'))
    '''

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
