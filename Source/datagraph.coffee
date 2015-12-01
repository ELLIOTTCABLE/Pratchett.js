uuid             = require 'node-uuid'
{ EventEmitter } = require 'events'

_                = require './utilities.coffee'
debugging        = require './debugging.coffee'

# I'll give $US 5,000 to the person who fucking *fixes* how Node handles globals inside modules. ಠ_ಠ
{  constructify, parameterizable, delegated
,  passthrough, selfify, modifier
,  terminal: term                                                                              } = _

{  ENV, verbosity, is_silent, colour
,  emergency, alert, critical, error, warning, notice, info, debug, verbose, wtf       } = debugging


# API entry-point
# ===============
module.exports =
Paws =
   utilities: _
   debugging: debugging

Paws.debugging.infect Paws


# Core data-types
# ===============
# The Paws object-space implements a single graph (in the computer-science sense) of homogenous(!)
# objects. Each object, or node in that graph, is called a `Thing`; and is singly-linked to an
# ordered list of other nodes.
#
# The first member of the metadata on a `Thing` (referred to as the ‘noughtie’) is generally
# reserved for special use from within Paws; and thus Paws' lists are effectively one-indexed.
#
#  > In addition to these links to other nodes that *every* `Thing` has, some `Thing`s carry around
#    additional information; these are implemented as additional JavaScript types, such as `Label`
#    (which carries around identity, and a description in the form of a Unicode string) or
#    `Execution` (which encapsulates procedure and execution-status information.)
#
#    The Paws model is to consider that underlying information as ‘data’ (the actual *concerns* of a
#    Paws program), and the links *between* those data as ‘metadata’; describing **the relationships
#    amongst** the actual data.
#
# Although objects appear from within Paws to be ordered lists of other objects; they are often
# *treated* as ersatz key-value-dictionaries. To this purpose, a single key-value ‘pair’ is
# often represented as a list-`Thing` containing only a key `Label`, and the associated value.
#
# Each (type of) object also has a `receiver` associated with it, involved in the evaluation
# process; an `Execution` for a procedure that receives messages ‘sent’ to the object in question.
# This defines the (default) action taken when the object is, for example, the subject on the left-
# hand-side of a simple expression.
#
# The default receiver for a flavour of object depends on the additional data it carries around
# (that is, the JavaScript type of the node). For instance, the default receiver for plain `Thing`s
# (those carrying no additional data around) is an equivalent to the `::find()` operation; that is,
# to treat the subject-object as a dictionary, and the message-object as a key to search that
# dictionary for. The default for any object, however, can be overridden per-object, changing how a
# given node in the graph responds to `Combination`s with other objects. (See the documentation for
# `Execution` for more exposition on the evaluation model.)
#
# ---- ---- ----
#
# The links from one `Thing` to another are encoded as `Relation` objects, which are further
# annotated with the property of **‘ownership’**: an object that ‘owns’ an object below it in the
# graph is claiming that object as a component of the *overall data-structure* that the parent
# object represents. (Put simply: a series of ownership-annotated links in the datagraph describe a
# single data-structure as a subgraph thereof.)
#
# These `Relation`s are stored in an ordered `Array`; manipulable via `::set()`, `::push()`,
# `::pop()`, `::shift()`, and `::unshift()`. When structured as a dictionary (a list of key-value
# ‘pairs’, usually created with `::define()`), the values are searchable by `::find()`; and the
# apparent key / value of a pair are exposed by `::keyish()` and `::valueish()`.
Paws.Thing = Thing = parameterizable class Thing extends EventEmitter
   constructor: constructify(return:@) (elements...)->
      @id = uuid.v4()
      @metadata = new Array
      @push elements... if elements.length

      @metadata.unshift undefined if @_?.noughtify != no

   rename: selfify (name)-> @name = name

   at:         (idx)->     @metadata[idx]?.to
   set:        (idx, to)-> @metadata[idx] = new Relation this, to

   own_at:     (idx)->     @metadata[idx] = @metadata[idx].as_owned()
   disown_at:  (idx)->     @metadata[idx] = @metadata[idx].as_contained()

   inject: (things...)->
      @push ( _.flatten _.map things, (thing)-> thing.toArray() )...

   push: (elements...)->
      relations = elements.map (it)=>
         if it instanceof Relation
            rel = it.clone()
            rel.from = this

         if it instanceof Thing
            rel = new Relation this, it

         rel.owns = @_?.own if @_?.own?
         return rel

      @metadata = @metadata.concat relations

   pop: ->
      @metadata.pop()
   shift: ->
      noughty = @metadata.shift()
      result = @metadata.shift()
      @metadata.unshift noughty
      result
   unshift: (other)->
      # TODO: include-noughtie optional
      noughty = @metadata.shift()
      @metadata.unshift other
      @metadata.unshift noughty

   compare: (to)-> to == this

   # Creates a copy of the `Thing` it is called on. Alternatively, can be given an extant `Thing`
   # copy this `Thing` *to*, over-writing that `Thing`'s metadata. In the process, the
   # `Relation`s within this relation are themselves cloned, so that changes to the new clone's
   # ownership don't affect the original.
   clone: (to)->
      to ?= new Thing.with(noughtify: no)()
      to.name = @name unless to.name?

      to.metadata = @metadata.map (rel)->
         rel = rel?.clone()
         rel?.from = to
         rel

      return to

   # This implements the core algorithm of the default jux-receiver; this algorithm is very
   # crucial to Paws' object system:
   #
   # Working through the metadata in reverse, select those items whose *first* (not the noughty; but
   # subscript-one) item `compare()`s truthfully to the searched-for key. Return them in the order
   # found (thus, “in reverse”), such that the latter-most item in the metadata that was found to
   # match is returned as the first match. For libside purposes, only this (the very latter-most
   # matching item) is used.
   #
   # Of note, in this implementation, we additionally test *if the matching item is a pair*. For
   # most *intended* purposes, this should work fine; but it departs slightly from the spec.
   # We'll see if we keep it that way.
   #---
   # TODO: `pair` option, can be disabled to return the 'valueish' things, instead of the pairs
   # TODO: `raw` option, to return the `Relation`s, instead of the wrapped `Thing`s
   find: (key)->
      key = new Label(key) unless key instanceof Thing
      results = @metadata.filter (rel)->
         rel?.to?.isPair?() and key.compare rel.to.at 1
      _.pluck(results.reverse(), 'to')

   # TODO: Option to include the noughty
   toArray: (cb)-> @metadata.slice(1).map (rel)-> (cb ? _.identity) rel?.to

   # Convenience method to create a ‘pair-ish’ `Thing` (one with only two members, the first of
   # which is a string-ish ‘key.’)
   @pair: (key, value, own)->
      it = new Thing
      it.push Label(key).owned_by it
      it.push value.contained_by(it, own) if value
      return it

   # A further convenience to add a new pair to the end of a ‘dictionary-ish’ `Thing`.
   #
   # The pair-object itself is always owned by the receiver `Thing`; but the third `own` argument
   # specifies whether the *`value`* is to be further owned by the dictionary-structure as well.
   define: (key, value, own)->
      pair = Thing.pair key, value, own
      @push pair.owned_by this

   # FIXME: This is ... not precise. /=
   isPair:   -> @metadata[1] and @metadata[2]
   keyish:   -> @at 1
   valueish: -> @at 2

   # Convenience methods to create `Relation`s *to* the receiver.
   contained_by: (other, own)-> new Relation other, this, own # Defaults to `no`
   owned_by:     (other)->      new Relation other, this, yes

