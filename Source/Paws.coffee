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

# I'll give $US 5,000 to the person who fucking *fixes* how Node handles globals inside modules. ಠ_ಠ
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

   code.locals.inject Paws.primitives 'infrastructure'
   code.locals.inject Paws.primitives 'implementation'

   return code


# Reactor
# =======
# A `Reactor` is, data-wise, a bag of knowledge about `Execution`s that are pending resumption.
#
# This is stored in two ways:
#
#  - `Execution`s that are *not* blocked against new responsibility (i.e. that have all the
#    responsibility they need) are stored in the `queue`, and processed as is convenient (that is,
#    there are no guarantees about the ordering of those `Execution`s being evaluated in any
#    particular order.)
#  - ... while ones that *are* blocked (i.e. they're `adopt`'ing a subgraph, and at adopt-time it
#    conflicted with something) are known via `hints`: a list of references to `Thing`s against
#    which `Execution`s are known to be blocking, and which have recently *changed* in ownership.
#
# >  Note: Despite JavaScript being single-threaded (at least with regards to shared memory,
#    anyway); as a proof-of-concept, this implementation allows multiple `Reactor` instances to
#    exist simultaneously; and can be told to pseudo-randomize their ordering: this (badly)
#    simulates a parallel implementation using only *conccurency*; and it should help to surface
#    issues with the locking and concurrency model.
#
#
Paws.Reactor = Reactor = do ->
   _reactors = new Array
   _current  = null

   class Reactor extends EventEmitter

      constructor: constructify(return: this) (@queue...)->
         @hints = new Array
         _reactors.push this

      # This returns the current `Reactor` instance if called during (on-stack) a tick; otherwise,
      # `null`.
      @current: current = -> _current

      # This returns a `Reactor` instace against which you can `queue` and `signal`.
      #
      # It will,
      #
      # 1. Return the *currently-governing* `Reactor` instance, if the code-path invoking this
      #    function originated within a `Reactor`-tick;
      # 2. select an available¹ `Reactor`, if called from client code off-tick;
      # 3. or create a `Reactor` instance and return it, if none yet exist.
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
      @get: get = -> current() ? _.sample(_reactors) ? new Reactor

      #---
      # A private method to `::signal` an arbitrary `Reactor`. This is called by `Thing::_signal`;
      # and thus by several `Thing`-ownership-mutating methods.
      @_signal: signal = (thing)-> get().signal(thing)

      # DOCME
      signal: (thing)->
         @hints.push thing

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


# XXX: Loading order:
#      0. Paws.☕️
#      1. += utilities.☕️
#      2.    -> debugging.☕️ ...
#         += debugging.☕️      (-> utilities.☕️ )
#      3. += datagraph.☕️      (-> utilities.☕️ , debugging.☕️ )
#      4. += parser.☕️         (-> utilities.☕️ , debugging.☕️ )
#      6, += primitives/*

debugging.info "++ API available"
