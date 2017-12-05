#!/usr/bin/env python3
import datetime, pickle, time, sys, os

from pprint     import pprint
from contextlib import contextmanager

from lib.brex       import BittrexClient
from lib.notify     import Notifier
from lib.crycompare import Price, History

from lib.brex       import get_marks

def dist_summary(bittrexClient):
    summary = ''
    btcmarks, usdmarks = get_marks(bittrexClient)
    btc = sum(btcmarks.values())

    for k, v in sorted(btcmarks.items(), key=lambda kv : kv[1], reverse=True):
        percent = v / btc * 100
        if percent > 1:
            summary += '{}: {}%\n'.format(k, round(percent, 2))
    summary += 'Total BTC: {}\n'.format(btc)
    summary += 'Total USD: {}\n'.format(sum(usdmarks.values()))
    return summary

def update(database, bittrexClient, notifyClient):
    summary = dist_summary(bittrexClient)
    today = datetime.datetime.today().date()

    def update_change(date):
        get_usdmarks = lambda date : database.get(date, dict())
        balance = lambda date : sum(map(float, usdmarks(date).values()))
        change  = balance(today) - balance(date)
        get_p   = lambda v1, v2 : round(((v1 - v2) / max(v1, v2, 1)) * 100, 4)
        pchange = get_p(balance(today), balance(date))

        todaydict = get_usdmarks(today)
        otherdict = get_usdmarks(date)

        pdict   = {k : get_p(todaydict[k], otherdict[k]) for k in todaydict.keys()}

        summary += 'Change: {}%\n'.format(pchange)
        summary += 'Change: {}\n'.format(change)
        #summary += 'Change: {}\n'.format(pdict)

    def update_since(**kwargs):
        since = today - datetime.timedelta(**kwargs)
        summary += 'Since {}'.format(since)
        update_change(since)

    update_since(days=1)
    update_since(days=7)
    update_since(months=1)
    update_since(months=3)
    update_since(months=6)
    update_since(years=1)

    original  = min(database.keys())
    summary += 'All time:\n'
    update_change(original)

    notifyClient.notify(summary)
    return database

commandTree = {
    'update' : update
        }

@contextmanager
def retrieve(database, name, default):
    element = database.get(name, default)
    yield element
    database[name] = element

def respond(database, bittrexClient, notifyClient):
    for message in notifyClient.client.messages.list():
        if message.direction == 'inbound':
            sent = message.date_sent
            now  = datetime.datetime.utcnow()
            today  = sent.day == now.day
            hour   = sent.hour == now.hour
            minute = abs(sent.minute - now.minute) < 2
            if today and hour and minute and message.sid not in checked:
                checked.add(message.sid)
                command = message.body.strip().lower()
                print('Recieved command: {}'.format(command))
                if command in commandTree:
                    commandTree[command](database, bittrexClient, notifyClient)
                else:
                    notifyClient.notify('Invalid command: {}'.format(command))

def save_data(database, bittrexClient):
    btcmarks, usdmarks = get_marks(bittrexClient)
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
        print('Waiting...', end='', flush=True)
        with retrieve(database, 'checked', set()) as checked:
            while True:
                save_data(database, bittrexClient)
                respond(database, bittrexClient, notifyClient)
                time.sleep(1)
                print('.', end='', flush=True)
    finally:
        with open(datafile, 'wb') as outfile:
            pickle.dump(database, outfile)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
