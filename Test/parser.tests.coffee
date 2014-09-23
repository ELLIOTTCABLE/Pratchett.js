`                                                                                                                 /*|*/ require = require('../Library/cov_require.js')(require)`
expect = require 'expect.js'

Paws  = require '../Source/Paws.coffee'
parse = require "../Source/parser.coffee"

describe 'Parser', ->
   it 'exists', ->
      expect(parse).to.be.ok()
      expect(parse).to.be.a 'function'
   
   Sequence    = parse.Sequence
   Expression  = parse.Expression
   Context     = parse.Context
   
   describe 'Context', ->
      it 'exists', ->
         expect(Context).to.be.ok()
         expect(Context).to.be.a 'function'
         
         expect(-> new Context).to.not.throwException()
         expect(   new Context).to.be.a Context
      
      it 'can associate an instance of itself with any object', ->
         an_object = new Object; another_object = new Object
         
         expect(-> Context.on an_object, 'abc').to.not.throwException()
         expect(   Context.on an_object, 'abc').to.be.a Context
      
      it 'can be retreived from an object', ->
         an_object = new Object; some_text = 'abc'
         
         Context.on an_object, some_text
         expect(-> Context.for an_object).to.not.throwException()
         expect(   Context.for an_object).to.be.a Context
         expect(   Context.for(an_object).text).to.be some_text
      
      it 'can store a range within the source-text', ->
         an_object = new Object; some_text = 'abc def ghi'
         
         Context.on an_object, some_text, 4, 7
         expect(Context.for(an_object).source()).to.be 'def'
      
      it 'can retreive the text *before* the source', ->
         an_object = new Object; some_text = 'abc def ghi'
         
         Context.on an_object, some_text, 4, 7
         expect(Context.for(an_object).before()).to.be 'abc '
      
      it 'can retreive the text *after* the source', ->
         an_object = new Object; some_text = 'abc def ghi'
         
         Context.on an_object, some_text, 4, 7
         expect(Context.for(an_object).after()).to.be ' ghi'
   
   describe 'Expression', ->
      it 'exists', ->
         expect(Expression).to.be.ok()
         expect(Expression).to.be.a 'function'
         
         expect(-> new Expression).to.not.throwException()
         expect(   new Expression).to.be.a Expression
      
      it "contains Things as 'words'", ->
         a_thing = new Thing
         
         expr = new Expression.from [a_thing]
         expect(expr).to.be.a Expression
         expect(expr.words).to.have.length 1
         expect(expr.words).to.eql [a_thing]
      
      it 'constructs Strings into Label-words', ->
         a_label = 'foo'
         
         expr = new Expression.from [a_label]
         expect(expr).to.be.a Expression
         expect(expr.words).to.have.length 1
         expect(expr.at 0       ).to.be.a Label
         expect(expr.at(0).alien).to.be a_label
      
      it 'can create sub-expressions', ->
         expect(-> new Expression.from ['foo', ['bar'], 'baz']).to.not.throwException()
   
      it 'creates a Sequence to wrap sub-expressions', ->
         expr = new Expression.from [['bar']]
         expect(expr).to.be.a Expression
         expect(expr.words).to.have.length 1
         expect(expr.at 0).to.be.a Sequence
   
      it 'recurses to create contents of sub-expressions', ->
         a_thing = new Thing
         
         expr = new Expression.from ['foo', [a_thing], 'baz']
         expect(expr).to.be.a Expression
         expect(expr.words).to.have.length 3
         expect(expr.at 1).to.be.a Sequence
         
         sub = expr.at(1).at(0)
         expect(sub).to.be.an Expression
         expect(sub.at 0).to.be a_thing
   
   describe 'parses ...', ->
      it.skip 'nothing', ->
         expr = parse('')
         
         expect(expr).to.be.ok()
         expect(expr).to.be.a(parse.Expression)
