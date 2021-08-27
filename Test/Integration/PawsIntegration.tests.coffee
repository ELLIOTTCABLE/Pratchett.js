support = require '../support.coffee'
util    = require '../../Source/utilities.coffee'

assert  = require 'assert'
sinon   = require 'sinon'
expect  = require('sinon-expect').enhance require('expect.js'), sinon, 'was'
match   = sinon.match

describe "Language integration tests:", ->
   Paws = require "../../Source/Paws.coffee"

   {  Reactor, parse
   ,  Thing, Label, Execution, Native
   ,  Relation, Liability, Combination, Position, Mask, Operation }                           = Paws

   {  Context, Sequence, Expression }                                                        = parse


   describe 'Reactor', ->
      # originalReactors = new Array
      # before     -> originalReactors = Reactor._internals._reactors()
      # after      -> Reactor._internals._reactors(originalReactors)
      #
      # _reactors = undefined
      # beforeEach ->
      #    Reactor._internals._reactors(_reactors = new Array)
      #    Reactor._internals._current(null)

      it 'should provide an "infrastructure" value to root-Executions', ->
         root = Paws.generateRoot "infrastructure void[]"

         results = root.locals.find('infrastructure')

         expect(results).to.be.an Array
         expect(results).to.have.length 1

         infra_pair = results[0]

         expect(infra_pair).to.be.a Thing
         expect(infra_pair.isPair()).to.be true

         infra = infra_pair.valueish()

         expect(infra).to.be.a Thing
         expect(infra.metadata.length).to.be > 20
