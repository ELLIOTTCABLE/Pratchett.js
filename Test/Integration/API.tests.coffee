support = require '../support.coffee'
expect  = require 'expect.js'

describe 'API consumers', ->
   they = it

   they "retain pristine globals after including Paws", ->
      require '../../Source/Paws.coffee'

      expect(-> Paws).to.throwError()

      expect(-> Thing).to.throwError()
      expect(-> Unit).to.throwError()

      expect(-> parse).to.throwError()
      expect(-> Expression).to.throwError()

      expect(-> debugging).to.throwError()
      expect(-> debug).to.throwError()
      expect(-> ENV).to.throwError()

      expect(-> _).to.throwError()
      expect(-> util).to.throwError()
      expect(-> terminal).to.throwError()
      expect(-> constructify).to.throwError()

   they "retain pristine globals after including `Interactive`", ->
      require '../../Source/interactive.coffee'

      expect(-> Paws).to.throwError()
      expect(-> Thing).to.throwError()

      expect(-> Interactive).to.throwError()

   they "retain pristine globals after including `Rule`", ->
      require '../../Source/rule.coffee'

      expect(-> Paws).to.throwError()
      expect(-> Thing).to.throwError()

      expect(-> Rule).to.throwError()
      expect(-> Collection).to.throwError()


describe 'The Paws API:', ->
   it.skip 'um...'
