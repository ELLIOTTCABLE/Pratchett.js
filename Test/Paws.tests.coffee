`require = require('../Source/cov_require.js')(require)`
expect = require 'expect.js'

# TODO: Replace all the 'should' language with more direct 'will' language
#       (i.e. “it should return ...” becomes “it returns ...”
describe 'The Paws API:', ->
   Paws = require "../Source/Paws.coffee"
   it 'should be defined', ->
      expect(Paws).to.be.ok()
   
   describe 'Thing', ->
      Thing = Paws.Thing
      
      describe 'Relation', ->
         Relation = Paws.Relation
         
         describe '##from', ->
            it 'should return the passed value if it is already a Relation', ->
               rel = new Relation(new Thing)
               expect(Relation.from rel).to.be rel
            it 'should return a relation *to* the passed value if not', ->
               thing = new Thing
               expect(Relation.from thing).to.be.a Relation
               expect(Relation.from(thing).to).to.be thing
            
            it 'should ensure all elements of a passed array are Relations', ->
               thing1 = new Thing; thing2 = new Thing; thing3 = new Thing
               array = [thing1, new Relation(thing2), thing3]
               expect(Relation.from array).to.be.an 'array'
               expect(Relation.from(array).every (el) -> el instanceof Relation).to.be.ok()
            
            it 'should be able to change the responsibility of relations', ->
               thing1 = new Thing; thing2 = new Thing; thing3 = new Thing
               array = [thing1, new Relation(thing2, false), new Relation(thing3, true)]
               expect( # TODO: This could be cleaner.
                  Relation.with(responsible: yes).from(array).every (el) -> el.isResponsible
               ).to.be.ok()
               
         
         describe '#clone', ->
            it 'should return a new Relation', ->
               rel = new Relation(new Thing, true)
               expect(rel.clone()).to.not.be rel
               expect(rel.clone().to).to.be rel.to
               expect(rel.clone().isResponsible).to.be rel.isResponsible
         
         it 'should default to being irresponsible', ->
            expect((new Relation).isResponsible).to.be false
         
      uuid_regex = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
      it 'should have a UUID', ->
         expect((new Thing).id).to.match uuid_regex
      
      it 'should noughtify the metadata by default', ->
         thing = new Thing
         expect(thing.metadata).to.have.length 1
         expect(thing.metadata[0]).to.be undefined
         
         bare_thing = new Thing.with(noughtify: no)()
         expect(bare_thing.metadata).to.have.length 0
      
      it 'should store metadata relations', ->
         child1 = new Thing; child2 = new Thing
         thing = new Thing child1, child2
         expect(thing).to.have.property 'metadata'
         expect(thing.metadata).to.be.an 'array'
         expect(thing.metadata[1]).to.be.a Paws.Relation
         expect(thing.metadata[1].to).to.be child1
         expect(thing.metadata[2]).to.be.a Paws.Relation
         expect(thing.metadata[2].to).to.be child2
