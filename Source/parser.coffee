Paws = require './Paws.coffee'

{  Thing, Label, Execution, Native
,  Relation, Combination, Position, Mask
,  debugging, utilities: _                                                                  } = Paws

{  constructify, parameterizable, delegated
,  terminal: term                                                                              } = _

{  ENV, verbosity, is_silent, colour
,  emergency, alert, critical, error, warning, notice, info, debug, verbose, wtf       } = debugging


exports._parser = PARSER =
try
   require '../Library/cPaws-parser.js'
catch e
   warning "!! Compiled parser not found! Dynamically building one from the grammar now ..."
   warning "   (This should have happened on `npm install`. Run that, if you haven't yet.)"
   PEG = require('pegjs'); fs = require('fs'); path = require('path')
   grammar = fs.readFileSync path.join(__dirname, 'cPaws.pegjs'), encoding: 'utf8'
   PEG.buildParser grammar


# Instances of this can be associated with Paws objects (and parser-types) to contextualize them
# with information about ‘where they came from.’
exports.Context = Context =
class Context
   key = '_context'
   # Retreives the `Context` instance, if any, associated with a passed object `it`.
   @for: (it)->          it[key]
   @on:  (it, args...)-> it[key] = Context.apply null, args

   constructor: constructify(return:@) (@text, @begin = 0, @end = @text.length - 1)->

   # These conveniences extract useful portions of the original source-text, with respect to the
   # range encapsulated herein.
   before: -> @text.substring 0, @begin
   source: -> @text.substring @begin, @end + 1
   after:  -> @text.substring @end + 1

# A simple container for a series of sequentially-executed `Expression`s.
exports.Sequence = Sequence =
parameterizable delegated('expressions', Array) class Sequence
   # A convenience method that simply wraps a single result of `Expression#from` in a `Sequence`.
   from: (representation)->
      return new Sequence Expression.from(representation)

   constructor: (@expressions...)->

   # Can either grab an expression out of this sequence (one index passed), or an object out of a
   # specific expression (two indices passed.)
   at: (expr_idx, idx)->
      expression = @expressions[expr_idx]
      return if idx? then expression.at(idx) else expression

# Represents a single expression (or sub-expression). Contains `words`, each of which may be either
# a Paws `Thing`, or an array of sub-`Expression`s. JavaScript strings will be constructed into
# `Label`s.
exports.Expression = Expression =
parameterizable delegated('words', Array) class Expression

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

         return new Sequence Expression.from representation if _.isArray representation
         return new Sequence representation if representation instanceof Expression
         return representation if representation instanceof Sequence

         return Thing.construct representation

      # Array of objects passed; construct an Expression
      it = new Expression
      it.words = _.map representation, (rep)-> node_from rep

      return it

   constructor: constructify(return:@) -> @words = new Array

   at: (idx)-> @words[idx]

# Prepares some raw text for parsing (primarily removing artifacts, such as shebangs.) Returns the
# (possibly modified) text.
exports.prepare = (text)->
   text = text.split("\n").slice(1).join("\n") if text.slice(0,2) == '#!'
   text


parse = (text)->
   context_from = (source_information, object)->
      Context.on object, text, source_information.begin, source_information.end
      return object

   # Translates a given PEG-output node into one of our parser nodes:
   node_from = (representation)->
      switch representation.type
         when 'sequence'
            seq = new Sequence
            seq.expressions = _.map representation, (expr)-> node_from expr
            seq.expressions.push new Expression unless seq.expressions.length
            context_from representation.source, seq

         when 'expression'
            expr = new Expression
            expr.words      = _.map representation, (word)-> node_from word
            context_from representation.source, expr

         when 'label'
            label = new Label representation.string
            context_from representation.source, label

         when 'execution'
            execution = new Execution node_from representation.sequence
            context_from representation.source, execution

   try intermediate = PARSER.parse(text)
   catch parser_error
      err = new SyntaxError
      err.message = parser_error.message
      throw err

   node_from intermediate


# Attempt to construct a canonical-Paws representation of this node.
#---
# XXX: This defaults-syntax is fucking dumb. Patch CoffeeScript.
# TODO: Pretty-print the output. (Newlines, etc.)
Expression::serialize = ({focus: focus} = {})->
   words = @words.map (word)->

      if word instanceof Label
         str = word.alien
         has =
            straight: /"/              .test(str),
            curly:    /[“”]/           .test(str),
            others:   /[{}\[\];\s]/    .test(str)

         if     (has.others or has.straight) and not has.curly    then str = '“'+str+'”'
         else if has.curly and not has.straight                   then str = '"'+str+'"'
         else if has.curly and has.straight
            throw new SyntaxError "Unserializable label: "+word.inspect()+"!"

      if word instanceof Sequence
         str = '['+word.serialize(focus: focus)+']'

      if word == focus then term.em str else str

   output = words.join ' '
   if this == focus then term.em output else output

Sequence::serialize = ({focus: focus} = {})->
   ser = (expr)-> expr.serialize focus: focus
   output = @expressions.map(ser, []).join '; '
   if this == focus then term.em output else output

Sequence::toString =
#---
# @param  {...!?!?} focus:
#    If included, a `focus` node can be hilighted within the serialized string. (However, the
#    passed object or Sequence/Expression must have originated from the same Script!)
# @option {boolean=false} context:
#    Include the entire parse-time Script (if available), instead of just `this` element.
#    environment-variable, though.)
# @option {boolean=true} tag:
#    Include the <Type ...> tagging around the output.
Expression::toString = ({focus: focus} = {})->
   context = Context.for this
   contents = context?.source() or @serialize {focus: focus}

   if context
      if focus
         f = Context.for focus

         if context and f.text == context.text and f.begin >= context.begin and f.end <= context.end
            length = f.end - f.begin
            start  = f.begin - context.begin
            end    = start + length

            c = new Context contents, start, end
            contents = c.before() + term.em(c.source()) + c.after()

      if (lines = @_?.context) > 0
         if not focus
            contents = term.em contents

         before = context.before()
         after  = context.after()
         if lines != yes
            before   = before.split("\n").slice(- @_?.context) .join("\n")
            after    = after .split("\n").slice(0, @_?.context).join("\n")

         contents = before + contents + after

   if @_?.tag == no then contents else Thing::_tagged.call this, contents


_.extend (module.exports = parse), exports
info "++ Parser available"
