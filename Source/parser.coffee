`require = require('./cov_require.js')(require)`
Paws = require './Paws.coffee'

module.exports = parser =
  parse: (text) ->
    new Paws.Label(text)
  
  Expression: class Expression

