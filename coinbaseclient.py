from coinbase.wallet.client import Client

class CoinbaseClient():
    def __init__(self, filename='etc/.api'):

        with open(filename, 'r') as infile:
            lines = [line for line in infile]
        key    = str(lines[0]).strip()
        secret = str(lines[1]).strip()

        self.client = Client(key, secret, api_version='2017-10-09')

        self.accountDict = dict()
        accounts = self.client.get_accounts()
        for account in accounts.data:
          self.accountDict[account.name] = account

    def get_sell_price(self, pair):
        return float(self.client.get_sell_price(currency_pair=pair)['amount'])

    def get_buy_price(self, pair):
        return float(self.client.get_pair_price(currency_pair=pair)['amount'])

    def sell(self, currency, amount):
        wallet = '{} Wallet'.format(currency)
        sell = self.client.sell(self.accountDict[wallet].id,
                           amount=self.accountDict[wallet].balance.amount,
                           currency=currency)
        return sell

    def buy(self, currency, amount):
        wallet = '{} Wallet'.format(currency)
        buy = self.client.buy(self.accountDict[wallet].id,
            amount=str(amount),
            currency=currency)
