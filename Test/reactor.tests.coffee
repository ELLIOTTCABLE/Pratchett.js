`                                                                                                                 /*|*/ require = require('../Library/cov_require.js')(require)`
assert = require 'assert'
expect = require 'expect.js'

Paws = require "../Source/Paws.coffee"
Paws.utilities.infect global, Paws

describe 'The Paws reactor:', ->
   reactor = Paws.reactor
   it 'should exist', ->
      expect(reactor).to.be.ok()
   
   
   describe 'Ownership Table', ->
      Table = reactor.Table
      it 'should exist', ->
         expect(Table).to.be.ok()
      
      it 'should store a Thing for a given Execution', ->
         table = new Table
         
         an_xec = new Execution
         a_thing = new Thing
         
         expect(-> table.give an_xec, a_thing).not.to.throwError()
         expect(table.get(an_xec)).to.contain a_thing
      
      it 'should store multiple Things for a given Execution', ->
         table = new Table
         
         an_xec = new Execution
         a_thing = new Thing
         expect(-> table.give an_xec, a_thing).not.to.throwError()
         expect(table.get(an_xec)).to.contain a_thing
         
         another_thing = new Thing
         expect(-> table.give an_xec, another_thing).not.to.throwError()
         expect(table.get(an_xec)).to.contain another_thing
         expect(table.get(an_xec)).to.contain a_thing
      
      it 'should separately store Things for multiple Executions', ->
         table = new Table
         
         an_xec = new Execution
         [thing_A, thing_B] = [new Thing, new Thing]
         table.give an_xec, thing_A, thing_B
         expect(table.get(an_xec)).to.contain thing_A
         expect(table.get(an_xec)).to.contain thing_B
         
         another_xec = new Execution
         [thing_X, thing_Y] = [new Thing, new Thing]
         table.give another_xec, thing_X, thing_Y
         expect(table.get(another_xec)).to.contain thing_X
         expect(table.get(another_xec)).to.contain thing_Y
         expect(table.get(another_xec)).to.not.contain thing_A
         expect(table.get(another_xec)).to.not.contain thing_B