# Constructs a generic ‘key/value’ style `Thing` from a `representation` (a JavaScript `Object`-
# hash) thereof. This convenience method expects arguments constructed as pairs of 1. any string (as
# the key, which will be converted into the `Label`), and 2. a Paws `Thing`-subclass (as the value.)
# These may be nested.
#
#  > For instance, given `{foo: thing_A, bar: thing_B}`, `construct()` will product a `Thing`
#    resembling the following (disregarding noughties):
#
#        ((‘foo’, thing_B), (‘bar’, thing_B))
#
# The ‘pair-ish’ values are always owned by their container; as are, by default, the ‘leaf’ objects
# passed in. (The latter is a behaviour configurable by `.with(own: no)`.)
#
# @option own: Construct the structure as as `own`ing newly-created sub-Things
# @option names: `rename` the constructed `Thing`s according to the key they're being assigned to
Thing.construct = (representation)->
   pairs = for key, value of representation

      if _.isFunction value
         value = Native.synchronous value

      else unless value instanceof Thing or value instanceof Relation
         value = @construct value

      leave_ownership_alone = value instanceof Relation
      should_own = @_?.own ? (if leave_ownership_alone then undefined else yes)

      rel.to.rename key if @_?.names
      Thing.pair key, value, should_own

   return Thing.with(own: yes) pairs...

