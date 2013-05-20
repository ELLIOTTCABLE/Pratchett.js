`require = require('./cov_require.js')(require)`

require('./additional.coffee') module.exports =
   paws = new Object

uuid = require 'uuid'

paws.utilities       = require('./utilities.coffee').infect global
paws.Unit   = Unit   = require './Unit.coffee'
paws.Script = Script = require './Script.coffee'

paws.Thing = Thing = parameterizable class Thing
   constructor: ->
      it = construct this
      
      it.id = uuid.v4()
      
      return it
