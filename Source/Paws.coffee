# Hello! I am Paws! Come read about me, and find out how I work.
#
#                        ,d88b.d88b,
#                        88888888888
#                        `Y8888888Y'
#                          `Y888Y'
#                            `Y'

{ EventEmitter } = require 'events'

_         = require './utilities.coffee'
debugging = require './debugging.coffee'

{  constructify, parameterizable, delegated
,  passthrough, selfify, modifier
,  terminal: term                                                                              } = _

{  ENV, verbosity, is_silent, colour
,  emergency, alert, critical, error, warning, notice, info, debug, verbose, wtf       } = debugging

# Entry-point
# ===========
module.exports =
Paws         = require './datagraph.coffee'
Paws.parse   = require './parser.coffee'


# Miscellaneous
# =============
Paws.primitives = (bag)->
   require("./primitives/#{bag}.coffee")()

Paws.generateRoot = (code = '', name)->
   code = Paws.parse Paws.parse.prepare code if typeof code == 'string'
   code = new Paws.Execution code
   code.rename name if name
   debugging.info "~~ Root-execution generated for #{_.terminal.bold name}" if name

   code.locals.push Paws.primitives 'infrastructure'
   code.locals.push Paws.primitives 'implementation'

   return code


# Reactor
# =======
# This implementation of Paws stores all information about pending evaluation (and thus, information
# about ordering) *in* the data-graph. That is, there isn't an authoritative source, external to the
# object-system, dictating a giant list of ‘instructions to carry out.’ Instead, each `Execution` is
# aware of the (internally-strictly-ordered) `Operation`s pending against it; and meanwhile, each
# `Thing` is aware of any `Liability`s describing the (*externally*-strictly-ordered) `Execution`s
# pending against adoption of that particular `Thing`.
#
# The `Reactor`, however, is the place where that evaluation *actually happens*. So, to avoid each
# `Reactor` instance climbing The Entire Datagraph constantly, the methods that manage the above
# information `::signal` a `Reactor`, so that the `Reactor` can cache a list of “stuff that might
# need to be done”:
#
#  - Whenever a new operation is queued against an `Execution`, a `Reactor` is notified, so that it
#    can watch the `Execution` and eventually actually evaluate it. (The `operational` cache.)
#  - Meanwhile, when the ownership of the datagraph changes, affects which pending `Execution`s
#    might be evaluable; so with every such mutation, `Reactor` is notified that `Liability`s whose
#    subgraphs intersect the graph affected by the mutation need to be re-evaluated. (The
#    `responsibility` cache.)
#
# These two caches are stored separately; because the ‘blocking’ cache supersedes the ‘non-blocking’
# cache: that is, even if there's N pending `Execution`s with operations queued, when a `::signal`
# is received for a change in ownership or responsibility, then the possibly-affected blocked
# `Execution`s “jump the queue” to immediately be evaluated. (This is based on two theories: α, that
# the operation jumping the queue is an `'adopt'`, not an `'advance'`, and thus isn't likely to
# upset a pseudo-intuitive ordering; and β, that if we wait, a *new* interloper could snap up the
# responsibility that just became available ... clearly, something that had already been blocked
# against the ρ in question, should not be made to wait longer for the sake of something that spat
# out an `'adopt'` in the intervening time.)
#
# >  Note: Despite JavaScript being single-threaded (at least with regards to shared memory,
#    anyway); as a proof-of-concept, this implementation allows multiple `Reactor` instances to
#    exist simultaneously; and can be told to pseudo-randomize their ordering: this (badly)
#    simulates a parallel implementation using only *concurrency*; and it should help to surface
#    issues with the locking and concurrency model.
Paws.Reactor = Reactor = do ->
   _reactors = new Array
   _current  = null

   class Reactor extends EventEmitter

      constructor: constructify(return:@) (execs, resp)->
         @cache = new Object

         if execs? and not _.isArray execs
            @cache.operational    = Array::slice.call arguments
            @cache.responsibility = new Array
         else
            @cache.operational    = execs ? []
            @cache.responsibility = resp  ? []

         _reactors.push this

      # This returns the current `Reactor` instance if called during a tick (on-stack); otherwise,
      # `null`.
      @current: current = ->
         return _current

      # This returns a `Reactor` instance to which you can `signal` pending operations.
      #
      # It will,
      #
      # 1. Return the *currently-governing* `Reactor` instance, if the code-path invoking this
      #    function originated within a `Reactor`-tick;
      # 2. or select an available¹ `Reactor`, if called from client code off-tick.
      #
      # Throws a ReferenceError if no `Reactor`s exist.
      #
      # (This method is called as the default behaviour by various convenience methods within Paws
      # if a `Reactor`-argument is needed and omitted; so you'll rarely have to call it yourself,
      # unless you want to obtain a reference to a *single* `Reactor`, and then use it multiple
      # times, without creating a new one yourself.)
      #---
      # TODO: Implement a flag to disable pseudo-random select, and make this implementation
      #       strictly-ordered (with, of course, appropriate warnings about that not being a
      #       specified feature, or any guarantees about the reproducibility of that ordering across
      #       versions ...)
      # TODO: Needs a better error-type than ReferenceError
      @get: get = -> current() ? _.sample(_reactors)

      #---
      # A private method to `::notify` an arbitrary `Reactor`. This is called by `Thing::_signal`;
      # and thus by several `Thing`-ownership-mutating methods.
      @_notify_some: (it, type)->
         some_reactor = get()

         if some_reactor?
            some_reactor.notify(it, type)
         else
            warning "!! Operations were queued on an Execution, but no Reactor was available to notify."

      # DOCME
      notify: (it, type = 'operational')->
         @cache[type].push it

      # This finds the next `Execution` to be evaluated by `::tick`.
      #
      # If any `Thing`s have `::signal`ed the receiver, then those are checked first (that is, any
      # `Thing.supplicants` are checked for `Thing::available_to` in the order they originally
      # attempted adoption). If there's nothing in the responsibility-cache to indicate possible
      # `supplicant` fulfilment, or if everything therein proves to still be unavailable for the
      # `Liability` they're blocked against, then the next `Execution` is pulled out of the
      # operational-queue instead.
      next: ->
         # XXX: UGHHGHGHHH SO SLOWWWW this is TERRIBLEEEE; we're at ... what, O(𝑛⁴)? maybe? -_-
         queue_jumper = _.find @cache.responsibility, (exe)->
            _.find exe.blockers, (li)->
               li.available()

         queue_jumper or @cache.operational.unshift()

     #upcoming: ->
     #   results = _.filter @queue, (staging)=> @table.allowsStagingOf staging
     #   return if results.length then results else undefined

      # DOCME
      tick: ->
         prev_reactor = _current
         _current = this

         unless exec = @next()
            @awaitingTicks = 0
            return no

         op = exec.ops[0]

         if op.perform(exec)
            exec.ops.unshift()

         _current = prev_reactor


   if debugging.testing()
      Reactor._internals =
         _reactors: (value)-> if typeof value is 'undefined' then _reactors else _reactors = value
         _current:  (value)-> if typeof value is 'undefined' then _current  else _current  = value

   Reactor


# Additional exports
# ==================
Paws.start =
Paws.js = (code)->
   root = Paws.generateRoot code

   here = new Paws.reactor.Unit
   here.stage root

   here.start()

Paws.infect = (target)-> @utilities.extend (target ? global), this


# Initialization
# ==============
Paws.Thing._init()
Paws.Execution._init()


# XXX: Loading order:
#      0. Paws.☕️
#      1. += utilities.☕️
#      2.    -> debugging.☕️ ...
#         += debugging.☕️      (-> utilities.☕️ )
#      3. += datagraph.☕️      (-> utilities.☕️ , debugging.☕️ )
#      4. += parser.☕️         (-> utilities.☕️ , debugging.☕️ )
#      6, += primitives/*

debugging.info "++ API available"
