Walker           = (require 'giraphe').default
uuid             = require 'uuid'
indentString     = require 'indent'
{ EventEmitter } = require 'events'

_                = require './utilities.coffee'
debugging        = require './debugging.coffee'

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
# The Paws object-space implements a single graph (in the computer-science sense) of homogeneous(!)
# objects. Each object, or node in that graph, is called a `Thing`; and is singly-linked² to an
# ordered list of other nodes.
#
# The first member of the metadata-links¹ on a `Thing` (referred to as the ‘noughtie’) is generally
# reserved for special use from within Paws; and thus Paws' lists are effectively one-indexed.
#
# In addition to these links to other nodes that every `Thing` has, some `Thing`s carry around
# additional information; these are implemented as additional JavaScript types, such as `Label`
# (which carries around identity, and a description in the form of a Unicode string) or `Execution`
# (which encapsulates procedure and execution-status information.)
#
# The Paws model is to consider that underlying information as ‘data’ (the actual *concerns* of a
# Paws program), and the links *between* those data as ‘metadata’; describing **the relationships
# amongst** the actual data.
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
# (those carrying no additional data around) is an equivalent to the `::find` operation; that is, to
# treat the subject-object as a dictionary, and the message-object as a key to search that
# dictionary for. The default for any object, however, can be overridden per-object, changing how a
# given node in the graph responds to `Combination`s with other objects. (See the documentation for
# `Execution` for more exposition on the evaluation model.)
#
# ---- ---- ----
#
# 1. The links from one `Thing` to another are encoded as `Relation` objects, which are further
# annotated with the property of **‘ownership’**: an object that ‘owns’ an object below it in the
# graph is claiming that object as a component of the *overall data-structure* that the parent
# object represents. (Put simply: a series of ownership-annotated links in the datagraph describe a
# single data-structure as a subgraph thereof.)
#
# 2. Note that although Paws objects are, by default, singly-linked, each `Thing` *also* includes
# separate reverse-links to all of the `Thing`s that ‘own’ it, to facilitate responsibility
# calculations. (Although actual ownership flows only-downwards along the graph, responsibility
# existing lower on the graph can still preclude owning ancestors from being adopted; so these back-
# links are maintained on those descendants as hints that they have adopted.)
#
# ---- ---- ----
#
# Many Paws operations change the data-graph; *any* of these operations can, thus, also effectively
# mutate responsibility. Libside, this is handled by the user: ‘<operation> assumes you've taken
# responsibility for its arguments’, or ‘<operation> will return when responsibility is available.’
# This becomes a little more complicated when calling from JavaScript, however.
#
# While *everything* is effectively asynch in Paws (that is, after all, sort of the point!), most
# things happening within a reactor-tick (or in a consuming/embedding application) are
# *synchronous*. This is problematic, both because there is no way to ‘block’ an operation mutating
# responsibility until such responsibility is available, and because when these operations are
# already being called from within the reactor-tick of a particular Paws operation, we can't
# retroactively change that operation to an `Operation['adopt']`! From another perspective,
# JavaScript operations happen atomically, in a single reactor-tick, from perspective of Paws
# operations.)
#
# This is exposed and communicated in this JavaScript API by partitioning available methods into
# three categories, and prefixing the names based on their behaviour. In general,
#
# 1. *underscore-prefixed methods* like `::_set` generally do no responsibility-checking, and must
#    be used after explicitly checking that the required responsibility is available (or during a
#    tick on a native that has responsibility for the relevant arguments);
#
# 2. *bare methods* like `::set` or `::dedicate` are still synchronous, but will preform
#    responsibility-checking in the due course of their behaviour, and throw synchronously if they
#    are unable to complete their operations or need to be placed into the operation-queue;
#
# 3. and *dollar-prefixed methods* like `::$dedicate` will return a `Promise`, and preform their
#    behaviour *asynchronously*, placing themselves in the Paws operation-queue if necessary
#    (meaning that, if called *during* a reactor-tick, these may effectively unstage and block the
#    calling operation.)
#
# In general, underscore-prefixed methods may be considered ‘private’, as the bare methods will
# behave exactly the same, but with additional reasonableness-checks; and dollar-prefixed methods
# are often essentially analogues to libside primitives.
#
# ### Method summary:
# `Thing`s are obtained via ...
#  - direct creation, `new Thing`, with a list of children,
#  - by `::clone`ing an existing `Thing`,
#  - or, as a convenience, with a provided JavaScript template, with `.construct`, below.
#
# Their `Relation`s to children are stored in an `Array`, manipulable ...
#  - canonically, as an ordered set: `::at`, `::set`, `::push`, `::pop`, `::shift`, and `::unshift`;
#  - or as a pseudo-dictionary, with ordered ‘pairs’ added by `::define` and queried by `::find`.
#
# Meanwhile, the data-structure ownership amongst a structure's elements is exposed through:
#  - `::own_at` (or `Relation::owned_by`), to create new membership in a data-structure;
#  - `::disown_at` (or `Relation::contained_by`), to leave ownership-less links between nodes;
#  - and `::is_owned_by` to query ownership relationships.
#
# >  Of note, as another convenience: all methods that take a `Thing` and manipulate relationships,
# >  can *also* take given a pre-constructed `Relation` indicating the desired relationship. It
# >  won't be used directly, but the relationship will be imitated by the changes produced in the
# >  data-graph:
# >
# >           a_thing.set(1, another_thing.owned_by(a_thing))
# >           # Equivalent to:
# >           a_thing.set(1, another_thing)
# >           a_thing.own_at(1)
Paws.Thing = Thing = parameterizable class Thing extends EventEmitter

   constructor: constructify(return:@) (elements...)->
      @id = uuid.v4()

      @metadata = new Array
      @owners = new Array
      @custodians  = { direct: [], inherited: [] }
      @supplicants = { direct: [], inherited: [] }

      relations = elements.map (it)=>
         rel = new Relation this, it
         rel?.owns = @_?.own if @_?.own?
         rel

      @_push relations if relations.length

      @metadata.unshift undefined if @_?.noughtify != no

   # Constructs a generic ‘key/value’ style `Thing` from a `representation` (a JavaScript `Object`-
   # hash) thereof. This convenience method expects arguments constructed as pairs of 1. any string
   # (as the key, which will be converted into the `Label`), and 2. a Paws `Thing`-subclass (as the
   # value.) These may be nested.
   #
   # >  For instance, given `{foo: thing_A, bar: thing_B}`, `construct()` will product a `Thing`
   #    resembling the following (disregarding noughties):
   #
   #             ((‘foo’, thing_B), (‘bar’, thing_B))
   #
   # The ‘pair-ish’ values are always owned by their container; as are, by default, the ‘leaf’
   # objects passed in. (The latter is a behaviour configurable by `.with(own: no)`.)
   #
   # @option own: Construct the structure as as `own`ing newly-created sub-Things
   # @option names: `rename` the constructed `Thing`s according to the key they're being assigned to
   @construct: (representation)->
      pairs = for key, value of representation

         if _.isFunction value
            value = Native.synchronous value

         else unless value instanceof Thing or value instanceof Relation
            value = @construct value

         leave_ownership_alone = value instanceof Relation
         should_own = @_?.own ? (if leave_ownership_alone then undefined else yes)

         value.rename key if @_?.names
         Thing.pair key, value, should_own

      return Thing.with(own: yes) pairs...


   # ### Common ###

   # Creates a copy of the `Thing` it is called on. Alternatively, can be given an extant `Thing`
   # copy this `Thing` *to*, over-writing that `Thing`'s metadata. In the process, the
   # `Relation`s within this relation are themselves cloned, so that changes to the new clone's
   # ownership don't affect the original.
   clone: (into, {clone_metadata} = {clone_metadata: true})->
      into ?= new Thing.with(noughtify: no)()

      if @name? and not into.name?
         into.name = @name

      if clone_metadata
         into.metadata = []
         @_clone into

      return into

   # Private: Just clone the Relations and update their `from` proprety, nothing more.
   _clone: (into)->
      rs = @metadata.map (rel)->
         rel = rel?.clone()
         rel?.from = into
         rel

      into.metadata.splice into.metadata.length, 0, rs...

   # TODO: A deep-`::clone` that stops at ownership boundaries.
   # structure_clone: (into)->

   # DOCME
   deep_clone: (into, seen = {})->
      return seen[@id] if seen[@id]?

      res = @clone into, {clone_metadata: false}

      seen[@id] = res

      res.metadata = @metadata.map (rel)->
         return rel unless typeof rel is 'object'
         new_rel = rel.clone()
         new_rel.from = res
         new_rel.to = rel.to?.deep_clone(undefined, seen)
         return new_rel

      return res

   # DOCME
   compare: (to)-> to == this


   # ### Shared, private methods ###

   # Private; implements the pre-checking-and-throwing behaviour for *public* methods that
   # eventually call `_add_parent_and_inherit_custodians()`. Expects a pre-constructed array.
   _validate_availability_to: (custodians)->
      unless @available_to custodians...
         # FIXME: Add more useful debugging information
         throw new ResponsibilityError(
            "Attempt to add Thing held under conflicting responsibility.")

   # XXX: N.B., when modifying ownership-mutation: Multiple Relations `from` and `to` the *same pair
   #      of Things* can exist in `@owners`, because they can exist in the `@metadata` of the
   #      parent, and one of them could be deleted, leaving the second.

   # Private; assumes the caller has checked availability, expects a safe (unused) `Relation`.
   _add_parent_and_inherit_custodians: (rel)->
      @owners.push rel unless _.contains @owners, rel

      rel.from._all_custodians().forEach (li)=>
         @_add_custodian li

      return this

   # Private; does several useful things:
   #
   #  - Remove a passed parent from the `owners` array,
   #  - check the *other* owners for all responsibility inherited through the removed owner,
   #  - and only then remove any *no-longer-reachable* `custodians`.
   #
   # N.B.: May only be called on a Relation *actually present as an owner* (i.e. call only on
   # `rel.to`, and after checking `rel.owns`.)
   _del_parent_and_inherited_custodians: (rel)->
      _.pull @owners, rel

      # FIXME: This m...might be *very* slow
      rel.from._all_custodians().forEach (li)=>
         unless _.any(@owners, (owner)=> li._is_in owner._all_custodians() )
            @_del_custodian li

      return this

   _add_custodian: (li)->
      fam = if this is li.ward then 'direct' else 'inherited'
      unless li._is_in @custodians[fam]
         li._add_to @custodians[fam]

   _del_custodian: (li)->
      fam = if this is li.ward then 'direct' else 'inherited'
      li._del_from @custodians[fam]

   _add_supplicant: (li)->
      fam = if this is li.ward then 'direct' else 'inherited'
      unless li._is_in @supplicants[fam]
         li._add_to @supplicants[fam]

   _del_supplicant: (li)->
      fam = if this is li.ward then 'direct' else 'inherited'
      li._del_from @supplicants[fam]


   # ### ‘Array-ish’ metadata manipulation ###

   at:  (idx)->  @metadata[idx]?.to

   # Directly set the child at a particular index to the passed value.
   #
   # @arg {Number} idx           Index on the receiver's metadata to change
   # @arg {(Relation|Thing)} it  Node to place at the given index
   # @returns {Relation}         New relation placed at idx
   # @throws ResponsibilityError If the new child is to be owned by the parent, but is not available
   #    to one of the parent's custodian-Executions
   #---
   # TODO: Async `::$set`.
   set: (idx, arg)->
      unless arg?
         return @_set idx, undefined

      rel = new Relation this, arg

      if rel.owns
         rel.to._validate_availability_to @_all_custodians()

      return @_set idx, rel

   # Private; directly assigns another `Thing` to an index-specified location in the receiver's
   # metadata. Assumes the caller has checked availability, expects a safe (brand-new / unused)
   # `Relation`.
   #
   # @see set
   _set: (idx, rel)->
      prev = @metadata[idx]

      if rel?.owns
         rel.to._add_parent_and_inherit_custodians rel

      if prev?.owns
         prev.to._del_parent_and_inherited_custodians prev

      @metadata[idx] = rel

      return rel

   # Append passed values to the receiver's metadata.
   #
   # Passed values can each be either a `Thing` (`foo.push(a_thing)`), or a `Relation` expressing
   # the desired ownership of that value (`foo.push(a_thing.contained_by(foo))` or the same with
   # `owned_by`, for instance). The arguments need not be homogenous.
   #
   # You can configure the ownership of all the passed values, wholesale, by explicitly setting the
   # `own:` option to either `true` or `false`:
   #
   #     blah.with(own: yes).push(foo, bar, baz)
   #
   # If the `Thing` in question is affected by responsibility conflicting with that flowing from /
   # through the receiver (that is, it is both marked as owned, and held with a conflicting license
   # by other `Liability`), a `ResponsibilityError` will be thrown.
   #
   # @arg {...(Relation|Thing)} elements  Values to be appended as children
   # @returns {Thing}                     The receiver
   # @throws ResponsibilityError          If one of the new children is to be owned by the parent,
   #    but is not available to one of the parent's custodian-Executions
   # @option own {Boolean}                Value with which to override the ownership of the children
   # @see unshift
   #---
   # TODO: Async `::$push`.
   # TODO: There's gotta be some shortcut-fusion / lazy-evaluation methodology to squash the
   #       iteration here, and the iteration in `::_push`, into one iteration-pass ...
   push: (elements...)->
      relations = elements.map (it)=>
         rel = new Relation this, it
         rel?.owns = @_?.own if @_?.own?
         rel

      unless _.isEmpty (custodians = @_all_custodians())
         _.forEach relations, (rel)=>
            if rel?.owns
               rel.to._validate_availability_to custodians

      return @_push relations

   # Private; directly adds other `Thing`s to the end of the receiver's metadata. Assumes the caller
   # has checked availability, expects an `Array` of safe (brand-new / unused) `Relations`.
   #
   # @see push
   _push: (relations)->
      _.forEach relations, (rel)=>
         if rel?.owns
            rel.to._add_parent_and_inherit_custodians rel

      @metadata = @metadata.concat relations

      return this

   # XXX: pop() and shift(), being remove-only operations, currently are purely synchronous, with no
   #      possibility of failure. Theoretically, though, at least libside, removal is still a
   #      mutating operation, and *should* require ownership.

   # Remove the ordinally-last `Thing` from the receiver's metadata relations, and returns it.
   #
   # If the departing `Thing` in question is affected by responsibility flowing from/through the
   # receiver, it will be `emancipated()`.
   #
   # @returns {Thing}                     The removed entry
   pop: ->
      rel = @metadata.pop()

      if rel?.owns
         rel.to._del_parent_and_inherited_custodians rel

      return rel?.to

   # Remove the ordinally-first `Thing`, after the noughty, from the receiver's metadata relations;
   # and returns it.
   #
   # If the departing `Thing` in question is affected by responsibility flowing from/through the
   # receiver, it will be `emancipated()`.
   #
   # @returns {Thing}                     The removed entry
   shift: ->
      noughty = @metadata.shift()
      rel     = @metadata.shift()
      @metadata.unshift noughty

      if rel?.owns
         rel.to._del_parent_and_inherited_custodians rel

      return rel?.to

   # Prepend passed values to the receiver's metadata, immediately following the noughty.
   #
   # Passed values can each be either a `Thing` (`foo.unshift(a_thing)`), or a `Relation` expressing
   # the desired ownership of that value (`foo.unshift(a_thing.contained_by(foo))` or the same with
   # `owned_by`, for instance). The arguments need not be homogenous.
   #
   # You can configure the ownership of all the passed values, wholesale, by explicitly setting the
   # `own:` option to either `true` or `false`:
   #
   #     blah.with(own: yes).unshift(foo, bar, baz)
   #
   # If the `Thing` in question is affected by responsibility conflicting with that flowing from /
   # through the receiver (that is, it is both marked as owned, and held with a conflicting license
   # by other `Liability`), a `ResponsibilityError` will be thrown.
   #
   # @arg {...(Relation|Thing)} elements  Values to be prepended as children
   # @returns {Thing}                     The receiver
   # @throws ResponsibilityError          If one of the new children is to be owned by the parent,
   #    but is not available to one of the parent's custodian-Executions
   # @option own {Boolean}                Value with which to override the ownership of the children
   # @see push
   #---
   # TODO: Async `::$unshift`.
   # TODO: cf. TODO on push() re: shortcut-fusion
   unshift: (elements...)->
      # FIXME: DRYME, this is all a duplicate of ::push
      relations = elements.map (it)=>
         if it instanceof Relation
            rel = it.clone()
            rel.from = this

         if it instanceof Thing
            rel = new Relation this, it

         rel?.owns = @_?.own if @_?.own?

         return rel

      unless _.isEmpty (custodians = @_all_custodians())
         _.forEach relations, (rel)=>
            if rel?.owns
               rel.to._validate_availability_to custodians

      return @_unshift relations

   # Private; directly adds other `Things` to the beginning-save-one of the receiver's metadata.
   # Assumes the caller has checked availability, expects a disposable / brand-new `Array` of safe
   # (also brand-new / unused) `Relations`.
   #
   # @see unshift
   _unshift: (relations)->
      _.forEach relations, (rel)=>
         if rel?.owns
            rel.to._add_parent_and_inherit_custodians rel

      protect_noughty = @metadata.length != 0

      noughty = @metadata.shift() if protect_noughty
      @metadata = relations.concat @metadata
      @metadata.unshift noughty   if protect_noughty

      return this

   # Deep-copy all the metadata of the `additions` argument, and append them to the receiver.
   _inject: (additions)->
      additions.metadata.shift() if @_?.include_noughty != no

      @_push additions.metadata

   # ### ‘Dictionary-ish’ metadata manipulation ###

   # Convenience method to create a ‘pair-ish’ `Thing` (one with only two members, the first of
   # which is a `Label` ‘key.’)
   #
   # The created thing will own the label, but not the value, by default. This can be overriden by
   # passing a third indicating whether to `own` the value.
   #
   # (N.B. that this cannot fail, despite modifying ownership — the parent is newly-created, and
   #  thus has no custodians.)
   @pair: (key, value, own)->
      pair = new Thing
      pair._push Label(key).owned_by pair
      pair._push value.contained_by(pair, own) if value
      return pair

   # A convenience to append a new ‘pair’ to the end of the receiver (thus “defining” a value, if
   # the receiver is seen as a pseudo-dictionary.)
   #
   # The pair-`Thing` itself and `Label` are always owned by the receiver; but the `value` (although
   # it defaults to being not-owned) can be configured by passing a Relation:
   #
   #     blah.define('foo', bar.owned_by(blah))
   #
   # Availability of the `value` will be checked, and a `ResponsibilityError` will be thrown in the
   # case of a conflict. (See `::push`.)
   #---
   # TODO: handling undefined values
   define: (key, value)->
      pair = Thing.pair key, value

      @push pair.owned_by this

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


   # ### Ownership ###

   # FIXME: Responsibility ;_;
   own_at: (idx)->
      if (prev = @metadata[idx])? and not prev.owns
         @metadata[idx] = prev.as_owned()
         @metadata[idx].to._add_parent_and_inherit_custodians @metadata[idx]
      else prev

   disown_at: (idx)->
      if (prev = @metadata[idx])? and prev.owns
         @metadata[idx] = prev.as_contained()
         @metadata[idx].to._del_parent_and_inherited_custodians prev
         @metadata[idx]
      else prev

   # FIXME: Okay, this naming is becoming a mess.
   owns_at: (idx)-> @metadata[idx]?.owns

   is_owned_by: (other)->
      if other instanceof Relation
         _.contains @owners, other
      else
         _.any @owners, 'from', other

   #---
   # XXX: At construct-time, this depends on `Relation` being defined. Sans hoisting (WHY DID I LAY
   #      THIS OUT THIS WAY?), these can't be exist until init-time — see `Thing._init_walkers`,
   #      `Thing._init_responsibility_walkers`, etc.
   _walk: walk = undefined

   # This returns a flat array of all the descendants of the receiver that satisfy a condition,
   # supplied by an optional callback.
   #
   # The callback may explicitly return `false` to indicate a descendant should be excluded; or the
   # sentinel value `Thing.abortIteration` to terminate the graph-walking early.
   #
   # The `descendants` return-value may be *passed in* as a pre-cache; any Things already existing
   # in that cache will not be touched by this function. (Tread carefully: if the data-graph is
   # modified between the *creation* of `descendants`, and the re-execution of this function, then
   # that cache may no longer be valid!)
   _walk_descendants: walk_descendants = undefined

   @abortIteration: Walker.abortIteration

   @_init_walkers: ->
      Thing::_walk = walk =
         new Walker class: Thing, key: 'id'
          , edge: { class: Relation, extract_path: 'to' }
          , inspector: Paws.inspect

      Thing::_walk_descendants = walk_descendants =
         walk -> _.compact(@metadata)


   # ### Responsibility ###

   is_adopted: ->
      not _.isEmpty(@custodians.direct)   or not _.isEmpty(@custodians.inherited)

   is_supplicated: ->
      not _.isEmpty(@supplicants.direct)  or not _.isEmpty(@supplicants.inherited)

   _any_custodian: (f)->
      _.any(@custodians.direct, f) or
      _.any(@custodians.inherited, f)

   _any_supplicant: (f)->
      _.any(@supplicants.direct, f) or
      _.any(@supplicants.inherited, f)

   _all_custodians: (f)->
      custodians = _(@custodians.direct).concat(@custodians.inherited).uniq()
      if f?
         _.all custodians, f
      else
         custodians.value()

   _all_supplicants: (f)->
      supplicants = _(@supplicants.direct).concat(@supplicants.inherited).uniq()
      if f?
         _.all supplicants, f
      else
         supplicants.value()

   # Returns a walker that only walks descendants *with custodians*.
   _walk_adopted: walk_adopted = undefined

   @_init_responsibility_walkers: ->
      Thing::_walk_adopted = walk_adopted =
         walk_descendants -> @is_adopted()

   # Indicates success if the passed `Execution` *already* holds the indicated license (or a greater
   # one) for the receiver. (For instance, if the `Execution` holds write-license to a parent of the
   # receiver, then `belongs_to(exe, 'read')` would indicate success.)
   #
   # If passed a `Liability` instead, this object is simply checked for the presence of that
   # specific `Liability`.
   #---
   # TODO: Handle being passed 1. an Execution but no License at all, or 2. a Liability *and* a
   #       License
   belongs_to: (it, license)->
      return false unless @is_adopted()

      if license?
         if license is 'write' or license is yes
            return @_any_custodian (liability)->
               return true if liability.custodian is it and
                              liability.write()   is yes
         else
            return @_any_custodian (liability)->
               return true if liability.custodian is it

      else
         return it._is_in(@custodians.direct) or
                it._is_in(@custodians.inherited)

   # Private helper that checks *only* the receiver's custodians for conflicts
   _directly_available_to: (liability)->
      return true if @belongs_to liability.custodian, liability.write()

      if liability.write()
         return false if @_any_custodian (li)=> li.custodian != this
      else
         return false if @_any_custodian (li)=> li.custodian != this and li.write()

      return true

   # Determines if the receiver *can* be `dedicate`-ed to the passed `Liability`.
   #
   # Returns `true` if all owned-descendants of the receiver are available for adoption (i.e. have
   # no conflicting responsibility); and `false` if the receiver or one of its descendants *cannot*
   # be adopted (i.e. currently has some form of conflicting responsibility.)
   #
   # This is, of course, checked as a part of `dedicate`; so explicitly calling this method is
   # usually only necessary if something being available for adoption *changes the decision of what
   # to adopt*. (Or, possibly, adopting across reactor ticks?)
   #---
   # TODO: This *badly* needs to share a cache with `::dedicate`, as the previous implementation did
   # TODO: Specify how this handles being given an *unrelated* (or blank) Liability
   available_to: (liabilities...)->
      liabilities = liabilities[0] if _.isArray liabilities[0]

      # First, check this object itself,
      return false unless _.every liabilities, (li)=> @_directly_available_to li

      # Then, depth-first traverse every *owned child*
      walk_result = @_walk_descendants ->
         return Thing.abortIteration unless _.every liabilities, (li)=> @_directly_available_to li

      return (false != walk_result)

   # When passed an existing `descendants` object, this assumes you obtained that by already having
   # checked their availability via `::available_to`.
   #---
   # FIXME: can't I just ... `@_walk_descendants -> @_add_custodian liability`, like below??
   _dedicate: (liability)->
      unless liability._is_in @custodians.direct
         _.values(@_walk_descendants()).forEach (descendant)=>
            descendant._add_custodian liability

   # FIXME: DOCME
   # TODO: Make this accept an Execution directly, as a convenience
   dedicate: (liabilities...)->
      liabilities = liabilities[0] if _.isArray liabilities[0]

      return false unless _.every liabilities, (li)=> @available_to li

      liabilities.forEach (li)=> @_dedicate li

      return true

   # The inverse of `::_dedicate`, this removes an existing `Liability` from the receiver (and its
   # owned-descendants.)
   #
   # Returns `true` if the `Liability` was successfully removed (or if the receiver didn't belong to
   # it in the first place).
   #
   # Nota bene: This can *only* remove responsibility *from the root node of the adopted sub-graph*.
   #            It will return truthfully if the `Liability` on which it is called is not in the
   #            directly-responsible `custodians` for the receiver; this also applies if the passed
   #            `Liability` roots on another node! You probably want `Liability::discard`, which
   #            calls this method.
   _emancipate: (liability)->
      return true unless liability._is_in @custodians.direct

      @_walk_descendants -> @_del_custodian liability; undefined

      return true

   # DOCME
   # XXX: At the moment, `_emancipate` cannot return false; so this isn't properly transactional. If
   #      there's any way for emancipation to fail, though, it's important to fix this method to
   #      *not actually remove the custodians* until the efficacy of the operation can be verified.
   emancipate: (liabilities...)->
      liabilities = liabilities[0] if _.isArray liabilities[0]

      return _.all liabilities, (liability)=> @_emancipate liability

   # FIXME: can't I just ... `@_walk_descendants -> @_add_supplicant liability`, like below??
   _supplicate: (liability)->
      unless liability._is_in @supplicants.direct
         _.values(@_walk_descendants()).forEach (descendant)=>
            descendant._add_supplicant liability

   # This adds a passed `Liability` into the receiver's `supplicants` array, indicating that the
   # `Execution` needs to be resumed when it will be able to successfully obtain responsibility for
   # the receiver.
   #
   # This should only be called after `::dedicate` has been called, and has indicated failure; this
   # is handled for you by ... # FIXME: DOCME
   supplicate: (liabilities...)->
      liabilities = liabilities[0] if _.isArray liabilities[0]
      liabilities.forEach (li)=> @_supplicate li
      return true

   _clear_supplication: (liability)->
      return true unless liability._is_in @supplicants.direct

      @_walk_descendants -> @_del_supplicant liability; undefined

      return true


   # ### Utility / convenience ###

   # TODO: Option to include the noughty
   toArray: (cb)-> @metadata.slice(1).map (rel)-> (cb ? _.identity) rel?.to

   # This ascertains if the receiver is “pair-shaped” — has precisely two non-metadata elements, the
   # first of which is a Label, and the second of which isn't undefined.
   #---
   # FIXME: This almost certainly *shouldn't* exist publically at all; and especially shouldn't be
   #        central to the crucial `find()` algorihtm. D:
   isPair:   -> Boolean (@metadata.length is 3) and @metadata[1].to instanceof Label and @metadata[2]


   keyish:   -> @at 1
   valueish: -> @at 2

   # Convenience methods to create `Relation`s *to* the receiver.
   contained_by: (other, own)-> new Relation other, this, own # Defaults to `no`
   owned_by:     (other)->      new Relation other, this, yes

   rename: selfify (name)-> @name = name


   # ### Initialization ###

   @_init: ->
      @_init_walkers()
      @_init_responsibility_walkers()

      # The default receiver for `Thing`s simply preforms a ‘lookup.’
      thing_receiver = (params)->
         caller  = params.at 0
         subject = params.at 1
         message = params.at 2

         results = subject.find message

         if results[0]
            caller.stage results[0].valueish()

         # FIXME: Welp, this is horrible error-handling. "Print a warning and freeze forevah!!!"
         else
            notice "~~ No results on #{Paws.inspect subject} for #{Paws.inspect message}."

      Thing::receiver = new Native(thing_receiver).rename 'thing×'