Thing.init_receiver = ->
   # The default receiver for `Thing`s simply preforms a ‘lookup.’
   Thing::receiver = new Native (params)->
      caller  = params.at 0
      subject = params.at 1
      message = params.at 2

      results = subject.find message

      if results[0]
         caller.respond results[0].valueish()

      # FIXME: Welp, this is horrible error-handling. "Print a warning and freeze forevah!!!"
      else
         notice "~~ No results on #{Paws.inspect subject} for #{Paws.inspect message}."

   .rename 'thing✕'


# A `Label` is a type of `Thing` which encapsulates a static Unicode string, serving two purposes:
#
# 1. Unique-comparison: Two `Label`s originally created with equivalent sequences of Unicode
#    codepoints will `compare()` as equal. That is, across codebases, `Label`s share identity, even
#    when they don't share objective content / metadata relationships.
# 2. Description: Although not designed to be used to manipulate character-data as a general
#    string-type, `Label`s can be used to associate an arbitrary Unicode sequence with some other
#    data, as a name or description. (Hence, ‘label.’)
#
# ---- ---- ----
#
# Due to their intented use as descriptions and comparators, the string-data associated with a
# `Label` cannot be mutated after creation; and they cannot be combined or otherwise manipulated.
# However, they *can* be `explode()`d into an ordered-list of individual codepoints, each
# represented as a new `Label`; and then manipulated in that form. These poor-man's mutable-strings
# (colloquially called ‘character soups’) are provided as a primitive form of string-manipulation.
Paws.Label = Label = class Label extends Thing
   constructor: constructify(return:@) (@alien)->
      if @alien instanceof Label
         @alien.clone this

   clone: (to)->
      super (to ?= new Label)
      to.alien = @alien
      return to

   compare: (to)->
      to instanceof Label and
      to.alien == @alien

   # FIXME: JavaScript's `split()` doesn't handle wide-character (surrogate in UTF-16, or 4-byte in
   #        UTF-8) Unicode -very-well.- (at all!)
   explode: ->
      it = new Thing
      it.push.apply it, _.map @alien.split(''), (char)-> new Label char
      it


