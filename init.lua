api_key = '-- your gdax api key --'
secret_key = '-- your gdax secret key --'
passphrase = '-- your gdax passphrase --'
totalInvested = 0 -- how much you invested totally
offlineBalances = { -- other balances to include in computation
  EUR = 0,
  BTC = 0.05,
  ETH = 0,
  LTC = 0
}

function getPrice(pair)
  _, res = hs.http.get('https://api.gdax.com/products/' .. pair .. '/ticker')
  data = hs.json.decode(res)
  return tonumber(data['price'])
end

function getProfit(balances, prices)
  return 
    balances['EUR']
    + prices['BTC'] * balances['BTC']
    + prices['ETH'] * balances['ETH']
    + prices['LTC'] * balances['LTC']
    - totalInvested
end

function decodeHexString(str)
  return ( 
    str:gsub( '..', function (cc)
      return string.char(tonumber(cc, 16))
    end)
  )
end

function getGdaxAuthHeaders(method, url, body)
  local timestamp = tostring(hs.timer.secondsSinceEpoch())
  local message = timestamp .. method .. url .. body
  local hmac_key = hs.base64.decode(secret_key)
  local signature = hs.hash.hmacSHA256(hmac_key, message)
  local signature_b64 = hs.base64.encode(decodeHexString(signature))
  local headers = {}
  headers['CB-ACCESS-SIGN'] = signature_b64
  headers['CB-ACCESS-TIMESTAMP'] = timestamp
  headers['CB-ACCESS-KEY'] = api_key
  headers['CB-ACCESS-PASSPHRASE'] = passphrase
  headers['Content-Type'] = 'application/json'
  return headers
end

function getBalances()
  local headers = getGdaxAuthHeaders('GET', '/accounts', '')
  local _, res = hs.http.get('https://api.gdax.com/accounts', headers)
  local data = hs.json.decode(res)
  local balances = {}

  for _,row in pairs(data) do
    balances[row['currency']] = tonumber(row['balance']) + offlineBalances[row['currency']]
  end
  return balances
end

function getPrices()
  local prices = {}
  prices['BTC'] = getPrice('BTC-EUR')
  prices['ETH'] = getPrice('ETH-EUR')
  prices['LTC'] = getPrice('LTC-EUR')

  return prices
end

function update()
  prices = getPrices()
  balances = getBalances()
  profit = getProfit(balances, prices)

  menu:setMenu({
    { title = 'BTC: ' .. prices['BTC'] },
    { title = 'ETH: ' .. prices['ETH'] },
    { title = 'LTC: ' .. prices['LTC'] }
  })
  menu:setTitle(' ' .. tostring(math.floor(profit)))
end

menu = hs.menubar.new()
menu:setIcon('~/Documents/biticon.png')
update()
hs.timer.doEvery(60, update)