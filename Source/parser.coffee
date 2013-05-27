`require = require('./cov_require.js')(require)`
Paws = require './Paws.coffee'

class Expression
  constructor: (@contents, @next) ->
  
  append: (expr) ->
    curr = this
    curr = curr.next while curr.next
    curr.next = expr

class Parser
  labelCharacters = /[^(){} \n]/ # Not currently supporting quote-delimited labels

  constructor: (@text) ->
    @i = 0

  character: (char) ->
    @text[@i] is char && ++@i

  whitespace: ->
    true while @character(' ') || @character('\n')
    true

  label: ->
    @whitespace()
    start = @i
    res = ''
    while @text[@i] && labelCharacters.test(@text[@i])
      res += @text[@i++]
    res && new Paws.Label(res)

  braces: (delim, constructor) ->
    start = @i
    if @whitespace() &&
        @character(delim[0]) &&
        (it = @expr()) &&
        @whitespace() &&
        @character(delim[1])
      new constructor(it)

  paren: -> @braces('()', (it) -> it)

  expr: ->
    res = new Expression
    while sub = (@label() || @paren())
      res.append(new Expression(sub))
    res

  parse: ->
    @expr()

module.exports =
  parse: (text) ->
    parser = new Parser(text)
    parser.parse()
  
  Expression: Expression