# *Programs* in Paws are a series of nested sequences-of-Paws-objects. For programs that originate
# as text (not all Paws programs do!), those `Thing`s are created at parse-time; Paws doesn't
# operate on text (or an intermediat representation thereof) in the way that many programming-
# languages do.
#
# The primary way you interact with code in Paws, is this, the `Execution`. An `Execution`, however,
# doesn't represent a simple invocable procedure, the way a `Function` might in JavaScript; instead,
# it represents the *partial completion thereof*. When you invoke a Paws `Execution`, you're not
# spawning a wholesale evaluation of that procedure, but rather *continuing* a previous evaluation.
#
# Each time you invoke an `Execution`, the script is advanced a single step to produce a new
# computational task, in the form of a ‘combination:’ a subject-object, and a message-object to be
# sent to it. The `receiver` (another `Execution`, see the above `Thing` documentation) of the
# *subject* will then be invoked in turn, and handed the message-object. (This means that each
# intentional step in a Paws program necessarily involves at *least* two effective steps; the
# invocation of the `Execution` intended, and then the invocation of the resulting subject's
# `receiver`.)
#
# Obviously, however, as Paws is an asynchronous language, *any amount* of actual work can happen
# following an instigator's invocation of an `Execution`; for instance, although the default-
# receivers are all implemented as `Native`s, completable in a single invocation as an atomic
# operation ... a custom receiver could preform any amount of work, before producing a result-value
# for the combination that caused it.
#
# Further, a crucial aspect of Paws is the ability to *branch* `Execution`-flow. This is acheived by
# `clone()`ing a partially-evaluated `Execution`. As the original procedure progresses, its
# instructions are gradually processed and discarded; meanwhile, however, an earlier clone's will
# *not* be. When so-branched, an `Execution`'s state is all duplicated to the clone, unaffected by
# changes to the original `Execution`'s position or objective-context.
#
# **Nota bene:** While clones do not share *additions* to their respective context, `locals`, the
#                clone made is *shallow in nature*. This means that the two `Execution`s' `locals`
#                objects share the original assignments (that is, the original pairs) created prior
#                to the cloning. This further means that either clone can modify an existing
#                assignment instead of appending an overriding pair, thus making the change visible
#                to prior clones, if desired.
#
# ---- ---- ----
#
# This implementation stores the `Execution` information as three crucial elements:
#
# 1. A stack of positions in a `Script`, as `Position`s in the `instructions` array,
# 2. a further stack of the `results` of outer `instruction`s,
# 3. and its objective evaluation context, a `Thing` accessible as `locals`.
#
# The position is primarily maintained by `::advance()`; diving into and climbing back out of sub-
# expressions to produce `Combination`s for the reactor. As it digs into a sub-expression, the
# position in the outer `Expression` is maintained in the `instructions` stack; while the results of
# the last `Combination` for each outer expression are correspondingly stored in `results`.
#
# **Nota anche: The `instructions` stack lists *completed* nodes; ones for which a `Combination` has
#               already been generated.)**
Paws.Execution = Execution = class Execution extends Thing
   constructor: constructify (@begin)->
      if typeof @begin == 'function' then return Native.apply this, arguments

      @begin = new Position @begin if @begin? and not (@begin instanceof Position)

      if @begin
         @results      = [ null   ]
         @instructions = [ @begin ]
      else
         @results      = [        ]
         @instructions = [        ]

      @pristine = yes
      @locals = new Thing().rename 'locals'
      @locals.define 'locals', @locals, no
      this   .define 'locals', @locals, yes

      @ops = new Array

      # If this belongs to a `LiabilityFamily` (i.e. is participating with other 'read'-access
      # `Execution`s, it will be linked here by `LiabilityFamily#add()`.
      #---
      # WAT: This makes no sense, because an Execution can hold Liabilities for multiple nodes in
      # a subgraph, each separately, and thus belong-by-extension to multiple LiabilityFamilies ...
     #@associates = undefined

      return this

   # Creates a list-thing of the form that receiver `Execution`s expect.
   @create_params: (caller, subject, message)-> new Thing.with(noughtify: no)(arguments...)


   # Pushes a new `Operation` onto this `Execution`'s `ops`-queue.
   queue: (something)->
      return @queue new Operation arguments...  unless something.op?

      @ops.push something

   # A convenience method for pushing an 'advance' `Operation`, specifically.
   respond: (response)->
      @queue new Operation 'advance', arguments...


   complete:-> !this.instructions.length

   # Returns the *current* `Position`; i.e. the top element of the `instructions` stack.
   current:-> @instructions[0]

   # This method of the `Execution` types will copy all data relevant to advancement of the
   # execution to a `Execution` instance. This includes the pristine-ness (boolean), the `results`
   # and `instructions` stacks (or for a `Native`, any `bits`.) A clone made thus can be advanced
   # just as the original would have been, without affecting the original's position.
   #
   # Of note: along with all the other data copied from the old instance, the new clone will inherit
   # the original `locals`. This is intentional.
   #---
   # TODO: nuke-API equivalent of lib-API's `branch()()`
   clone: (to)->
      super (to ?= new Execution)
      to.pristine    = @pristine

      # FIXME: Remove old 'locals' from the Exec's cloned metadata?
      to.locals      = @locals.clone().rename 'locals'
      to.define        'locals', to.locals, yes

      to.advancements = @advancements if @advancements?

      if @instructions? and @results?
         to.instructions = @instructions.slice 0
         to.results      = @results.slice 0

      return to

   # This informs an `Execution` of the ‘result’ of the last `Combination` returned from `next`.
   # This value is stored in the `results` stack, and is later used as one of the values in furhter
   # `Combination`s.
   register_response: (response)-> @results[0] = response

   # Returns the next `Combination` that needs to be preformed for the advancement of this
   # `Execution`. This is a mutating call, and each time it is called, it will produce a new
   # (subsequent) `Combination` for this `Execution`.
   #
   # It usually only makes sense for this to be called after a response to the *previous*
   # combination has been signaled by `register_response` (obviously unless this is the first time
   # it's being advanced.) This also accepts an optional argument, the passing of which is identical
   # to calling `register_response` with that value before-hand.
   #
   # For combinations involving the start of a new expression, `null` will be returned as one part
   # of the `Combination`; this indicates no meaningful data from the stack for that node. (The
   # reactor will interpret this as an instruction to insert this `Execution`'s `locals` into that
   # combo, instead.)
   advance: (response)->
      return undefined if @complete()

      @register_response response if response?

      # If we're continuing to advance a partially-completed `Execution`, ...
      completed = @instructions[0]
      previous_response = @results[0]
      if not @pristine

         # Gets the next instruction from the current sequence (via `Position#next`)
         @instructions[0] =
         upcoming = completed.next()

         # If we've completed the current sub-expression (a sequence.), then we're going to step out
         # (pop the stack.) and preform the indirected combination.
         if not upcoming?
            outer_current_value = @results[1]
            @instructions.shift(); @results.shift()
            return new Combination outer_current_value, previous_response

         # Discards the last response at the current stack-level, if this is the beginning of a new
         # semicolon-delimited expression.
         if upcoming.index is 0
            @results[0] =
            previous_response = null

         it = upcoming.valueOf()

         # If the current node is a `Thing`, we combine it against the top of the `results`-stack
         # (either another Thing, or `null` if this is the start of an expression.)
         if it instanceof Thing
            upcoming_value = it
            return new Combination previous_response, upcoming_value

         # If it's not a `Thing`, it must be a sub-expression (that is, a `parse.Sequence`).
         else
            upcoming = new Position it

            # If we've got what appears to be an empty sub-expression, then we're dealing with the
            # special-case syntax for referencing the Paws equivalent of `this`. We treat this like
            # a simple embedded-`Thing` combination, except with the current `Execution` as the
            # `Thing` in question:
            if not upcoming.valueOf()?
               return new Combination previous_response, this

            # Else, the ‘upcoming’ node is a real sub-expression, and we're going to ‘dive’ into it
            # (push it onto the stack.)
            @instructions.unshift upcoming; @results.unshift null

      # At this point, we're left at the *beginning* of a new expression. Either we'll be looking at
      # a `Thing`, or a nested series of ‘immediate’ (i.e. `[[[foo ...`) sub-expressions, eventually
      # ending in a `Thing` (since truly empty sub-expressions are impossible.)
      @pristine = no

      # If we *are* looking at another (or an arbitrary number of further) immediate
      # sub-expression(s), we need to push it (all of them) onto the stack.
      while (it = @instructions[0].valueOf())? and it.expressions?
         @instructions.unshift new Position it; @results.unshift null

      upcoming = @instructions[0]

      # (another opportunity for an empty sub-expression / self-reference)
      if not upcoming.valueOf()?
         return new Combination previous_response, this

      # At this point, through one of several paths above, we've definitely descended into a (or
      # several) sub-expression(s), and are definitely looking at the first `Thing` in a new
      # expression.
      upcoming_value = upcoming.valueOf()
      return new Combination null, upcoming_value


