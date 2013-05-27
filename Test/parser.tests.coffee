`require = require('../Source/cov_require.js')(require)`
expect = require 'expect.js'
Paws = require '../Source/Paws.coffee'

describe 'Parser', ->
  parser = require "../Source/parser.coffee"

  it 'should be defined', ->
    expect(parser).to.be.ok()
    expect(parser.parse).to.be.a('function')
    expect(parser.Expression).to.be.ok()

  it 'should parse nothing', ->
    expr = parser.parse('')
    expect(expr).to.be.ok()
    expect(expr).to.be.a(parser.Expression)
    expect(expr.contents).to.be(undefined)
    expect(expr.next).to.be(undefined)

  it 'should parse a label expression', ->
    expr = parser.parse('hello').next
    expect(expr.contents).to.be.a(Paws.Label)
    expect(expr.contents.alien.toString()).to.be('hello')

  it 'should parse multiple labels', ->
    expr = parser.parse('hello world').next
    expect(expr.contents).to.be.a(Paws.Label)
    expect(expr.contents.alien.toString()).to.be('hello')
    expect(expr.next.contents).to.be.a(Paws.Label)
    expect(expr.next.contents.alien.toString()).to.be('world')

