expect = require 'expect.js'

describe "Paws' utilities", ->
   
   utilities = require '../Source/utilities'
   it 'should exist', ->
      expect(utilities).to.be.ok()
   
   describe '#runInNewContext', ->
      him = utilities.runInNewContext
      it 'should return a value', ->
         expect(him '42').to.be.ok()