# Correspondingly to normal `Execution`s, some procedures are provided by the implementation (or
# those extending Paws with the API, such as yourself) as `Native`s. These consist of chunks of
# JavaScript code to be executed each time the faux-`Execution` is invoked.
#
# To imitate the behaviour of a natural `Execution`, `Native` procedures are advanced destructively
# each time they are invoked: a chunk of behaviour is discarded. Similarly, each of these `bits` of
# behaviour can be separately argumented with ‘results’ when invoked (again, just as a regular
# `Execution` must be parameterized on each reinvocation.) This can best be visualized as an
# explicit coroutine, with each `yield` being represented by the end of one `Function` and beginning
# of the next.
#
# To further imitate the cloning-behaviour of `Execution`s, we shallow-clone any JavaScript members
# added by the `Native`'s `bits` during their evaluation to clones of the `Native` itself.
#
# *Note:* All of the `Native`s provided by this implementation are stored in a separate project,
#         `primitives`. See `primitives/infrastructure.coffee` for the majority thereof.
#
# ---- ---- ----
#
# We implement `Native`s as an array of `bits`; `Function`s that receive the Paws resumption-value
# as their sole argument. Instead of storing information on the objecive `locals`, `Native`s'
# implementations have the option of storing partial progress on the `Native` instance itself; to
# this end, `this` within the body of a `Function`-bit will be the `Native` instance being invoked.
# (Note that although the *enumerable properties* will be copied from the `Native` to a clone
# thereof, the *object-identity* will obviously have changed.)
#
# Of great use, we also provide the `.synchronous()` convenience function; although most `Native`s
# imitate fully-asynchronous, coroutine-style procedures, this function can be used to construct
# faux-synchronous-style procedures that consume all of their parameters before evaluating and
# producing a result. (This expidently allows `Native` procedures to be written as single,
# synchronous `Function`s, that accept multiple arguments and `return` a single result.)
Paws.Native = Native = class Native extends Execution
   constructor: constructify(return:@) (@bits...)->
      delete @begin
      delete @instructions
      delete @results

      @advancements = @bits.length

   complete:-> not @bits.length

   current:-> @bits[0]

   clone: (to)->
      super (to ?= new Native)
      _.map Object.getOwnPropertyNames(this), (key)=>
         to[key] = this[key] unless to[key]?

      to.bits = @bits.slice 0

      return to

   # `advancing` to the next unit of work for a `Native` is substantially simpler than doing so for
   # a normal `Execution`: we simply remove (and return) another body-section from `bits`.
   advance: (response)->
      return undefined if @complete()

      @pristine = no
      return @bits.shift()


