`require = require('../Source/cov_require.js')(require)`
expect = require 'expect.js'

describe 'The Paws API:', ->
   Paws = require "../Source/Paws.coffee"
   it 'should be defined', ->
      expect(Paws).to.be.ok()
   
   describe 'Thing', ->
      Thing = Paws.Thing
      
      uuid_regex = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
      it 'should have a UUID', ->
         expect((new Thing).id).to.match uuid_regex
      
      it 'should have metadata', ->
         thing = new Thing
         expect(thing).to.have.property 'metadata'
         expect(thing.metadata).to.be.an 'array'
      it 'should noughtify the metadata by default', ->
         thing = new Thing
         expect(thing.metadata).to.have.length 1
         expect(thing.metadata[0]).to.be undefined
         
         bare_thing = new Thing.with(noughtify: no)()
         expect(bare_thing.metadata).to.have.length 0
