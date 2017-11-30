#!/usr/bin/env python3
import datetime, time, sys

from pprint import pprint

from lib.brex           import BittrexClient
from lib.notify         import Notifier
from lib.crycompare     import Price, History

def update(bittrexClient, notifyClient):
    btc     = 0
    summary = ''
    balances = bittrexClient.get_balances()['result']

    btcmarks = dict()

    for balance in balances:
        nshares = balance['Balance']['Balance']
        name    = balance['Currency']['Currency']
        if float(nshares) > 0:
            if name == 'BTC':
                pershare = 1
            else:
                if balance['BitcoinMarket'] is not None:
                    pershare = balance['BitcoinMarket']['Last']
                else:
                    pershare = 0

            amount = nshares * pershare

            btcmarks[name] = amount
            btc += amount

    for k, v in sorted(btcmarks.items(), key=lambda kv : kv[1], reverse=True):
        percent = v / btc * 100
        if percent > 1:
            summary += '{}: {}%\n'.format(k, round(percent, 2))
    summary += 'Total BTC: {}\n'.format(btc)
    notifyClient.notify(summary)

commandTree = {
    'update' : update
        }

def main(args):
    bittrexClient = BittrexClient()
    notifyClient  = Notifier()

    checked = set()
    while True:
        for message in notifyClient.client.messages.list():
            if message.direction == 'inbound':
                sent = message.date_sent
                now  = datetime.datetime.today()

                today = sent.day == now.day
                if today and message.sid not in checked:
                    checked.add(message.sid)
                    command = message.body.lower().strip()
                    if command in commandTree:
                        commandTree[command](bittrexClient, notifyClient)
                    else:
                        notifyClient.notify('Invalid command: {}'.format(command))
        print('Waiting...')
        time.sleep(1)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