# This alternative constructor will automatically generate a series of ‘bits’ that will curry the
# appropriate number of arguments into a single, final function.
#
# Instead of having to write individual function-bits for your `Native` that collect the appropriate
# set of resumption-values into a series of “arguments” that you need for your task, you can use
# this convenience constructor for the common situation that you're treating an `Execution` as
# equivalent to a synchronous JavaScript function.
#
# ----
#
# This takes a single function, and checks the number of arguments it requires before generating the
# corresponding bits to acquire those arguments.
#
# Then, once the resultant `Native` has been resumed the appropriate number of times (plus one extra
# initial resumption with a `caller` as the value, as is standard coproductive practice in Paws),
# the synchronous JavaScript passed in as the argument here will be invoked.
#
# That invocation will provide the arguments recorded in the function's implementation, as well as a
# context-object containing the following information available on `this`:
#
# caller
#  : The first resumption-value provided to the generated `Native`. Usually, itself, an `Execution`,
#    in the coproductive pattern.
# execution
#  : The original `this`. That is, the generated `Native` that was constructed from the function.
#
# After your function executes, if it results in a non-null return value, then the `caller` provided
# as the first response Paws-side will be resumed one final time with that as the corresponding
# response. (Hence the name of this method: it provides a ‘synchronous’ (ish) result after all the
# parameters have been asynchronously collected.)
#
# @param { function(... [Thing], this:{caller: Execution, this}): ?Thing }
#    synch_body   The synchronous function we'll generate an Execution to match
Native.synchronous = (synch_body) ->
   advancements = synch_body.length + 1

   # First, we construct the *middle* bits of the coproductive pattern (that is, the ones that
   # handle all but the *last* actual argument the passed function requires.) These are pretty
   # generic: they simply partially-apply their RV to the *last* bit (which will be defined
   # below.) Thus, they participate in currying their argument into the final invocation of
   # the synchronous function.
   bits = new Array(advancements - 1).join().split(',').map ->
      (caller, value)->
         # FIXME: Pretty this up with prototype extensions. (#last, anybody?)
         @bits[@bits.length - 1] = _.partial @bits[@bits.length - 1], value
         caller.respond this

   # Next, we construct the *first* bit, which is a special case responsible for receiving the
   # `caller` (as is usually the case in the coproductive pattern.) It takes its resumption-
   # value, and curries it into *every* following bit. (Notice that both the middle bits, above,
   # and the concluding bit, below, save a spot for a `caller` argument.)
   bits[0] = (caller)->
      @bits = @bits.map (bit)=> _.partial bit, caller
      caller.respond this

   # Now, the complex part. The *final* bit has quite a few arguments curried into it:
   #
   #  - Immediately (at generate-time), the locals we'll need within the body: the `Paws` API,
   #    and the `synch_body` we were passed. This is necessary, because we're building the body
   #    in a new JavaScript environment, due to the `eval`-y `Function` constructor;
   #  - Second (later on, throughout invocation-time), the `caller` curried in by the first bit;
   #  - Third, any *actual arguments* curried in by intermediate bits.
   #
   # In addition to these, it's got one final argument (the actual resumption-value with which
   # this final bit is invoked, after all the other bits have been exhausted).
   #
   # These values are curred into a function we construct within the body-string below, that
   # proceeds to provide the *actual* arguments to the synchronous `func`, as well as
   # constructing a context-object to act as the `this` described above.
   #---
   # FIXME: Remove the `Paws` pass, if it's unnecessary
   arg_names = ['synch_body', 'caller'].concat Array(advancements).join('_').split('')

   last_bit = """
      var that = { caller: caller, execution: this }
      var result = synch_body.apply(that, [].slice.call(arguments, 2))
      if (typeof result !== 'undefined' && result !== null) {
         caller.respond(result) }
   """

   bits[advancements - 1] = _.partial Function(arg_names..., last_bit), synch_body


   it = new Native bits...
   it.synchronous = synch_body

   return it

Execution.init_receiver = ->
   # The `Execution` default-receiver is specified to preform a ‘call-pattern’ invocation: cloning
   # the subject-`Execution`, resuming that clone, and explicitly *not* resuming the caller.
   Execution::receiver = new Native (params)->
      subject = params.at 1
      message = params.at 2

      subject.clone().respond message
   .rename 'execution✕'


