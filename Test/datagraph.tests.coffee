support = require './support.coffee'
util    = require '../Source/utilities.coffee'

assert  = require 'assert'
sinon   = require 'sinon'
expect  = require('sinon-expect').enhance require('expect.js'), sinon, 'was'

# TODO: Replace all the 'should' language with more direct 'will' language
#       (i.e. “it should return ...” becomes “it returns ...”
describe "Paws' Data types:", ->
   Paws = require "../Source/Paws.coffee"

   {  Thing, Label, Execution, Native, parse
   ,  Relation, Combination, Position, Mask, Operation } = Paws

   {  Context, Sequence, Expression } = parse

   describe 'Thing', ->

      describe 'Relation', ->
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

            it 'should be able to change the ownership of relations', ->
               thing1 = new Thing; thing2 = new Thing; thing3 = new Thing
               array = [thing1, new Relation(thing2, false), new Relation(thing3, true)]
               expect( # TODO: This could be cleaner.
                  Relation.with(own: yes).from(array).every (el) -> el.owns
               ).to.be.ok()

         it 'should default to non-owning', ->
            expect((new Relation).owns).to.be false

         describe '#clone', ->
            it 'should return a new Relation', ->
               rel = new Relation(new Thing, yes)
               expect(rel.clone()).to.not.be rel
               expect(rel.clone().to).to.be rel.to
               expect(rel.clone().owns).to.be rel.owns

      describe '##construct', ->
         it 'should construct a Thing', ->
            a_thing = new Thing
            expect(Thing.construct {foo: a_thing}).to.be.a Thing

         it 'should construct Things with a noughty', ->
            constructee = Thing.construct {foo: new Thing}
            expect(constructee.at 0).to.be undefined

         it 'should construct Things with pairs', ->
            a_thing = new Thing
            constructee = Thing.construct {foo: a_thing}
            expect(constructee.metadata).to.have.length 2

            pair = constructee.at 1
            expect(pair     ).to.be.a Thing
            expect(pair.at 1).to.be.a Label
            expect(pair.at 2).to.be a_thing

         it 'should construct multiple pairs', ->
            thing_1 = new Thing; thing_2 = new Thing
            constructee = Thing.construct {foo: thing_1, bar: thing_2}
            expect(constructee.metadata).to.have.length 3
            expect(constructee.find('foo')[0].valueish()).to.be thing_1
            expect(constructee.find('bar')[0].valueish()).to.be thing_2

         it 'should flag the construct as owning its pairs', ->
            constructee = Thing.construct {something: new Thing}
            expect(constructee.metadata[1]).to.be.owned()

         it 'should flag the construct as owning its members, by default', ->
            constructee = Thing.construct {something: new Thing}
            expect(constructee.find('something')[0].metadata[2]).to.be.owned()

         it "should accept an option to create structures that don't own their members", ->
            constructee = Thing.with(own: no).construct {something: new Thing}
            expect(constructee.metadata[1]).to.be.owned()
            expect(constructee.find('something')[0].metadata[2]).to.not.be.owned()

         it 'generates nested Things', ->
            constructee = Thing.construct { foo: { bar: {baz: something = new Thing} } }

            first_pair = constructee.at 1
            expect(first_pair               ).to.be.a Thing
            expect(first_pair.keyish().alien).to.be 'foo'
            expect(first_pair.valueish()    ).to.be.a Thing

            second_pair = first_pair.valueish().at 1
            expect(second_pair               ).to.be.a Thing
            expect(second_pair.keyish().alien).to.be 'bar'
            expect(second_pair.valueish()    ).to.be.a Thing

            third_pair = second_pair.valueish().at 1
            expect(third_pair               ).to.be.a Thing
            expect(third_pair.keyish().alien).to.be 'baz'
            expect(third_pair.valueish()    ).to.be something

         it 'passes Functions to Native.synchronous', ->
            constructee = Thing.construct {foo: new Function}
            expect(constructee.metadata).to.have.length 2

            pair = constructee.at 1
            expect(pair     ).to.be.a Thing
            expect(pair.at 1).to.be.a Label
            expect(pair.at 2).to.be.an Execution

      describe '##pair', ->
         it.skip 'should be tested...'

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
         expect(thing.metadata[1]).to.be.a Relation
         expect(thing.metadata[1].to).to.be child1
         expect(thing.metadata[2]).to.be.a Relation
         expect(thing.metadata[2].to).to.be child2

      describe '#clone', ->
         it 'should return a new Thing', ->
            thing = new Thing
            expect(thing.clone()).to.not.be thing
         it 'should have identical metadata', ->
            thing = new Thing new Thing, new Thing, new Thing
            clone = thing.clone()
            expect(clone.metadata).to.have.length 4
            thing.metadata.forEach (rel, i) -> if rel
               expect(clone.at i).to.be.ok()
               expect(rel).not.to.be clone.metadata[i]
               expect(rel.to).to.be clone.metadata[i].to
         it 'should apply new metadata to any passed Thing', ->
            thing1 = new Thing new Thing, new Thing, new Thing
            thing2 = new Thing new Thing
            old_metadata = thing2.metadata

            result = thing1.clone(thing2)
            expect(result).to.be thing2
            expect(thing2.metadata).to.not.be old_metadata

      describe '#toArray', ->
         it 'reduces Things to an Array'
         it 'excludes the noughty by default'
         it 'maintains indices'
         it 'contains Things, not the Relation members of the Thing'

      it 'compares by identity', ->
         thing1 = new Label 'foo'
         thing2 = new Label 'foo'

         expect(Thing::compare.call thing1, thing1).to.be     true
         expect(Thing::compare.call thing1, thing2).to.not.be true



      # FIXME: Seperate JavaScript-side convenience API tests from algorithmic tests
      describe '#find', ->
         first = new Thing; second = new Thing; third = new Thing
         foo_bar_foo = new Thing Thing.pair('foo', first),
                                 Thing.pair('bar', second),
                                 Thing.pair('foo', third)

         it 'should return an array ...', ->
            expect(foo_bar_foo.find Label 'foo').to.be.an 'array'
         it '... of result-Things ...', ->
            expect(foo_bar_foo.find(Label 'foo').length).to.be.greaterThan 0
            foo_bar_foo.find(Label 'foo').forEach (result) ->
               expect(result).to.be.a Thing
         it '... that only contains matching pairs ...', ->
            expect(foo_bar_foo.find Label 'foo').to.have.length 2
         it '... in reverse order', ->
            expect(foo_bar_foo.find(Label 'foo')[0].valueish()).to.be third
            expect(foo_bar_foo.find(Label 'foo')[1].valueish()).to.be first

         it 'should handle non-pair Things gracefully', ->
            thing = new Thing Thing.pair('foo', first),
                              new Thing,
                              Thing.pair('bar', second),
                              Thing.pair('foo', third)
            expect(thing.find Label 'foo').to.have.length 2

         it 'should accept JavaScript primitives', ->
            expect(foo_bar_foo.find 'foo').to.have.length 2


   describe 'Mask', ->
      describe '#flatten', ->
         it 'should always return at least the root', ->
            a_mask = new Mask(a_thing = new Thing)
            expect(a_mask.flatten()).to.contain a_thing

         it 'should include anything owned by that root', ->
            [a_thing, another_thing] = [new Thing, new Thing]
            a_mask = new Mask Thing.construct {something: a_thing, something_else: another_thing}
            expect(a_mask.flatten()).to.contain a_thing
            expect(a_mask.flatten()).to.contain another_thing

         it 'should include anything owned, recursively, by that roots', ->
            [a_thing, another_thing] = [new Thing, new Thing]
            parent_thing = Thing.construct {something: a_thing, something_else: another_thing}
            a_mask = new Mask Thing.construct {child: parent_thing}
            expect(a_mask.flatten()).to.contain parent_thing
            expect(a_mask.flatten()).to.contain a_thing
            expect(a_mask.flatten()).to.contain another_thing

      # FIXME: This is insufficiently exercised.
      describe '#conflictsWith', ->
         it 'should indicate whether passed a mask currently contains some of the same items', ->
            a_mask = new Mask Thing.construct(things = {a: new Thing, b: new Thing})
            expect(a_mask.conflictsWith new Mask things.a).to.be true
            expect(a_mask.conflictsWith new Mask new Thing).to.be false

      describe '#containedBy', ->
         it 'should return true if the only item is contained by a passed Mask', ->
            a_mask       = new Mask Thing.construct(things = {a: new Thing, b: new Thing})
            another_mask = new Mask things.a
            expect(another_mask.containedBy a_mask).to.be true

         it 'should return true if all items are contained by a passed Mask', ->
            [a_thing, another_thing] = [new Thing, new Thing]
            parent_thing = Thing.construct {something: new Thing, something_else: new Thing}
            a_mask = new Mask Thing.construct {child: parent_thing}
            another_mask = new Mask parent_thing
            expect(another_mask.containedBy a_mask).to.be true

         it 'should return true if all items are contained by one or another of the passed Masks'
            # NYI: Is this even possible? If it contains the root node of a given mask, then it must
            #      contain all nodes. In fact, I should take advantage of that in my climbing algorithm ...

         it 'should return false if any item is *not* contained by one of the passed Masks', ->
            # XXX: Ditto above. It's possible that *only* roots can possibly be not-contained. Hm ...
            [a_thing, another_thing] = [new Thing, new Thing]
            parent_thing = Thing.construct {something: new Thing, something_else: new Thing}
            a_mask = new Mask Thing.construct {child: parent_thing}
            another_mask = new Mask parent_thing
            expect(a_mask.containedBy another_mask).to.be false


   describe 'Label', ->
      it 'should contain a String', ->
         foo = new Label 'foo'
         expect(foo).to.be.a Thing
         expect(foo.alien).to.be.a 'string'
         expect(foo.alien).to.be 'foo'

      describe '#clone', ->
         it 'retains metadata', ->
            foo = new Label 'foo'
            pair = Thing.pair('abc', new Label '123')

            foo.push pair
            clone = foo.clone()
            expect(clone.at(1)).to.be pair

         it 'copies alien-data', ->
            foo = new Label 'foo'

            clone = foo.clone()
            expect(clone.alien).to.be 'foo'

      it 'should compare as equal, when containing the same String', ->
         foo1 = new Label 'foo'
         foo2 = new Label 'foo'
         expect(foo1.compare foo2).to.be true


   describe 'Operation', ->
      it 'consists of of a stringly-typed operation,', ->
         expect(-> new Operation 'foo').to.not.throwError()

      it '... with some optional arguments', ->
         expect(-> new Operation 'foo', new Thing, new Thing).to.not.throwError()

      it 'maintains a global map of known operations', ->
         expect(Operation.operations).to.be.ok()
         expect(Operation.operations).to.be.an 'object'
         expect(Operation.operations).to.have.keys 'advance', 'adopt'

      it 'can be told to register new operation-types', ->
         expect(   Operation.register).to.be.ok()
         expect(   Operation.register).to.be.a 'function'

         [ops, Operation.operations] = [Operation.operations, new Array]
         an_op = new Function

         expect(-> Operation.register 'op', an_op).to.not.throwError()
         expect(   Operation.operations).to.have.key 'op'
         expect(   Operation.operations['op']).to.be an_op

         Operation.operations = ops

      it 'applies the body of the operation against a passed Execution', ->
         [ops, Operation.operations] = [Operation.operations, new Array]
         Operation.register 'op', sinon.spy()
         an_exec = new Execution

         it = new Operation 'op'
         it.perform an_exec

         expect(Operation.operations['op']).was.calledOn an_exec

         Operation.operations = ops

      describe "'advance'", ->
         it 'exists', ->
            expect(Operation.operations['advance']).to.be.ok()
            expect(Operation.operations['advance']).to.be.a 'function'

         it 'advances the execution', ->
            an_exec = new Native ->
            sinon.spy an_exec, 'advance'

            op = new Operation 'advance'
            op.perform an_exec

            expect(an_exec.advance).was.calledOnce()

         it 'does nothing if the execution is complete', ->
            an_exec = new Native
            sinon.spy an_exec, 'advance'

            op = new Operation 'advance'
            op.perform an_exec

            expect(an_exec.advance).was.notCalled()
         it "calls a Native's next bit,", ->
            bit = sinon.spy()
            an_exec = new Native bit
            a_thing = new Thing

            op = new Operation 'advance', a_thing
            op.perform an_exec

            expect(bit).was.calledOnce()
            expect(bit).was.calledWith a_thing

         # FIXME: I don't like how tightly-coupled this test is.
         it.skip "... or queues a combination for the Execution", ->
            an_exec = new Execution
            a_receiver = new Native

            clone = sinon.stub an_exec.receiver, 'clone'
            clone.returns a_receiver

            op = new Operation 'advance',
            op.perform an_exec

            expect(clone).was.calledOnce()
            expect(a_receiver.queue[0]).to.be.ok()
            expect(a_receiver.queue[0].params[0]).to.be.ok()

            params = a_receiver.queue[0].params[0].metadata
            expect(params[0]).to.be an_exec
            expect(params[1]).to.be.ok()
            expect(params[1]).to.be.ok()

         # TODO: Test defaulting-to-locals functionality

      describe "'adopt'", ->
         it 'exists'


   describe 'Execution', ->
      it 'should construct an Native when passed function-bits', ->
         expect(new Execution ->).to.be.an Native

      it 'should not construct an Native when passed an expression', ->
         expect(new Execution new Sequence).to.be.an Execution
         expect(new Execution new Sequence).not.to.be.an Native

         expect(new Execution).to.be.an Execution
         expect(new Execution).not.to.be.an Native

      it 'should begin life in a pristine state', ->
         expect((new Execution).pristine).to.be yes

      it 'should begin already completed if created with no instructions', ->
         expect((new Execution).complete()).to.be yes

      it 'should have locals', ->
         exe = new Execution
         expect(exe.locals).to.be.a Thing
         expect(exe.locals.metadata).to.have.length 2

         # Seperate locals-tests into their own suite
         expect(exe.find 'locals').to.not.be.empty()
         expect(exe       .at(1).valueish()).to.be exe.locals
         expect(exe       .at(1).metadata[2].owns).to.be yes
         expect(exe.locals.at(1).valueish()   ).to.be exe.locals
         expect(exe.locals.at(1).metadata[2].owns).to.be no

      it 'should take a position', ->
         seq = new Sequence new Expression

         expect(-> new Execution seq).to.not.throwException()

         exec = new Execution seq
         expect(exec.instructions[0].expression()).to.be seq.at 0

      it 'should know whether it is complete', ->
         ex = new Execution Expression.from ['foo']
         expect(ex.complete()).to.be false

         ex.advance()
         expect(ex.complete()).to.be false

         ex.advance()
         expect(ex.complete()).to.be true

      it 'provides access to its current position', ->
         seq = parse 'abc def'
         ex = new Execution seq

         expect(-> ex.current()).to.not.throwException()
         expect(   ex.current()).to.be.a Position

         expect(   ex.current().expression()).to.be seq.at 0
         expect(   ex.current().valueOf().alien).to.be 'abc'

         ex.advance()
         ex.advance new Thing
         expect(   ex.current().expression()).to.be seq.at 0
         expect(   ex.current().valueOf().alien).to.be 'def'

      it 'can be cloned', ->
         ex = new Execution (new Sequence)
         expect(-> ex.clone()).to.not.throwException()
         expect(   ex.clone()).to.be.an Execution

      it 'preserves the instructions and results when cloning', ->
         seq1 = new Sequence new Expression
         seq2 = new Sequence new Expression
         ex = new Execution seq1

         clone1 = ex.clone()
         expect(clone1.instructions[0].expression()).to.be seq1.at 0
         expect(clone1.results).to.not.be ex.results
         expect(clone1.results).to.eql ex.results

         ex.instructions[0] = new Position seq2
         ex.results.unshift new Label 'intermediate value'
         clone2 = ex.clone()
         expect(clone2.instructions[0].expression()).to.be seq2.at 0
         expect(clone2.results).to.have.length 2
         expect(clone2.results).to.not.be ex.results
         expect(clone2.results).to.eql ex.results

      it 'clones locals when cloned', ->
         ex = new Execution (new Sequence)
         clone = ex.clone()

         expect(clone.locals).to.not.equal ex.locals
         expect(clone.find('locals')[0].valueish()).to.equal clone.locals
         expect(clone.locals.toArray()).to.eql ex.locals.toArray()

      it 'retains a reference to old locals when cloned', ->
         ex = new Execution (new Sequence)
         clone = ex.clone()

         expect(clone.locals).to.not.equal ex.locals
         expect(clone.find('locals')[1].valueish()).to.equal ex.locals

      describe '#advance', ->
         it "doesn't modify a completed Native", ->
            completed_alien = new Native
            expect(completed_alien.complete()).to.be.ok()

            expect(completed_alien.advance new Thing).to.be undefined

         it 'flags a modified Native as un-pristine', ->
            func1 = new Function; func2 = new Function
            an_alien = new Native func1, func2

            an_alien.advance new Thing
            expect(an_alien.pristine).to.be no

         it 'advances the bits of an Native', ->
            func1 = new Function; func2 = new Function
            an_alien = new Native func1, func2

            expect(an_alien.advance new Thing).to.be func1
            expect(an_alien.advance new Thing).to.be func2

            expect(an_alien.complete()).to.be.ok()

         it 'completes Executions', ->
            an_xec = new Execution Expression.from ['something']

            an_xec.advance()
            an_xec.advance()

            expect(an_xec.complete()).to.be yes

         it 'does nothing with a completed Execution', ->
            completed_native = new Execution Expression.from ['something']
            completed_native.advance()
            completed_native.advance()

            expect(completed_native.advance()).to.be undefined

         it "doesn't choke on a simple expression", ->
            an_xec = new Execution Expression.from ['abc', 'def']
            expect(-> an_xec.advance()).to.not.throwError()

         it 'can generate a simple combination against a previous result', ->
            expr = Expression.from ['something','other']; other = expr.at(1)
            an_xec = new Execution expr
            an_xec.advance()

            something = new Thing
            combo = an_xec.advance something
            expect(combo.subject).to.be something
            expect(combo.message).to.be other

         it 'implicitly combines against locals at the beginning of an Execution', ->
            expr = Expression.from ['something']; something = expr.at(0)
            an_xec = new Execution expr

            combo = an_xec.advance()
            expect(combo.subject).to.be null
            expect(combo.message).to.be something

         it 'will dive into sub-expressions, again implicitly combining against locals', ->
            expr = Expression.from ['something', ['other']]; other = expr.at(1).at(0,0)
            an_xec = new Execution expr
            c1 = an_xec.advance()

            something = (new Thing).rename 'something'
            combo = an_xec.advance something
            expect(combo.subject).to.be null
            expect(combo.message).to.be other

         it "should retain the previous result at the parent's level,
             and juxtapose against that when exiting", ->
            expr = Expression.from ['something', ['other']]
            an_xec = new Execution expr
            an_xec.advance()

            something = new Thing
            an_xec.advance something

            other = new Object
            combo = an_xec.advance other
            expect(combo.subject).to.be something
            expect(combo.message).to.be other

         it 'should descend into multiple levels of nested-immediate sub-expressions', ->
            expr = Expression.from ['something', [[['other']]]]
            an_xec = new Execution expr
            an_xec.advance()
            # ~locals <- 'something'

            something = new Thing
            an_xec.advance something
            # ~locals <- 'other'

            other = new Thing
            combo = an_xec.advance other
            expect(combo.subject).to.be null
            expect(combo.message).to.be other
            # ~locals <- other

            meta_other = new Thing
            combo = an_xec.advance meta_other
            expect(combo.subject).to.be null
            expect(combo.message).to.be meta_other
            # ~locals <- <meta-other>

            meta_meta_other = new Thing
            combo = an_xec.advance meta_meta_other
            expect(combo.subject).to.be something
            expect(combo.message).to.be meta_meta_other
            # something <- <meta-meta-other>

         it 'should handle an *immediate* sub-expression', ->
            expr = Expression.from [['something'], 'other']; other = expr.at(1)
            an_xec = new Execution expr
            an_xec.advance()
            # ~locals <- 'something'

            something = new Thing
            combo = an_xec.advance something
            expect(combo.subject).to.be null
            expect(combo.message).to.be something
            # ~locals <- something

            meta_something = new Thing
            combo = an_xec.advance meta_something
            expect(combo.subject).to.be meta_something
            expect(combo.message).to.be other
            # <meta-something> <- 'other'

         it 'should descend into multiple levels of *immediate* nested sub-expressions', ->
            expr = Expression.from [[[['other']]]]
            an_xec = new Execution expr
            an_xec.advance()
            # ~locals <- 'other'

            other = new Thing
            combo = an_xec.advance other
            expect(combo.subject).to.be null
            expect(combo.message).to.be other
            # ~locals <- other

            meta_other = new Thing
            combo = an_xec.advance meta_other
            expect(combo.subject).to.be null
            expect(combo.message).to.be meta_other
            # ~locals <- <meta-other>

            meta_meta_other = new Thing
            combo = an_xec.advance meta_meta_other
            expect(combo.subject).to.be null
            expect(combo.message).to.be meta_meta_other
            # ~locals <- <meta-meta-other>

      describe 'as an Native', ->
         it 'should take a series of procedure-bits', ->
            a = (->); b = (->); c = (->)

            expect(-> new Execution a, b, c).to.not.throwException()
            expect(   new Execution a, b, c).to.be.an Native

            expect(  (new Execution a, b, c).bits).to.have.length 3
            expect(  (new Execution a, b, c).bits).to.eql [a, b, c]

         it 'should know whether it is complete', ->
            ex = new Execution ->
            expect(ex.complete()).to.be false

            ex.bits.length = 0
            expect(ex.complete()).to.be true

         it 'can be cloned', ->
            ex = new Execution ->
            expect(-> ex.clone()).to.not.throwException()
            expect(   ex.clone()).to.be.an Native

         it 'has the same bits after cloning', ->
            funcs =
               one: ->
               two: ->
               three: ->
            ex = new Execution funcs.one, funcs.two, funcs.three

            clone = ex.clone()
            expect(clone.bits).to.not.be ex.bits
            expect(clone.bits).to.eql [funcs.one, funcs.two, funcs.three]

         # FIXME: Why did I expect this to behave differently when it was a `Native`!?
         it.skip 'shares locals with clones', ->
            ex = new Execution ->
            clone = ex.clone()

            expect(clone.locals).to.equal ex.locals

         describe '##synchronous', ->
            synchronous = Native.synchronous
            it 'accepts a function', ->
               expect(   synchronous).to.be.ok()
               expect(-> synchronous ->).to.not.throwException()

            it 'results in a new Native', ->
               expect(synchronous ->).to.be.an Native

            it 'adds bits corresponding to the arity of the function', ->
               expect( (synchronous (a, b)->)       .bits).to.have.length 3
               expect( (synchronous (a, b, c, d)->) .bits).to.have.length 5

            describe 'produces bits that ...', ->
               a = null
               beforeEach -> a =
                  caller: new Execution
                  thing:  new Label 'foo'
                  unit: { stage: sinon.spy() }
               call = (exe, rv)->
                  # FIXME: This is waaaaay too tightly-coupled. I am clearly bad at TDD.
                  exe.bits.shift().call exe, rv, a.unit

               it 'are Functions', ->
                  exe = synchronous (a, b, c)->
                  expect(exe.bits[0]).to.be.a Function
                  expect(exe.bits[1]).to.be.a Function
                  expect(exe.bits[2]).to.be.a Function
                  expect(exe.bits[3]).to.be.a Function

               it 'expect a caller, RV, and unit', ->
                  exe = synchronous (a, b, c)->
                  expect(exe.bits[0]).to.have.length 2 # `caller`-curry
                  expect(exe.bits[1]).to.have.length 3
                  expect(exe.bits[2]).to.have.length 3

               it 'can be successfully called', ->
                  exe = synchronous (a, b, c)->
                  expect(-> call exe, a.caller).to.not.throwException()
                  expect(-> call exe, a.thing).to.not.throwException()

               it 'are provided a `caller` by the first bit', ->
                  some_function = sinon.spy (a, b, c)->
                  exe = synchronous some_function
                  exe.bits = exe.bits.map (bit)-> sinon.spy bit
                  bits = exe.bits.slice()

                  call exe, a.caller
                  call exe, new Label 123
                  call exe, new Label 456
                  call exe, new Label 789

                  assert bits[1].calledWith a.caller
                  assert bits[2].calledWith a.caller
                  assert bits[3].calledWith a.caller

               it 're-stage the `caller` after each coproductive consumption', ->
                  stage = a.unit.stage
                  exe = synchronous (a, b, c)->

                  call exe, a.caller
                  expect(stage.callCount).to.be 1
                  assert stage.getCall(0).calledOn a.unit
                  assert stage.getCall(0).calledWith a.caller, exe

                  call exe, new Label 123
                  expect(stage.callCount).to.be 2
                  assert stage.getCall(1).calledOn a.unit
                  assert stage.getCall(1).calledWith a.caller, exe

                  call exe, new Label 456
                  expect(stage.callCount).to.be 3
                  assert stage.getCall(2).calledOn a.unit
                  assert stage.getCall(2).calledWith a.caller, exe

                  call exe, new Label 789
                  expect(stage.callCount).to.not.be 4

               it 're-stage the `caller` after all coproduction if a result is returned', ->
                  stage = a.unit.stage

                  result = new Label "A result!"
                  exe = synchronous (a)-> return result

                  call exe, a.caller
                  expect(stage.callCount).to.be 1
                  assert stage.getCall(0).calledOn a.unit
                  assert stage.getCall(0).calledWith a.caller, exe

                  call exe, new Label 123
                  expect(stage.callCount).to.be 2
                  assert stage.getCall(1).calledOn a.unit
                  assert stage.getCall(1).calledWith a.caller, result

               it 're-stage the `caller` immediately if no coconsumption is required', ->
                  stage = a.unit.stage

                  result = new Label "A result!"
                  exe = synchronous -> return result

                  call exe, a.caller
                  expect(stage.callCount).to.be 1
                  assert stage.getCall(0).calledOn a.unit
                  assert stage.getCall(0).calledWith a.caller, result

               it 'call the passed function exactly once, when exhausted', ->
                  some_function = sinon.spy (a, b, c)->
                  exe = synchronous some_function

                  call exe, a.caller
                  call exe, new Label 123
                  call exe, new Label 456
                  call exe, new Label 789

                  assert some_function.calledOnce

               it 'collect individually passed arguments into arguments to the passed function', ->
                  some_function = sinon.spy (a, b, c)->
                  exe = synchronous some_function

                  things =
                     first:  new Label 123
                     second: new Label 456
                     third:  new Label 789

                  call exe, a.caller
                  call exe, things.first
                  call exe, things.second
                  call exe, things.third

                  assert some_function.calledWithExactly(
                     things.first, things.second, things.third, a.unit)

               it 'inject context into the passed function', ->
                  some_function = sinon.spy (arg)->
                  exe = synchronous some_function

                  call exe, a.caller
                  call exe, a.thing

                  expect(some_function.firstCall.thisValue).to.have.property 'caller'
                  expect(some_function.firstCall.thisValue.caller).to.be.an Execution
                  expect(some_function.firstCall.thisValue.caller).to.be a.caller

                  expect(some_function.firstCall.thisValue).to.have.property 'this'
                  expect(some_function.firstCall.thisValue.this).to.be.an Execution
                  expect(some_function.firstCall.thisValue.this).to.be exe

                  expect(some_function.firstCall.thisValue).to.have.property 'unit'
                 #expect(some_function.firstCall.thisValue.unit).to.be.a Unit # FIXME
                  expect(some_function.firstCall.thisValue.unit).to.be a.unit
