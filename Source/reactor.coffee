`                                                                                                                 /*|*/ require = require('../Library/cov_require.js')(require)`
(Paws = require './Paws.coffee').utilities.infect global

module.exports =
reactor = new Object

# At some point, I want to refactor this function (originally, a method of Execution, that I decided
# was more in-kind with the rest of `reactor` instead of with anything implemented within the rest
# of the data-types, and so moved here) to be A) simpler, and B) integrated tighter with the rest of
# the reactor. For now, however, it's a direct port from `µpaws.js`.
advance = (exe)->
   return if @complete()
   
   if this instanceof Alien
      @pristine = no
      return _.bind @bits.shift(), this
   
   # NYI

# This acts as a `Unit`'s store of access knowledge: `Executions` are matched to the `Thing`s they've
# successfully requested a form of access to.
#
# I'd *really* like to see a better data-structure; but my knowledge of such things is insufficient to
# apply a truly appropriate one. For now, just a simple mapping of `Thing`s to accessors (`Executions`).
reactor.Table = Table = class Table
   constructor: ->
      @content = new Array
   
   give: (accessor, thing...)->
      association = _(@content).find [accessor]
      if not association?
         @content.push(association = [accessor, new Array])
      
      association[1].push thing...
      return association
   
   get: (accessor)-> _(@content).find([accessor])?[1]
   
   remove: (accessor)->
      delete @content[ _(@content).findIndex [accessor] ]

# The Unitary design (i.e. distribution) isn't complete, at all. At the moment, a `Unit` is just a
# place to store the action-queue and access-table.
#
# Theoretically, this should be enough to, at least, run two Units *at once*, even if there's
# currently no design for the ways I want to allow them to interact.
# More on that later.
reactor.Unit = Unit = class Unit
   constructor: constructify(return:@) ->
      @queue = new Array
      @table = new Table
   
   # Given some `Thing` roots, flatten out the nodes (more `Thing`s) of the sub-graph ‘owned’ by those
   # roots at the time this function is called into a simple set.
   # 
   # The return-value from this function is an `Array`, but with three added functions:
   # 
   #  - `#concat`: Overriding `Array#concat`, this will add the passed Arrays' elements to this one.
   #  - `#conflictsWith`: Returns `true`, if any `Thing` included by this mask, is also included in any
   #    of the passed masks.
   #  - `#contains`: `true` if *every* `Thing` included by this mask is also incloded in those passed
   @mask: (roots...)->
      recursivelyMask = (mask, root)->
         mask.push root
         _(root.metadata).filter().filter('isResponsible').pluck('to').reduce recursivelyMask, mask
         return mask
      
      mask = _.chain(roots).reduce(recursivelyMask, new Array).uniq().value()
      
      mask.concat =  chain (masks...)-> @push _.flatten(masks)...
      mask.conflictsWith = (masks...)-> _(masks).flatten().some (thing)=> _(this).contains thing
      mask.contains =      (masks...)-> _(this).difference(_.flatten masks).isEmpty()
      return mask

reactor.schedule = 
   reactor.awaitingTicks++
   
   

reactor.awaitingTicks = 0
