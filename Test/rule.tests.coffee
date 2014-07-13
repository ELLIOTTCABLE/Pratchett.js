`                                                                                                                 /*|*/ require = require('../Library/cov_require.js')(require)`
assert = require 'assert'
sinon  = require 'sinon'
expect = require('sinon-expect').enhance require('expect.js'), sinon, 'was'

Paws = require "../Source/Paws.coffee"
Paws.utilities.infect global, Paws

describe "Paws' Rulebook support:", ->
   Rule = require '../Source/rule.coffee'
   
   describe 'a Rule', ->
      the_env = undefined
      beforeEach ->
         the_env = {unit: new reactor.Unit, caller: new Execution}
      
      it 'should exist', ->
         expect(Rule).to.be.ok()
      it 'should construct', ->
         expect(-> new Rule the_env, 'a test', new Execution).not.to.throwException()
      
      it 'should clone the locals of the environment', ->
         a_thing = new Thing
         the_env.caller = new Execution
         the_env.caller.locals.inject Thing.construct {a_key: a_thing}
         the_body = new Execution
         
         rule = new Rule the_env, 'a test', the_body
         expect(the_body.locals.find('a_key')[0].valueish()).to.be a_thing
