`require = require('../Source/cov_require.js')(require)`
expect = require 'expect.js'
Paws = require '../Source/Paws.coffee'

describe 'Parser', ->
  parser = require "../Source/parser.coffee"

  it 'should be defined', ->
    expect(parser).to.be.ok()
    expect(parser.parse).to.be.a('function')
    expect(parser.Expression).to.be.ok()

  it 'should parse a label', ->
    ast = parser.parse('hello')
    expect(ast).to.be.ok()
    expect(ast).to.be.a(Paws.Label)
    expect(ast.alien.toString()).to.be('hello')

