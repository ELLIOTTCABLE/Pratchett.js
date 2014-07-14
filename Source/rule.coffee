`                                                                                                                 /*|*/ require = require('../Library/cov_require.js')(require)`
require('./utilities.coffee').infect global

Paws = require './Paws.coffee'
infect global, Paws

module.exports = Rule = class Rule extends Thing
   #---
   # NOTE: Expects an @environment similar to Execution.synchronous's `this`. Must contain .caller
   #       and .unit.
   constructor: constructify(return:@) (@environment, @title, @body, @collection = Collection.current())->
      @title = new Label @title unless @title instanceof Label
      @body.locals = @environment.caller.locals.clone()
      @collection.push this
   
   maintain_locals: (@locals)->
      @body.locals.inject @locals
   
   dispatch: ->
      @environment.unit.once 'flushed', @eventually_listener if @eventually_listener?
      @environment.unit.stage @body
   
   pass: -> @status = true;  @complete()
   fail: -> @status = false; @complete()
   
   complete: ->
      @environment.unit.removeListener 'flushed', @eventually_listener if @eventually_listener?
      @emit 'complete', @status
   
   # FIXME: repeated calls?
   eventually: (block)->
      block.locals.inject @locals if @locals?
      @eventually_listener = =>
         @environment.unit.stage block, undefined
   
Rule.Collection = Collection = class Collection
   
   _current = undefined
   @current: -> _current ?= new Collection
   
   constructor: -> @rules = new Array
   
   push: (rules...)->
      _.map rules, (rule)=>
         rule.once 'complete', => @report rule, 
         @rules.push rule
   
   # Prints a line for a completed rule.
   report: (rule)-> if not @done
      number = @rules.indexOf(rule) + 1
      status = switch rule.status
         when true      then 'ok'
         when false     then 'not ok'
         when 'pending' then 'not ok'
         else           rule.status
      directive = " # TODO" if rule.status == 'pending'
      
      process.stdout.write "#{status} #{number} #{rule.title.alien}#{directive||''}\n"
