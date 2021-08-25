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
      beforeEach ->
         Reactor._internals._reactors(_reactors = new Array)
         Reactor._internals._current(null)

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

         expect(a.reactor).to.have.property 'cache'
         expect(a.reactor.cache.operational).to.not.be.empty()
         expect(a.reactor.cache.operational).to.contain an.execution
         expect(a.reactor.cache.operational).to.contain another.execution

      describe '~ Instance management', ->
         it 'will retrieve a previously-created Reactor, if not on-stack with a current one', ->
            a Reactor; another Reactor

            expect(Reactor.get).to.be.ok()
            expect(rv = Reactor.get()).to.be.a Reactor
            expect(rv is a.reactor or rv is another.reactor).to.be.ok()

         it 'will preferentially return the *current* reactor, if on-stack', ->
            a Reactor; another Reactor

            reac = new Reactor
            Reactor._internals._current(reac)

            expect(Reactor.get()).to.be reac

         # FIXME: This could ... probably be tested better?
         it 'randomizes the returned reactor', ->
            sinon.spy util, 'sample'
            a Reactor; another Reactor

            expect(Reactor.get()).to.be.a Reactor
            expect(util.sample).was.calledOnce()

            util.sample.restore()

         it 'multiplexes notifications to Reactor instances', ->
            an Execution; a Reactor

            expect(Reactor._notify_some an.execution).to.be.ok()
            expect(a.reactor.cache.operational).to.contain an.execution

      describe '::next', ->
         # ...
