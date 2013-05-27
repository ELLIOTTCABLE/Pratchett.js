`require = require('../Source/cov_require.js')(require)`
expect = require 'expect.js'

describe 'Parser', ->
  parser = require "../Source/parser.coffee"

  it 'should be defined', ->
    expect(parser).to.be.ok()
    expect(parser.parse).to.be.a('function')
    expect(parser.Expression).to.be.ok()

