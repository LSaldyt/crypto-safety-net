# Notes

A simple trading algorithm for cryptocurrency:

Create a logarithmic regression model of the currency.
Let n be some amount, expressed in fiat currency, that is willing to be traded.
The bot will invest n at some initial price.
Then, whenever market price is above model price, the bot will sell an amount proportional to the difference from model price.
Whenever market price is below model price, the bot will use excess fiat under amount n to "buy dips" 

The bot will track the amount of profit that it has made relative to the profit that would've been made if the currency had been cold-held.
Based on this, and potentially on other metrics, the bot will come up with some caution score that determines its probability of trading.


