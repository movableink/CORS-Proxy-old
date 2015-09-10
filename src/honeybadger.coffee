Badger = require 'node-honeybadger'
os = require 'os'

hb = new Badger
  apiKey: process.env['HONEYBADGER_API_KEY']
  server:
    hostname: os.hostname()
    environment: process.env['NODE_ENV'] || "development"
  logger: console

module.exports = hb
