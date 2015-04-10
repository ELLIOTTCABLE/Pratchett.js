require('./utilities.coffee').infect global

{EventEmitter} = require 'events'

Paws = require './Paws.coffee'
infect global, Paws

# FIXME: Refactor this entire thing to use isaacs' `node-tap`

module.exports = Rule = class Rule extends Thing
   
   @construct: (schema)->
      return null unless schema.name? or schema.body?
      name = new Label schema.name ? '<untitled>'
      body = if schema.body
         Paws.generateRoot schema.body, name
      else new Native -> rule.NYI()
      
      # XXX: Each rule in its own Unit?
      rule = new Rule {unit: new reactor.Unit}, name, body
      if schema.eventually
         rule.eventually switch schema.eventually
            when 'pass' then new Native -> rule.pass()
            when 'fail' then new Native -> rule.fail()
            
            # Not generateRoot'd, because we replace this Execution's locals with the body's locals
            # when it's invoked.
            else             new Execution Paws.parse schema.eventually
      
      return rule
   
   #---
   # NOTE: Expects an environment similar to Execution.synchronous's `this`. Must contain `.unit`,
   #       and may contain `.caller`.
   constructor: constructify(return:@) ({@caller, @unit}, @title, @body, collection = Collection.current())->
      @title = new Label @title unless @title instanceof Label
      
      if @caller?
         @body.locals = @caller.clone().locals
      
      @body.locals.inject primitives.generate_block_locals this
      this        .inject primitives.generate_members this if @caller
      
      collection.push this if collection
   
   maintain_locals: (@locals)->
      @body.locals.inject @locals
   
   dispatch: ->
      return if @dispatched
      Paws.notice '-- Dispatching:', Paws.inspect this
      @dispatched = true
      @unit.once 'flushed', => @flushed = true
      @unit.once 'flushed', @eventually_listener if @eventually_listener?
      @unit.stage @body
   
   pass: -> @status = true;  @complete()
   fail: -> @status = false; @complete()
   NYI:  -> @status = 'NYI'; @complete()
   
   complete: ->
      Paws.info "-- Completed (#{@status}):", Paws.inspect this
      @unit.removeListener 'flushed', @eventually_listener if @eventually_listener?
      @emit 'complete', @status
      @on 'newListener', (eve, listener)=> if eve is 'complete' then listener.call this, @status
   
   # FIXME: repeated calls?
   eventually: (block)->
      block.locals.inject @body.locals
      
      if not @flushed
         Paws.info "-- Registering 'eventually' for ", Paws.inspect this
         @eventually_listener = =>
            Paws.info "-- Firing 'eventually' for ", Paws.inspect this
            @unit.stage block, undefined
         @unit.once 'flushed', @eventually_listener if @dispatched
      
      else
         Paws.info "-- Immediately firing 'eventually' for already-flushed ", Paws.inspect this
         @unit.stage block, undefined
   
   
Rule.Collection = Collection = class Collection extends EventEmitter
   
   # Construct a Collection (and member Rules) from an array of rule-structures (usually from a
   # Rulebook / YAML file.)
   #
   # Example:
   #     [{ name: 'a test',
   #        body: "implementation void[] [pass[]]"
   #        eventually: 'fail' },
   #      ... ]
   #---
   # TODO: Nested Collections
   @from: (schemas)->
      collection = new Collection
      collection.rules = _.filter _.map schemas, (schema)-> Rule.construct schema
      return collection
   
   _current = undefined
   @current: -> _current ?= new Collection
   
   # Creates a new `Collection`. If this is the first `Collection` created, it becomes the default
   # collection for new `Rules`.
   #---
   # FIXME: WHY IS THIS DESTRUCTURING PARAMETER SO FUCKING UGLY, COFFEESCRIPT!?
   constructor: ({output: @stream} = {})->
      @stream ?= process.stdout
      
      @rules = new Array
      @completed = 0
      @activate() unless _current
   
   # Make this `Collection` the `current` collection (meaning newly created `Rules` will be added
   # to it, by default.)
   activate: -> _current = this unless @closed
   
   # Add new `Rules` to this `Collection`. If the collection is already set to `dispatch` rules,
   # then the newly added rules will be dispatched; however, if it has instead been `close()d`, then
   # this method has no effect.
   push: (rules...)->
      return false if @closed
      
      _.map rules, (rule)=>
         @rules.push rule
         @_dispatch rule
   
   # When called, starts `dispatch`ing each `Rule` belonging to the `Collection`. In addition, after
   # this has been called, any rules added will be immediately dispatched.
   #
   # When a dispatched `Rule` completes, it is reported (a TAP line-entry is printed) if reporting
   # is active; and if it is the last rule in the `Collection` to do so (requiring that the
   # collection be `close()d`, obviously), then the collection is completed as well (printing the
   # TAP ‘plan’ line.)
   dispatch: ->
      @dispatching = true
      _.map @rules, (rule)=> @_dispatch rule
   
   # A `Collection` is capable of printing ‘TAP’ (Test-Anything Protocol) reports on the rules being
   # executed. Calling `report()` enables that feature (which requires either that an output stream
   # be passed to the `Collection` constructor, or that it be left undefined to default to zero.)
   # 
   # When called, each previously-completed `Rule` in the `Collection` will have a TAP line printed
   # for it; and any rules added (or completed) later will immediately print further TAP lines.
   # 
   # Upon completion of the entire `Collection` (when it has been `close()d`, and all added `Rules`
   # have completed), a final TAP ‘plan’ line will be printed, informing the test-harness that
   # testing has completed.
   report: ->
      @dispatch()
      return unless @stream
      
      @reporting = true
      @stream.write "TAP version 13\n"
      _.map @rules, (rule)=>
         if rule.status? then @_report rule
      
      @_untap()
   
   # Once `close()d`, a `Collection` will accept no further `Rules`, and will emit `complete` when
   # all those rules already added themselves `complete()`.
   close: ->
      @closed = true
      _current = undefined if this is _current
      @dispatch() unless @dispatching
      @_complete() if @completed == @rules.length
   
   
   _dispatch: (rule)-> if @dispatching
      rule.once 'complete', (status)=> unless rule._completed
         rule._completed = true
         Paws.debug "-- Completed Rule within Collection"
         @completed++
         @status = status && (@status ? true)
         @_report rule if @reporting
         @emit 'rule', rule
         
         @close() if @closed
      
      rule.dispatch()
   
   # Prints a line for a completed rule.
   _report: (rule)->
      return unless @stream
      
      number =  @rules.indexOf(rule) + 1
      [status, directive] = switch rule.status
         when true      then ['ok']
         when 'NYI'     then ['ok', 'TODO']
         when false     then ['not ok']
         else                ['not ok', rule.status]
      
      title = rule.title.alien
      title = ['#', directive, title].join ' ' if directive
      @stream.write "#{status} #{number} #{title}\n"
   
   # This will close the suite, outputting no more TAP and dispatching no further tests. It will
   # also print the TAP 'plan' line, telling the harness how many tests were run.
   _complete: ->
      @_untap() if @reporting
      @emit 'complete', @status
      @on 'newListener', (eve, listener)=> if eve is 'complete' then listener.call this, @status
   
   _untap: ->
      if @closed and @completed == @rules.length
         @stream.write "1..#{@rules.length}\n" if @stream

# Fucking Node.js. ಠ_ಠ
primitives = require('./primitives/specification.coffee')
