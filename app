#!/usr/bin/env python3
import datetime, pickle, time, sys, os

from pprint     import pprint
from contextlib import contextmanager

from lib.brex           import BittrexClient 
from lib.get            import get_usd_marks
from lib.notify         import Notifier
from lib.crycompare     import Price, History
from lib.coinbaseclient import CoinbaseClient

from cord import Cord

def dist_summary(brex, cbase):
    summary = ''
    usdmarks = get_usd_marks(brex, cbase)
    total = sum(usdmarks.values())

    for k, v in sorted(usdmarks.items(), key=lambda kv : kv[1], reverse=True):
        percent = v / total * 100
        if percent > 1:
            summary += '{}: {}%\n'.format(k, round(percent, 2))
    summary += 'Total USD: {}\n'.format(total)
    return summary

def update_change(date, database):
    today = datetime.datetime.today().date()
    summary = ''
    get_db_usdmarks = lambda date : database.get(date, dict())
    balance = lambda date : sum(map(float, get_db_usdmarks(date).values()))
    change  = balance(today) - balance(date)
    get_p   = lambda v1, v2 : round(((v1 - v2) / max(v1, v2, 1)) * 100, 4)
    pchange = get_p(balance(today), balance(date))

    todaydict = get_db_usdmarks(today)
    otherdict = get_db_usdmarks(date)

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
    brex = BittrexClient()
    cbase = CoinbaseClient()

    summary = ''
    summary += dist_summary(brex, cbase)
    summary += update_since(usdmarks, days=1)
    summary += update_since(usdmarks, days=7)

    original = min(list(usdmarks.keys()) + [datetime.datetime.today().date()])
    summary += 'All time:\n'
    summary += update_change(original, usdmarks)

    summary += 'Sent using cord\n'

    notifyClient.notify(summary)
    return database

def save_data(database):
    cbase = CoinbaseClient()
    brex  = BittrexClient()
    usdmarks = get_usd_marks(brex, cbase)
    if 'usdmarks' not in database:
        database['usdmarks'] = dict()
    database['usdmarks'][datetime.datetime.today().date()] = usdmarks

if __name__ == '__main__':
    cord = Cord(dict(update=update), save_data, lambda database: print('Cryptometric..'))
    cord.loop()