# A `Label` is a type of `Thing` which encapsulates a static Unicode string, serving two purposes:
#
# 1. Unique-comparison: Two `Label`s originally created with equivalent sequences of Unicode
#    codepoints will `::compare` as equal. Across codebases, `Label`s share identity, even when they
#    don't share objective content / metadata relationships.
#
#    That is: `foo ['bar']` will find the same object assigned with a different instance of `'bar'`.
# 2. Description: Although not designed to be used to manipulate character-data as a general
#    string-type, `Label`s can be used to associate an arbitrary Unicode sequence with some other
#    data, as a name or description. (Hence, ‘label.’)
#
# ---- ---- ----
#
# Due to their intented use as descriptions and comparators, the string-data associated with a
# `Label` cannot be mutated after creation; and they cannot be combined or otherwise manipulated.
# However, they *can* be `::explode`d into an ordered-list of individual codepoints, each
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
# `::clone`ing a partially-evaluated `Execution`. As the original procedure progresses, its
# instructions are gradually processed and discarded; meanwhile, however, an earlier clone's will
# *not* be. When so-branched, an `Execution`'s state is all duplicated to the clone, unaffected by
# changes to the original `Execution`'s position or objective-context.
#
# **Nota bene:** While clones do not share *additions* to their respective context, `locals`, the
#                clone made is *shallow in nature*. This means that the two `Execution`s' `locals`
#                objects share the original assignments (that is, the original pairs) created prior
#                to the cloning. This further means that either branch can modify an existing
#                assignment-pair on `locals` instead of `::define`ing a new, overriding pair, thus
#                making the change visible to prior clones, if desired.
#
# ---- ---- ----
#
# This implementation stores the `Execution` information as three crucial elements:
#
# 1. A stack of positions in a `Script`, as `Position`s in the `instructions` array,
# 2. a further stack of the `results` of outer `instruction`s,
# 3. and its objective evaluation context, a `Thing` accessible as `locals`.
#
# The position is primarily maintained by `::advance`; diving into and climbing back out of sub-
# expressions to produce `Combination`s for the reactor. As it digs into a sub-expression, the
# position in the outer `Expression` is maintained in the `instructions` stack; while the results of
# the last `Combination` for each outer expression are correspondingly stored in `results`.
#
# **Nota anche: The `instructions` stack lists *completed* nodes; ones for which a `Combination` has
#               already been generated.)**
Paws.Execution = Execution = class Execution extends Thing

   constructor: constructify (@begin)->
      if typeof @begin is 'function' then return Native.apply this, arguments

      @begin = new Position @begin if @begin? and not (@begin instanceof Position)

      if @begin
         @results      = [ null   ]
         @instructions = [ @begin ]
      else
         @results      = [        ]
         @instructions = [        ]

      @pristine = yes
      @locals = new Thing().rename 'locals'
      @locals.define 'locals', @locals
      this   .define 'locals', @locals.owned_by this

      @ops = new Array

      @wards = new Array
      @blockers = new Array

      return this


   # ### Common ###

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
      to.define        'locals', to.locals.owned_by to

      to.advancements = @advancements if @advancements?

      if @instructions? and @results?
         to.instructions = @instructions.slice 0
         to.results      = @results.slice 0

      # TODO: 🤘 ops? wards? blockers??

      return to


   # ### Operation-queue ###

   # Pushes a new `Operation` onto this `Execution`'s `ops`-queue.
   queue: (something)->
      return @queue new Operation arguments...  unless something.op?

      @ops.push something

   # A convenience method for pushing an 'advance' `Operation`, specifically.
   #---
   # TODO: Needs to obtain the Unit by climbing the datagraph, if this isn't called on-stack.
   stage: (response)->
      @queue new Operation 'advance', response
      Paws.Reactor._notify_some this, 'operational'

   # This informs an `Execution` of the ‘result’ of the last `Combination` returned from `next`.
   # This value is stored in the `results` stack, and is later used as one of the values in further
   # `Combination`s.
   #---
   # FIXME: Should this be public? o_O
   register_response: (response)-> @results[0] = response


   # ### Position management and advancement ###

   complete:-> !this.instructions.length

   # Returns the *current* `Position`; i.e. the top element of the `instructions` stack.
   current:-> @instructions[0]

   # Returns the next `Combination` that needs to be preformed for the advancement of this
   # `Execution`. This is a mutating call, and each time it is called, it will produce a new
   # (subsequent) `Combination` for this `Execution`.
   #
   # It usually only makes sense for this to be called after a response to the *previous*
   # combination has been signaled by `register_response` (obviously unless this is the first time
   # it's being advanced.) This also accepts an optional argument, the passing of which is identical
   # to calling `::register_response` with that value before-hand.
   #
   # For combinations involving the start of a new expression, `null` will be returned as one part
   # of the `Combination`; this indicates no meaningful data from the stack for that node. (The
   # reactor will interpret this as an instruction to insert this `Execution`'s `locals` into that
   # combo, instead.)
   advance: (response)->
      return undefined if @complete()

      @register_response response if response?

      # If we're continuing to advance a partially-completed `Execution`, ...
      @_last_completed = @instructions[0]
      previous_response = @results[0]
      unless @pristine

         # Gets the next instruction from the current sequence (via `Position#next`)
         @instructions[0] =
         upcoming = @_last_completed.next()

         # If we've completed the current sub-expression (a sequence.), then we're going to step out
         # (pop the stack.) and preform the indirected combination.
         unless upcoming?
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
            unless upcoming.valueOf()?
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
      unless upcoming.valueOf()?
         return new Combination previous_response, this

      # At this point, through one of several paths above, we've definitely descended into a (or
      # several) sub-expression(s), and are definitely looking at the first `Thing` in a new
      # expression.
      upcoming_value = upcoming.valueOf()
      return new Combination null, upcoming_value


   # ### Responsibility ###

   # Given a `Liability`, this will record that responsibility into the receiver's `wards`.
   #
   # Note: This does not preform any verifications or availability checks; that must be handled by
   #       the caller; for that reason, this is usually called after `Thing::dedicate`. (You
   #       probably want to use `Liability::commit` instead of doing these things manually.)
   accept: (liability)->
      liability._add_to @wards
      liability._del_from @blockers
      return liability

   # Given a `Liability`, this will remove that responsibility from the receiver's `wards`.
   #
   # Note: This is usually called after `Thing::emancipate`. (You probably want to use
   #       `Liability::discard` instead of doing these things manually.)
   abjure: (liability)->
      liability._del_from @wards
      return liability

   # TODO: DOCME
   block: (liability)->
      unless liability._is_in @wards
         liability._add_to @blockers

      return liability

   _clear_block: (liability)->
      liability._del_from @blockers
      return liability


   # ### Utility / convenience ###

   # Creates a list-thing of the form that receiver `Execution`s expect.
   @create_params: (caller, subject, message)-> new Thing.with(noughtify: no)(arguments...)


   # ### Initialization ###

   @_init: ->
      # The `Execution` default-receiver is specified to preform a ‘call-pattern’ invocation:
      # cloning the subject-`Execution`, resuming that clone, and explicitly *not* resuming the
      # caller.
      execution_receiver = (params)->
         subject = params.at 1
         message = params.at 2

         subject.clone().stage message

      Execution::receiver = new Native(execution_receiver).rename 'execution×'


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
# Of great use, we also provide the `.synchronous` convenience function; although most `Native`s
# imitate fully-asynchronous, coroutine-style procedures, this function can be used to construct
# faux-synchronous-style procedures that consume all of their parameters before evaluating and
# producing a result. (This expidently allows `Native` procedures to be written as single,
# synchronous `Function`s, that accept multiple arguments and `return` a single result.)
Paws.Native = Native = class Native extends Execution

   constructor: constructify(return:@) (@bits...)->
      # FIXME: Why are these necessary? idr.
      delete @begin
      delete @instructions
      delete @results

      @advancements = @bits.length

   # ### Common ###

   clone: (to)->
      super (to ?= new Native)
      _.map Object.getOwnPropertyNames(this), (key)=>
         to[key] = this[key] unless to[key]?

      to.bits = @bits.slice 0

      return to

   # ### Overrides ###

   complete:-> not @bits.length

   current:-> @bits[0]

   # `advancing` to the next unit of work for a `Native` is substantially simpler than doing so for
   # a normal `Execution`: we simply remove (and return) another body-section from `bits`.
   advance: (response)->
      return undefined if @complete()

      @pristine = no
      return @bits.shift()

   # ### Utility / convenience ###

   # This alternative constructor will automatically generate a series of ‘bits’ that will curry the
   # appropriate number of arguments into a single, final function.
   #
   # Instead of having to write individual function-bits for your `Native` that collect the
   # appropriate set of resumption-values into a series of “arguments” that you need for your task,
   # you can use this convenience constructor for the common situation that you're treating an
   # `Execution` as equivalent to a synchronous JavaScript function.
   #
   # ----
   #
   # This takes a single function, and checks the number of arguments it requires before generating
   # the corresponding bits to acquire those arguments.
   #
   # Then, once the resultant `Native` has been resumed the appropriate number of times (plus one
   # extra initial resumption with a `caller` as the value, as is standard coproductive practice in
   # Paws), the synchronous JavaScript passed in as the argument here will be invoked.
   #
   # That invocation will provide the arguments recorded in the function's implementation, as well
   # as a context-object containing the following information available on `this`:
   #
   # caller
   #  : The first resumption-value provided to the generated `Native`. Usually, itself, an
   #    `Execution`, in the coproductive pattern.
   # execution
   #  : The original `this`. That is, the generated `Native` that was constructed from the function.
   #
   # After your function executes, if it results in a non-null return value, then the `caller`
   # provided as the first response Paws-side will be resumed one final time with that as the
   # corresponding response. (Hence the name of this method: it provides a ‘synchronous’ (ish)
   # result after all the parameters have been asynchronously collected.)
   #
   # @param { function(... [Thing], this:{caller: Execution, this}): ?Thing }
   #    synch_body   The synchronous function we'll generate an Execution to match
   @synchronous: (synch_body)->
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
            caller.stage this

      # Next, we construct the *first* bit, which is a special case responsible for receiving the
      # `caller` (as is usually the case in the coproductive pattern.) It takes its resumption-
      # value, and curries it into *every* following bit. (Notice that both the middle bits, above,
      # and the concluding bit, below, save a spot for a `caller` argument.)
      bits[0] = (caller)->
         @bits = @bits.map (bit)=> _.partial bit, caller
         caller.stage this

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
            caller.stage(result) }
      """

      bits[advancements - 1] = _.partial Function(arg_names..., last_bit), synch_body

      it = new Native bits...
      it.synchronous = synch_body

      return it



# Supporting types
# ================

#---
# N.B.: Apeing the ES6 Set() interface
Paws.ThingSet = ThingSet = class ThingSet
   constructor: constructify(return:@) (things...)->
      @clear()
      things.forEach (thing)=>
         @add thing

   size: -> Object.keys(@_store).length

   # TODO: Assertions or error-handling of some sort
   add: (value)->
      @_store[value.id] = value
      return this

   clear: -> @_store = new Object

   delete: (value)->
      h = @has value
      delete @_store[value.id]
      return h

   has: (value)-> @_store[value.id]?

#---
# N.B.: Hahaha, CoffeeScript is failing me even harder than usual, here.
ThingSet.prototype[Symbol.iterator] = -> {
      foo: 'bar'
   }

Paws.Relation = Relation = parameterizable delegated('to', Thing) class Relation

   constructor: constructify(return:@) (from, to, owns)->
      if from instanceof Relation
         from.clone this
      else if to instanceof Relation
         to.clone this
         @from = from
      else
         @from = from
         @to   = to
         @owns = false

      @owns    = !!owns if owns?

   # Copy the receiver `Relation` to a new `Relation` instance. (Can also overwrite the contents of
   # an existing `Relation`, if passed, with this receiver's state.)
   #---
   # FIXME: Make truly immutable (i.e. refuse to modify once this Relation has been used in a Thing)
   #
   # UPDATE (June 2016): idk, *copying* Relations every time the edge is modified seems performance-
   #        foolish?
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

   # Equivalent to `_.contains()`, but using `::compare` instead of reference-equality. Jesus, I
   # wish I were writing OCaml. -_-
   _is_in: (container) ->
      that = this
      _.any container, (other)-> that.compare other

   _add_to: (container)->
      container.push this unless @_is_in container

   _del_from: (container)->
      that = this
      idx = _.findIndex container, (other)-> that.compare other

      return if (idx is -1)

      deleted = container.splice idx, 1
      return deleted[0]

   # Convenience method to call `Thing::available_to` on the `ward`.
   available: -> @ward.available_to this

   # This is the union of `Thing::dedicate` and `Execution::accept`, indicating the acceptance of
   # responsibility (represented by the receiver `Liability`) of the `custodian` `Execution` for the
   # `ward` `Thing`.
   #
   # This returns `false` if the `Thing::dedicate`ion fails, indicating that the responsibility
   # represented by the receiver conflicts with actively-held responsibility on the part of another
   # `Execution` than the receiver's `custodian`.
   commit: ->
      return false unless @ward.dedicate this
      @custodian.accept this
      return true

   # This is the union of `Thing::emancipate` and `Execution::abjure`, indicating the abjuration of
   # responsibility (represented by the receiver `Liability`) of the `custodian` `Execution` for the
   # `ward` `Thing`.
   #
   # This results in `Thing::_signal` (see `Thing::emancipate`), indicating to the reactor that new
   # changes in responsibility may allow supplicant `Execution`s to be staged.
   discard: ->
      @custodian.abjure this
      @ward.emancipate this
      return true

   # Thing::supplicate
   # DOCME
   # FIXME: does this need checks as to whether the requested liability is already supplicated?
   request: ->
      @custodian.block this
      @ward.supplicate this
      return true

   _clear_request: ->
      @custodian._clear_block this
      @ward._clear_supplication this
      return true


# A `Combination` represents a single operation in the Paws semantic. An instance of this class
# contains the information necessary to process a pending combo (as returned by
# `Execution::next`).
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
# `Operation` types are added with `.register`; they are written as a function executed in the
# context of the `Execution` to which they are applied, passed the `params` stored on the
# `Operation` instance in the queue.
#
# Operations are not removed from a queue (as completed) until they indicate success by returning a
# truthy value. (They shouldn't, therefore, preform mutating operations and then indicate failure!)
#
# Available operations:
#
#  - `'advance'`: given a resumption-value, this will apply that value to the `Execution` in
#    question, as the result of the previous `Combo` generated by it. This will advance the
#    evaluation of that `Execution` by one step, generally producing the *next* `Combo`.
#  - `'adopt'`: prevent further operations (so, advancements) in this `Execution`'s queue until all
#    `blockers` are cleared (i.e. all `Thing`s it's supplicated-to have become available to it.)
#    This is acheived by returning false every time it's attempted, unless the responsibility in
#    question has become available.
Paws.Operation = Operation = class Operation
   constructor: constructify(return:@) (@op, @params...)->

   @operations: new Object
   @register: (op, func)-> @operations[op] = func

   # Takes an `Execution` to preform this operation `against`, preforms the `op`, and returns a
   # return-value as defined by the operation.
   perform: (against)->
      Operation.operations[@op].apply(against, @params)


Operation.register 'advance', op_advance = (response)->
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
      # NYI: The old `reactor.coffee` extended EventEmitter and emitted a `flushed` event when the
      #      global-queue was full; this was depended upon both by the `paws.js` executable and
      #      (much more heavily) by the `Rule` implementation to determine when something was
      #      “finished.”
      #
      #      I've known for a while, though, that I need a more robust and langauge-integration
      #      definition /implementation thereof, so I guess this queueless-rewrite is as good a time
      #      as any to figure that the fuck out?
      #stage.flushed() unless stage.upcoming()
      return

   next = @advance response

   if typeof next is 'function'
      next.call this, response
      return true

   else
      if process.env['TRACE_REACTOR']
         warning " ╰┈ ⇢ combo: #{next.subject} × #{next.message}"

      require('assert') next.message?
      subject = next.subject ? @locals
     #message = next.message ? @locals    # this should be impossible.
      params  = Execution.create_params this, subject, next.message
      params.rename '<parameters>'

      # FIXME: Er. What? How does `stage` play with `Reactor::queue` ... I've clearly gained some
      #        disunified design-plans at some point. D:
      subject.receiver.clone().stage params
      return true


Operation.register 'adopt', op_adopt = (additional_liability)->
   # XXX: Debugging NYI.
  #if process.env['TRACE_REACTOR']
  #   warning ">> #{this} ← #{response}"
  #   if @current() instanceof Function
  #      body = @current().toString()
  #      wtf term.block body, (line)->   ' │ ' + line.slice 0, -4
  #   else
  #      body = @current().expression().with context: 3, tag: no
  #         .toString focus: @current().valueOf()
  #      debug term.block body, (line)-> ' │ ' + line.slice 0, -4

   if @complete()
      # XXX: Debugging NYI.
      #warning ' ╰┄ complete!' if process.env['TRACE_REACTOR']
      warning 'Completed Execution attempted to adopt o_O'
      return

   additional_liability.request() if additional_liability?

   # This continues attempting all blockers even if one fails; this means the `'adopt'` operation
   # can fail, but still obtain *some* of the locking it's waiting on.
   @blockers.forEach (liability)-> liability.commit()

   # If any of the `dedicate` calls failed, then this exec will still stand `supplicant` thereto;
   # and thus still have `blockers`.
   return _.isEmpty @blockers


# Error types
# ===========

# This is the error thrown by synchronous, responsibility-checking methods (ones not prefixed by `_`
# or `$`) when the responsibility required for the operation isn't available / held by the
# currently-evaluating code.
Paws.ResponsibilityError = class ResponsibilityError extends Error


# Debugging output
# ================
# Convenience to call whatever string-making methods are available on the passed JavaScript value.
Paws.inspect = (object)->
   object?.inspect?() or
   object instanceof Thing && Thing::inspect.apply(object) or
   _.node.inspect object

# Wraps the meat of an inspect-function
inspectify = (func)->
   return (ictx, args...)->
      old_colour_setting = null
      if typeof ictx is 'number' # Mocha calls `inspect()` functions with a number
         old_colour_setting = colour()
         colour(false)

      unless typeof ictx is 'object'
         ictx = {}

      result = func.call this, ictx, args...

      if old_colour_setting?
         colour(old_colour_setting)

      return result

# Generates a short, string-ish form of the UUID to uniquely identify a given object during debug
Thing::_inspectID = ->
   if @id? then @id.slice(-8) else ''
# Describes a given object, using the string-ish unique ID along with the object's `name`, if any.
Thing::_inspectNames = ->
   names = []
   names.push @_inspectID()   if @_inspectID and (not @name or process.env['ALWAYS_ID'] or @_?.tag == no)
   names.push term.bold @name if @name
   names

Thing::_inspectTag = -> @constructor.__name__ or @constructor.name

# Wraps an (optional) string and prefixes it with a description of the receiving object. If called
# without content to wrap, this simply wraps all of the object's names.
Thing::_tagged = (content)->
   names = (@_inspectNames or Thing::_inspectNames).call this
   tag   = (@_inspectTag   or Thing::_inspectTag  ).call this

   if this instanceof Thing and @isPair()
      names.push '~' + @keyish().alien
   else
      names.unshift(tag) if tag

   content = if content then ' '+content else ''

   "<#{names.join ':'}#{content}>"

Native::_inspectNames = ->
   names = Thing::_inspectNames.call this
   if @advancements?
      calls = @advancements - @bits.length
      names[names.length - 1] = names[names.length - 1] + new Array(calls).join 'ʹ'
   names

# The first public-entry into the debugging code; `toString` produces a short(ish) description of
# the receiving Paws object.
Thing::toString = ->
   if @_?.tag == no then @_inspectNames().join(':') else @_tagged()

# As an alternative to `toString`, one can invoke `inspect` to produce a more-lengthy description of
# some Paws objects (possibly multi-line.)
Thing::inspect = inspectify (ictx, alien_body)->
   ictx.seen ||= {} # "inspsection context"
   ictx.seen[@id] = true

   cseen = {} # "current seen"

   unless @metadata[0]? or @metadata.length > 1
      return @_tagged()

   idt = (ictx.indent ||= @_?.indent or 3)
   if 'number' is typeof idt
      idt = (ictx.indent = new Array(idt + 1).join(' '))

   idt_len = term.strip(idt).length

   ba = (ictx.break_at ||= @_?.break_at or (95 - idt_len))

   body = if alien_body then alien_body + " " else ""

   # max_label_length

   retry = false
   for rel, i in @metadata
      entry = ""
      pn = "" # "pair name"
      cidt = idt # "current-indent" —  for this 'Relation' only
      cidt_len = idt_len

      # If there's anything unusual about a 'pair', we don't want to shorthand it
      if (pair = rel?.to)? and pair.isPair() and
            (pair.at(0) is undefined) and
            (pair.keyish().metadata.length is 1) and
            pair.owns_at 1
         pn = pair.keyish().alien
         pn = '“' + pn + '”' if pn.indexOf(' ') != -1
         pn += ': '
         rel = pair.metadata[2]

      unless rel?
         entry += term.fg(10, if ictx.broke then cidt + "< ∅ >" else "∅")

      else if cseen[rel.to.id] or ictx.seen[rel.to.id]
         desc = term.fg(4, rel.to._tagged "⤣ ")

         if rel.owns
            desc = pn + desc
         else
            desc = pn + term.fg(10, "⎋ ") + desc

         entry += desc

      else # rel exists, not seen
         cseen[rel.to.id] = true
         # console.log(cseen)

         sub_ictx = _.extend({}, ictx, {
            seen: _.extend({}, ictx.seen, cseen),
            broke: false,
            break_at: ictx.break_at - cidt_len - pn.length })
         desc = rel.to.inspect(sub_ictx)

         # If we can save some space by moving the desc to the line after a long pn ...
         # console.log('brk: ', @_inspectID(), pn.length, cidt_len, sub_ictx.break_at, sub_ictx.broke, sub_ictx.overran)
         if pn.length > cidt_len and (sub_ictx.broke or sub_ictx.overran)
            # console.log('DID LONG-KEY BREAK')
            pn = pn[..-2] + "\n"
            cidt += '   '
            cidt_len += 3
            sub_ictx = _.extend({}, ictx, {
               seen: _.extend({}, ictx.seen, cseen),
               broke: false,
               break_at: ictx.break_at - cidt_len,
               indent: idt })
            desc = rel.to.inspect(sub_ictx)


         _.extend cseen, sub_ictx.seen

         if ictx.broke
            if sub_ictx.broke
               desc = indentString(desc, cidt[..-4] + '  ⎹')
            else
               desc = indentString(desc, cidt[..-4] + '   ')

            if rel.owns
               desc = idt+pn+desc
            else
               desc = idt[..-3] + term.fg(10, "⎋ ") + pn + desc[cidt.length..]

         else unless rel.owns
            desc = pn + term.fg(10, "⎋ ") + desc

         entry += desc

      if ictx.broke
         body += "\n" + entry
      else
         body += (if i > 0 then ", " else "") + entry

         if sub_ictx?.broke or term.strip(body).length >= ba # or body.indexOf("\n") != -1
            retry = true
            ictx.broke = true
            break

   if retry
      # console.log('breaking', @_inspectID())
      return @inspect ictx

   _.extend ictx.seen, cseen
   # console.error('printed', @_inspectID(), 'in', term.strip(body).length)

   if ictx.broke
      body += "\n"

   # If we got this far and it's still too long (likely due to a miniscule ba), make sure we report
   # that back
   # console.log('did we overrun?', term.strip(body).length, ba)
   if term.strip(body).length >= ba
      ictx.overran = true

   @_tagged body

Label::_inspectNames = ->
   if @name then term.bold [@name] else []

Label::toString = ->
   output = "“#{@alien}”"
   if @_?.tag == no then output else @_tagged output

Label::inspect = (ictx = {})->
   output = "“#{@alien}”"

   super ictx, output
Label::inspect = inspectify Label::inspect

# By default, this will print a serialized version of the `Execution`, with `focus` on the current
# `Thing`, and a type-tag. If explicitly invoked with `tag: true`, then the serialized content will
# be omitted; if instead with `serialize: true`, then the tag will be omitted.
#---
# FIXME: Should `Execution` and `Native` do their multi-line debugging-info-printing in `inspect`?
Execution::toString = ->
   Sequence = Paws.parse.Sequence

   if @begin? and not @begin._sequence instanceof Sequence
      @begin._sequence = new Sequence(@begin._sequence.expressions...)

   if @_?.tag != yes or @_?.serialize == yes
      if @complete()
         desc = if @begin? then @begin._sequence.serialize(focus: @_last_completed.valueOf()) + ' ✓'
      else
         desc = if @begin? then @begin._sequence.serialize focus: @current().valueOf()
      output = "{ #{desc ? ''} }"

   if @_?.tag == no or @_?.serialize == yes then output else @_tagged output

Execution::inspect = (ictx = {})->
   # Fail fast if the parser isn't loaded
   Sequence = Paws.parse.Sequence

   if @begin? and not @begin._sequence instanceof Sequence
      @begin._sequence = new Sequence(@begin._sequence.expressions...)

   idt = (ictx.indent ||= @_?.indent or 3)
   if 'number' is typeof idt
      idt = (ictx.indent = new Array(idt + 1).join(' '))

   idt_len = term.strip(idt).length

   ba = (ictx.break_at ||= @_?.break_at or (95 - idt_len))

   if ictx.alien_broke
      if @begin?
         if @complete()
            desc = @begin._sequence.with(tag: no).inspect(ictx, focus: @_last_completed.valueOf())
         else
            desc = @begin._sequence.with(tag: no).inspect(ictx, focus: @current().valueOf())

         desc = desc.replace /^\s+|\s+$/g, ''
         desc = indentString(desc, idt)
         abody = "{\n#{desc + if @complete() then ' ✓' else ''}\n}"
      else
         abody = "{}"

      sub_ictx = _.extend {}, ictx
      super sub_ictx, abody

   else
      # If it keeps it short, we re-serialize instead of keeping the original formatting
      if @complete()
         desc = if @begin? then @begin._sequence.serialize focus: @_last_completed.valueOf()
         abody = "{ #{if desc then desc + ' ✓' else ''} }"
      else
         desc = if @begin? then @begin._sequence.serialize focus: @current().valueOf()
         abody = "{ #{desc || ''} }"

      if term.strip(abody).length >= ba or abody.indexOf("\n") != -1
         ictx.alien_broke = true
         ictx.broke = true
         return @inspect ictx

      sub_ictx = _.extend {}, ictx
      super sub_ictx, abody
Execution::inspect = inspectify Execution::inspect

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

Native::inspect = (ictx = {})->
   output = "FUNCTION"

   super ictx, output
Native::inspect = inspectify Native::inspect

debug "++ Datagraph available"
