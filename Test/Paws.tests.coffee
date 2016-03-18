support = require './support.coffee'
util    = require '../Source/utilities.coffee'

assert  = require 'assert'
sinon   = require 'sinon'
expect  = require('sinon-expect').enhance require('expect.js'), sinon, 'was'
match   = sinon.match

describe "Paws' reactor:", ->
   Paws = require "../Source/Paws.coffee"

   {  Reactor, parse
   ,  Thing, Label, Execution, Native
   ,  Relation, Liability, Combination, Position, Mask, Operation }                           = Paws

   {  Context, Sequence, Expression }                                                        = parse


   describe 'Reactor', -> # ---- ---- ---- ---- ----                                         Reactor
      originalReactors = new Array
      before     -> originalReactors = Reactor._internals._reactors()
      after      -> Reactor._internals._reactors(originalReactors)

      _reactors = undefined
      beforeEach -> Reactor._internals._reactors(_reactors = new Array)
      beforeEach -> Reactor._internals._current(null)

      it 'exists', ->
         expect(Reactor).to.be.ok()
         expect(Reactor).to.be.a 'function'

      it 'constructs', ->
         expect(-> new Reactor).not.to.throwError()
         expect(new Reactor).to.be.a Reactor

      it 'constructs without `new`', ->
         expect(-> Reactor()).not.to.throwError()
         expect(Reactor()).to.be.a Reactor

      it 'adds constructed instances to a global set', ->
         a Reactor

         expect(_reactors).to.contain a.reactor

      it 'accepts a set of Executions to immeduately queue at construct-time', ->
         a Reactor, (an Execution), (another Execution)

         expect(a.reactor).to.have.property 'queue'
         expect(a.reactor.queue).to.not.be.empty()
         expect(a.reactor.queue).to.contain an.execution
         expect(a.reactor.queue).to.contain another.execution

      describe '~ Instance management', ->
         it 'can retrieve the current Reactor', ->
            Reactor._internals._current(a Reactor)

            expect(Reactor.get).to.be.ok()
            expect(Reactor.get()).to.be a.reactor

         it 'can construct a new Reactor', ->
            expect(Reactor.get()).to.be.a Reactor
            expect(_reactors).to.not.be.empty()

         it 'will retrieve a previously-created Reactor', ->
            a Reactor; another Reactor

            expect(rv = Reactor.get()).to.be.a Reactor
            expect(rv is a.reactor or rv is another.reactor).to.be.ok()

         it 'randomizes the returned reactor', ->
            sinon.spy util, 'sample'
            a Reactor; another Reactor

            expect(Reactor.get()).to.be.a Reactor
            expect(util.sample).was.calledOnce()

            util.sample.restore()

         it 'multiplexes signals to Reactor instances', ->
            a Thing; a Reactor

            expect(Reactor._signal a.thing).to.be.ok()
            expect(a.reactor.hints).to.contain a.thing
