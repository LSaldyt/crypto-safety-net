#!/usr/bin/env python3
import datetime, pickle, time, sys, os

from pprint import pprint

from lib.brex       import BittrexClient
from lib.notify     import Notifier
from lib.crycompare import Price, History

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

def update(database, bittrexClient, notifyClient):
    summary = ''
    balances = bittrexClient.get_balances()['result']
    btcmarks = get_btcmarks(balances)
    btc      = sum(btcmarks.values())

    for k, v in sorted(btcmarks.items(), key=lambda kv : kv[1], reverse=True):
        percent = v / btc * 100
        if percent > 1:
            summary += '{}: {}%\n'.format(k, round(percent, 2))
    summary += 'Total BTC: {}\n'.format(btc)

    today     = datetime.datetime.today()
    yesterday = today - datetime.timedelta(days=1)

    balance = lambda date : sum(map(float, database[date.date()].values() if date.date() in database else []))

    change  = balance(today) - balance(yesterday)
    pchange = (change / max(balance(today), balance(yesterday))) / 100

    summary += 'Change: {}\n'.format(change)
    summary += 'P Change: {}%\n'.format(pchange)

    notifyClient.notify(summary)
    return database

commandTree = {
    'update' : update
        }

def save_data(database, bittrexClient):
    balances = bittrexClient.get_balances()['result']
    btcmarks = get_btcmarks(balances)
    btcprice = get_btc_price(balances)
    usdmarks = {k : v * btcprice for k, v in btcmarks.items()}
    database[datetime.datetime.today().date()] = usdmarks

def main(args):
    bittrexClient = BittrexClient()
    notifyClient  = Notifier()

    datafile = '.data.pkl'

    if os.path.isfile(datafile):
        with open(datafile, 'rb') as infile:
            database = pickle.load(infile)
    else:
        database = dict()
    try:
        checked = database['checked'] if 'checked' in database else set()
        while True:
            save_data(database, bittrexClient)
            for message in notifyClient.client.messages.list():
                if message.direction == 'inbound':
                    sent = message.date_sent
                    now  = datetime.datetime.utcnow()
                    print(now)
                    #now  = datetime.datetime.today() + datetime.timedelta(hours=7)
                    today  = sent.day == now.day
                    hour   = sent.hour == now.hour
                    minute = abs(sent.minute - now.minute) < 2
                    if today and hour and minute and message.sid not in checked:
                        checked.add(message.sid)
                        command = message.body.lower().strip()
                        print('Recieved command: {}'.format(command))
                        if command in commandTree:
                            commandTree[command](database, bittrexClient, notifyClient)
                        else:
                            notifyClient.notify('Invalid command: {}'.format(command))
            print('Waiting', end='')
            for i in range(2):
                time.sleep(1)
                print('.', end='', flush=True)
            print('')
            pprint(database)
        database['checked'] = checked
    finally:
        with open(datafile, 'wb') as outfile:
            pickle.dump(database, outfile)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
