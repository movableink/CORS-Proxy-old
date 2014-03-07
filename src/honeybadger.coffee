honeybadger = require 'honeybadger-node'

honeybadger.configure
  apiKey: '09cea8ab'
  environment: process.env['NODE_ENV'] || "development"

module.exports = honeybadger
