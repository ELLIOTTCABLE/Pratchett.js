expect = require 'expect.js'

describe "Paws' utilities", ->
   
   utilities = require '../Source/utilities'
   it 'should exist', ->
      expect(utilities).to.be.ok()
   
   run = utilities.runInNewContext
   describe '#runInNewContext', ->
      it 'should return a value', ->
         expect(run '42').to.be 42
