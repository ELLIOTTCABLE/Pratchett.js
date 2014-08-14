`                                                                                                                 /*|*/ require = require('../Library/cov_require.js')(require)`
Paws = require './data.coffee'

try
   parser = require '../Library/cPaws-parser.js'
catch e
   Paws.warning "!! Compiled parser not found! Dynamically building one from the grammar now ..."
   Paws.warning "   (This should have happened on `npm install`. Run that, if you haven't yet.)"
   PEG = require('pegjs'); fs = require('fs'); path = require('path')
   grammar = fs.readFileSync path.join(__dirname, 'cPaws.pegjs'), encoding: 'utf8'
   parser = PEG.buildParser grammar


# This can either be inherited from by node-y types (see below), or an instance of it can be created
# to wrap around raw data-types. In either case, that data can then be contextualized by its
# location in some original source-code, as well as the exact source-code used to generate it.
#---
# TODO: This'd be a nicer API if we had a dynamic on-construction version of delegated()
exports.HasSource = HasSource =
class HasSource
   @unwrap: (it)->
      if it instanceof HasSource and it.hasOwnProperty 'value' then return it.value else return it
   
   constructor: constructify(return:@) (@value)->
   
   # This contextualizes the wrapped `value` with source information.
   from: (@source_text, @source_begin = 0, @source_end = @source_text.length - 1)->
   
   # These conveniences extract useful portions of the original source-text, with respect to the
   # range encapsulated herein.
   source_before: -> @source_text.substring 0, @source_begin
   source_of:     -> @source_text.substring @source_begin, @source_end
   source_after:  -> @source_text.substring @source_end

# A simple container for a series of sequentially-executed `Expression`s.
exports.Sequence = Sequence =
delegated('expressions', Array) class Sequence extends HasSource
   constructor: (@expressions...)->
   
   at: (idx)-> HasSource.unwrap @expressions[idx]

# Represents a single expression (or sub-expression). Contains `words`, each of which may be either
# a Paws `Thing`, or an array of sub-`Expression`s. JavaScript strings will be constructed into
# `Label`s.
exports.Expression = Expression =
delegated('words', Array) class Expression extends HasSource
   
   # Convenience function to construct an `Expression` from a simple JavaScript-object
   # representation thereof. Given an array of `Thing`s (or JavaScript objects, which are
   # constructed into `Thing`s as appropriate), this will return an `Expression` of those in
   # sequence. If arrays are included therein, they will be constructed into sub-`Expression`s:
   #     
   #     // `<thing a> <thing b>`
   #     Expression.from [new Thing, new Thing]
   #     
   #     // `foo bar`
   #     Expression.from [new Label('foo'), new Label('bar')]
   #     // or
   #     Expression.from ['foo', 'bar']
   #
   #     // `foo [bar baz]`
   #     Expression.from ['foo', ['bar', 'baz']]
   #     
   # Note that that cannot be used to represent sequences-of-`Expression`s (i.e. semicolon-seperated
   # expressions). Each generated sub-`Expression` will have only one `Expression`; for more complex
   # constructions, you can nest calls to this:
   #     
   #     // Constructs an analogue of `foo bar [a; b] baz`
   #     Expression.from ['foo', 'bar', [Expression.from 'a', Expression.from 'b'] 'baz']
   #     // which is equivalent to,
   #     Expression.from ['foo', 'bar', new Sequence(Expression.from 'a', Expression.from 'b'), 'baz']
   @from: (representation)->
      node_from = (representation)->
         return new Label representation if typeof representation == 'string'
         return representation if representation instanceof Thing
         
         if representation instanceof HasSource
            representation.value = node_from representation.value
            return representation
         
         return new Sequence Expression.from representation if _.isArray representation
         return new Sequence representation if representation instanceof Expression
         return representation if representation instanceof Sequence
         
         return Thing.construct representation
      
      # Array of objects passed; construct an Expression
      it = new Expression
      it.words = _.map representation, (rep)-> node_from rep
      
      return it
   
   constructor: -> @words = new Array
   
   at: (idx)-> HasSource.unwrap @words[idx]


parse = ->
   

module.exports = parse
Paws.utilities.infect module.exports, exports