# Supporting types
# ================
Paws.Relation = Relation = parameterizable delegated('to', Thing) class Relation

   constructor: constructify(return:@) (from, to, owns)->
      if from instanceof Relation
         from.clone this
      else
         @from = from
         @to   = to
         @owns = false

      @owns    = owns if owns?

   # Copy the receiver `Relation` to a new `Relation` instance. (Can also overwrite the contents of
   # an existing `Relation`, if passed, with this receiver's state.)
   #---
   # FIXME: Make truly immutable (i.e. refuse to modify once this Relation has been used in a Thing)
   clone: (other)->
      other ?= new Relation
      other.from = @from
      other.to   = @to
      other.owns = @owns

      return other

   as_contained: (own)->
      it = @clone()
      it.owns = own ? no
      return it
   as_owned: ->
      it = @clone()
      it.owns = yes
      return it

   # Provided for API-parity with `Thing`
   contained_by: (other, own)-> new Relation other, @to, own ? @owns
   owned_by:     (other)->      new Relation other, @to, yes


# This is a an intersection-type representing the ‘responsibility’ mapping between an object, and
# the `Execution` responsible for it. It encapsulates:
#
#  - the `ward` `Thing` that the responsibility is for,
#  - the `custodian` `Execution` currently responsible for it,
#  - and the `license`ing-status of that `Execution` (`true` for 'write'-exclusivity, `false` for
#    'read'-only.)
Paws.Liability = Liability = delegated('for', Thing) class Liability
   constructor: constructify(return:@) (@custodian, @ward, license = 'read')->
      @_write = license is yes or license is 'write'

   write: ->     @_write
   read:  -> not @_write

   # This simply determines if two `Liability`s are precisely identical.
   compare: (other)->
      return true if this is other

      other._write      is @_write     &&
      other.custodian   is @custodian  &&
      other.ward        is @ward

Paws.Liability.Family = LiabilityFamily = delegated('custodians', Array) class LiabilityFamily
   constructor: constructify(return:@) (first)->
      @_write = first._write

      @members = new Array
      @add first, yes

   write: ->     @_write
   read:  -> not @_write

   add: (it, first = false)->
      if not first
         return false if @_write
         return false if it._write
         return false if @includes it

      @members.push it
     #it.custodian.associates = this

   remove: (it)->
      _(@members)
         .remove( (member)-> member.compare it ) # FIXME: Wasteful.
      #  .forEach (member)-> member.custodian.associates = undefined
         .commit()

   includes: (it)-> _(@members).any (member)-> member.compare it


# A `Combination` represents a single operation in the Paws semantic. An instance of this class
# contains the information necessary to process a pending combo (as returned by
# `Execution#next`).
Paws.Combination = Combination = class Combination
   constructor: constructify (@subject, @message)->

# A `Position` records the last element of a given expression from which a `Combination` was
# generated. It also contains the information necessary to find the *next* element of that
# expression's sequence (i.e. the indices of both the element within the expression, and the
# expression within the sequence.)
#
# This class is considered immutable.
#---
# FIXME: Factor out the Script-types (Expression/Sequence) from the parser, so I can include them
# verbatim into both parser.coffee and datagraph.coffee
Paws.Position = Position = class Position
   constructor: constructify(return:@) (@_sequence, @expression_index = 0, @index = 0)->
      unless @_sequence?.expressions? # ... passed an Expression, not a Sequence
         @_sequence = expressions: [@_sequence] # Construct a faux-Sequence
         [@index, @expression_index] = [@expression_index, 0]

      # FIXME: argument validation.
      #unless _.isArray(@_sequence) and _.isArray(@_sequence[0])

   expression: -> @_sequence.expressions[@expression_index]
   valueOf:    -> @_sequence.expressions[@expression_index]?.at @index

   clone: ->
      new Position @_sequence, @expression_index, @index

   # Returns a new `Position`, representing the next element of the parent sequence needing
   # combination. (If the current element is the last word of the last expression in the sequence,
   # returns `undefined`.)
   next: ->
      if @expression().at(@index + 1)?
         return new Position @_sequence, @expression_index, @index + 1
      if @_sequence.expressions[@expression_index + 1]?
         return new Position @_sequence, @expression_index + 1


