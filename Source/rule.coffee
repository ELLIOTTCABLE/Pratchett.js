require('./utilities.coffee').infect global

Paws = require './Paws.coffee'
infect global, Paws

# FIXME: Refactor this entire thing to use isaacs' `node-tap`

module.exports = Rule = class Rule extends Thing
   
   @construct: (schema)->
      return null unless schema.name? or schema.body?
      name = new Label schema.name ? '<untitled>'
      body = if schema.body
           new Execution Paws.parse schema.body
      else new Native -> rule.NYI()
      
      # XXX: Each rule in its own Unit?
      rule = new Rule {unit: new reactor.Unit}, name, body
      if schema.eventually
         rule.eventually switch schema.eventually
            when 'pass' then new Native -> rule.pass()
            when 'fail' then new Native -> rule.fail()
            else             new Execution Paws.parse schema.eventually
      
      return rule
   
   #---
   # NOTE: Expects an environment similar to Execution.synchronous's `this`. Must contain `.unit`,
   #       and may contain `.caller`.
   constructor: constructify(return:@) ({@caller, @unit}, @title, @body, collection = Collection.current())->
      @title = new Label @title unless @title instanceof Label
      
      if @caller?
         @body.locals = @caller.clone().locals
      else
         @body.locals.inject Paws.primitives 'infrastructure'
         @body.locals.inject Paws.primitives 'implementation'
      
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
   
   
Rule.Collection = Collection = class Collection
   
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
   
   # FIXME: WHY IS THIS DESTRUCTURING PARAMETER SO FUCKING UGLY, COFFEESCRIPT!?
   constructor: ({output: @stream} = {})->
      @stream ?= process.stdout
      
      @rules = new Array
      @activate() unless _current?
   
   activate: -> _current = this
   
   push: (rules...)->
      _.map rules, (rule)=>
         rule.once('complete', => @print rule) if @reporting
         @rules.push rule
         rule.dispatch() if @dispatching
   
   dispatch: ->
      @dispatching = true
      _.map @rules, (rule)=> rule.dispatch()
   
   report: ->
      return unless @stream
      
      @reporting = true
      @stream.write "TAP version 13\n"
      _.map @rules, (rule)=>
         if rule.status? then @print rule
         else rule.once 'complete', => @print rule
   
   # This will close the suite, outputting no more TAP and dispatching no further tests. It will
   # also print the TAP 'plan' line, telling the harness how many tests were run.
   #---
   # FIXME: Tests *already dispatched* might output after this is called.
   # XXX: Vaguely convinced this is un-asynchronous. o_O
   complete: ->
      @dispatching = false
      @reporting = false
      @stream.write "1..#{@rules.length}\n" if @stream
   
   # Prints a line for a completed rule.
   print: (rule)->
      return unless @stream
      
      number = @rules.indexOf(rule) + 1
      status = switch rule.status
         when true      then 'ok'
         when false     then 'not ok'
         when 'NYI'     then 'not ok'
         else           rule.status
      directive = "# TODO " if rule.status == 'NYI'
      
      @stream.write "#{status} #{number} #{directive||''}#{rule.title.alien}\n"

# Fucking Node.js. ಠ_ಠ
primitives = require('./primitives/specification.coffee')
