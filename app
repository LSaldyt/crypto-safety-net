#!/usr/bin/env python3
import datetime, pickle, time, sys, os

from pprint     import pprint
from contextlib import contextmanager

from lib.brex       import BittrexClient, get_marks
from lib.notify     import Notifier
from lib.crycompare import Price, History

from cord import Cord

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

def update_change(date, database):
    today = datetime.datetime.today().date()
    summary = ''
    get_usdmarks = lambda date : database.get(date, dict())
    balance = lambda date : sum(map(float, get_usdmarks(date).values()))
    change  = balance(today) - balance(date)
    get_p   = lambda v1, v2 : round(((v1 - v2) / max(v1, v2, 1)) * 100, 4)
    pchange = get_p(balance(today), balance(date))

    todaydict = get_usdmarks(today)
    otherdict = get_usdmarks(date)

    pdict   = {k : get_p(todaydict.get(k, 0), otherdict.get(k, 0)) for k in todaydict.keys()}

    summary += 'Change: {}%\n'.format(round(pchange, 4))
    summary += 'Change: {}\n'.format(round(change, 4))
    return summary

def update_since(database, **kwargs):
    today = datetime.datetime.today().date()
    summary = ''
    since = today - datetime.timedelta(**kwargs)
    summary += 'Since {}:\n'.format(since)
    summary += update_change(since, database)
    return summary

def update(database, notifyClient):
    usdmarks = database.get('usdmarks', dict())
    bittrexClient = BittrexClient()

    summary = ''
    summary += dist_summary(bittrexClient)
    summary += update_since(usdmarks, days=1)
    summary += update_since(usdmarks, days=7)

    original = min(list(usdmarks.keys()) + [datetime.datetime.today().date()])
    summary += 'All time:\n'
    summary += update_change(original, usdmarks)

    summary += 'Sent using cord\n'

    notifyClient.notify(summary)
    return database

def save_data(database):
    client = BittrexClient()
    bitmarks, usdmarks = get_marks(client)
    if 'usdmarks' not in database:
        database['usdmarks'] = dict()
    database['usdmarks'][datetime.datetime.today().date()] = usdmarks

if __name__ == '__main__':
    cord = Cord(dict(update=update), save_data)
    cord.loop()