# An `Operation` is effectively just a delayed function-invocation; every operation is a function-
# member of this class, which is evaluable once preceding operations in a given `Execution`'s queue
# are complete.
#
# `Operation` types are added with `Operation.register`; they are written as a function executed in
# the context of the `Execution` to which they are applied, passed the `params` stored on the
# `Operation` instance in the queue.
#
# Operations are not removed from a queue (as completed) until they indicate success by returning a
# truthy value. (They shouldn't, therefore, preform mutating operations and then indicate failure.)
#
# Available operations:
#
#  - `advance`: given a resumption-value, this will apply that value to the `Execution` in question,
#    as the result of the previous `Combo` generated by it. This will advance the evaluation of that
#    `Execution` by one step, generally producing the *next* `Combo`.
#  - `adopt`: given a target object, block further operations (so, advancements) in this
#    `Execution`'s queue until it is available for responsibility; then take that responsibility.
Paws.Operation = Operation = class Operation
   constructor: constructify(return:@) (@op, @params...)->

   @operations: new Object
   @register: (op, func)-> @operations[op] = func

   # Takes an `Execution` to preform this operation `against`, preforms the `op`, and returns a
   # return-value as defined by the operation.
   perform: (against)->
      Operation.operations[@op].apply(against, @params)


Operation.register 'advance', (response)->
   if process.env['TRACE_REACTOR']
      warning ">> #{this} ← #{response}"
      if @current() instanceof Function
         body = @current().toString()
         wtf term.block body, (line)->   ' │ ' + line.slice 0, -4
      else
         body = @current().expression().with context: 3, tag: no
            .toString focus: @current().valueOf()
         debug term.block body, (line)-> ' │ ' + line.slice 0, -4

   if @complete()
      warning ' ╰┄ complete!' if process.env['TRACE_REACTOR']
     #stage.flushed() unless stage.upcoming()
      return

   next = @advance response

   if typeof next is 'function'
      next.call this, response

   else
      if process.env['TRACE_REACTOR']
         warning " ╰┈ ⇢ combo: #{next.subject} × #{next.message}"

      require('assert') next.message?
      subject = next.subject ? @locals
     #message = next.message ? @locals    # this should be impossible.
      params  = Execution.create_params this, subject, next.message
      params.rename '<parameters>'

      subject.receiver.clone().respond params


Operation.register 'adopt', ()->


# Debugging output
# ----------------
# Convenience to call whatever string-making methods are available on the passed object.
Paws.inspect = (object)->
   object?.inspect?() or
   object instanceof Thing && Thing::inspect.apply(object) or
   _.node.inspect object

Thing::_inspectID = ->
   if @id? then @id.slice(-8) else ''
Thing::_inspectName = ->
   names = []
   names.push ''
   names.push @_inspectID()   if @_inspectID and (not @name or process.env['ALWAYS_ID'] or @_?.tag == no)
   names.push term.bold @name if @name
   names.join(':')
Thing::_tagged = (output)->
   tag = @constructor.__name__ or @constructor.name
   content = if output then ' '+output else ''
   "<#{tag}#{(@_inspectName or Thing::_inspectName).call this}#{content}>"

Execution::_inspectName = ->
   names = []
   names.push ''
   names.push @_inspectID()   if @_inspectID and (not @name or process.env['ALWAYS_ID'] or @_?.tag == no)
   names.push term.bold @name if @name
   names.join(':')
Native::_inspectName = ->
   names = Execution::_inspectName.call this
   if @advancements?
      calls = @advancements - @bits.length
      names + new Array(calls).join 'ʹ'
   names


Thing::toString = ->
   if @_?.tag == no then @_inspectName() else @_tagged()

Thing::inspect = ->
   @toString()

Label::_inspectName = ->
   names = []
   names.push ''
   names.push term.bold @name if @name
   names.join(':')
Label::toString = ->
   output = "“#{@alien}”"
   if @_?.tag == no then output else @_tagged output

# By default, this will print a serialized version of the `Execution`, with `focus` on the current
# `Thing`, and a type-tag. If explicitly invoked with `tag: true`, then the serialized content will
# be omitted; if instead with `serialize: true`, then the tag will be omitted.
Execution::tostring = ->
   if @_?.tag != yes or @_?.serialize == yes
      output = "{ #{@begin.toString focus: @current().valueOf()} }"

   if @_?.tag == no or @_?.serialize == yes then output else @_tagged output

# For `Native`s, we instead print only the tag by default, *if it is named*. If a name is absent, we
# print the serialized implementation as well.
Native::toString = ->
   if @_?.serialize != no and (not @name or @_?.tag == no or @_?.serialize == yes)
      output = if @synchronous
         synch = @synchronous.toString()
         synch.slice synch.indexOf("{"), synch.lastIndexOf("}") + 1
      else
         bodies = @bits.map (bit)->
            bit = bit.toString()
            bit.slice bit.indexOf("{"), bit.lastIndexOf("}") + 1
         bodies.join ' -> '

   if @_?.tag == no then output else @_tagged output


# Initialization
# ==============
Thing.init_receiver()
Execution.init_receiver()

debug "++ Datagraph available"
