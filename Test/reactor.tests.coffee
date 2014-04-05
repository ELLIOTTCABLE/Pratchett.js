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
   
   describe 'Unit utilities', ->
      Unit = reactor.Unit
      
      describe '##mask', ->
         it 'should always return a least the roots passed in', ->
            [a_thing, another_thing] = [new Thing, new Thing]
            expect(Unit.mask a_thing, another_thing).to.contain a_thing
            expect(Unit.mask a_thing, another_thing).to.contain another_thing
         
         it 'should include anything owned by those roots', ->
            [a_thing, another_thing] = [new Thing, new Thing]
            root_thing = Thing.construct {something: a_thing, something_else: another_thing}
            expect(Unit.mask root_thing).to.contain a_thing
            expect(Unit.mask root_thing).to.contain another_thing
         
         it 'should include anything owned, recursively, by those roots', ->
            [a_thing, another_thing] = [new Thing, new Thing]
            parent_thing = Thing.construct {something: a_thing, something_else: another_thing}
            root_thing = Thing.construct {child: parent_thing}
            expect(Unit.mask root_thing).to.contain parent_thing
            expect(Unit.mask root_thing).to.contain a_thing
            expect(Unit.mask root_thing).to.contain another_thing
         
         it 'should expose ephemeral methods on its resultant values', ->
            mask = Unit.mask new Thing
            expect(mask).to.have.property 'concat'
            expect(mask.concat)       .to.be.a 'function'
            expect(mask.conflictsWith).to.be.a 'function'
            expect(mask.contains)     .to.be.a 'function'
         
         describe '#concat', ->
            it 'should combine passed arguments into the mask', ->
               first_mask  = Unit.mask Thing.construct(things = {a: new Thing, b: new Thing})
               second_mask = Unit.mask Thing.construct(more_things = {m: new Thing, n: new Thing})
               third_mask  = Unit.mask Thing.construct(final_things = {x: new Thing, y: new Thing})
               
               first_mask.concat second_mask, third_mask
               _([things.a, things.b, more_things.m,
                 more_things.n, final_things.x, final_things.y]).forEach (thing)->
                  expect(first_mask).to.contain thing
               
         describe '#conflictsWith', ->
            it 'should return false when passed conflicting things', ->
               mask = Unit.mask Thing.construct(things = {a: new Thing, b: new Thing})
               expect(mask.conflictsWith Unit.mask things.a).to.be true
               expect(mask.conflictsWith Unit.mask new Thing).to.be false