support = require './support.coffee'
util    = require '../Source/utilities.coffee'

assert  = require 'assert'
sinon   = require 'sinon'
expect  = require('sinon-expect').enhance require('expect.js'), sinon, 'was'
__      = sinon.match


describe "Paws' Data types:", ->
   Paws = require "../Source/Paws.coffee"

   {  Reactor, parse
   ,  Thing, Label, Execution, Native
   ,  Relation, Liability, Combination, Position, Mask, Operation }                           = Paws

   {  Context, Sequence, Expression }                                                        = parse


   describe 'Thing', -> # ---- ---- ---- ---- ----                                             Thing
      # FIXME: A lot of these tests are more ... integration-ey than unit-ey; and to boot, a lot of
      #        *actual* unit tests are absent. I need to extract some of these complicated,
      #        purpose-related tests into an *integration* suite, and then re-build this suite from
      #        scratch to achieve ≥80% *unit* coverage.

      # ### Thing: Core functionality ###

      it 'exists', ->
         expect(Thing).to.be.ok()
         expect(Thing).to.be.a 'function'

      it 'has a UUID', ->
         uuid_regex = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/

         expect((new Thing).id).to.match uuid_regex

      it 'compares by identity', ->
         thing1 = new Label 'foo'
         thing2 = new Label 'foo'

         expect(Thing::compare.call thing1, thing1).to.be     true
         expect(Thing::compare.call thing1, thing2).to.not.be true

      it 'can easily construct a Relation *to* itself', ->
         a_parent = new Thing; a_child  = new Thing; another_child = new Thing

         result = a_child.owned_by a_parent
         expect(result).to.be.a Relation
         expect(result).to.be.owned()
         expect(result.from).to.be a_parent
         expect(result.to)  .to.be a_child

         result = another_child.contained_by a_parent
         expect(result).to.be.a Relation
         expect(result).not.to.be.owned()
         expect(result.from).to.be a_parent
         expect(result.to)  .to.be another_child

      describe '~ Metadata', ->
         it 'is an ordered list of metadata', ->
            thing = new Thing
            expect(thing).to.have.property 'metadata'
            expect(thing.metadata).to.be.an 'array'

         it 'has an implicit slot for the noughty by default', ->
            thing = new Thing
            expect(thing.metadata).to.have.length 1
            expect(thing.metadata[0]).to.be undefined

         it 'can be configured with no noughty-slot', ->
            bare_thing = new Thing.with(noughtify: no)()
            expect(bare_thing.metadata).to.have.length 0

         it 'stores relations to other Things', ->
            child1 = new Thing; child2 = new Thing
            thing = new Thing child1, child2
            expect(thing).to.have.property 'metadata'
            expect(thing.metadata).to.be.an 'array'
            expect(thing.metadata[1]).to.be.a Relation
            expect(thing.metadata[1].to).to.be child1
            expect(thing.metadata[2]).to.be.a Relation
            expect(thing.metadata[2].to).to.be child2

         it 'tracks ownership', ->
            a_parent = new Thing; a_child  = new Thing; another_child = new Thing
            a_parent = new Thing a_child.owned_by(a_parent), another_child

            expect(a_parent.metadata[1]).to.be.owned()
            expect(a_parent.metadata[2]).to.not.be.owned()

            a_parent.disown_at 1
            expect(a_parent.metadata[1]).to.not.be.owned()
            expect(a_child.owners).to.be.empty()

            a_parent.own_at 2
            expect(a_parent.metadata[2]).to.be.owned()
            expect(another_child.owners).to.not.be.empty()
            expect(another_child.is_owned_by a_parent).to.be yes


      describe '~ Backlinks', ->
         it 'are created on children added as ‘owned’', ->
            a_parent = new Thing; a_child  = new Thing; another_child = new Thing; other = new Thing

            expect(a_child).to.have.property 'owners'
            expect(a_child.owners).to.be.an 'array'
            expect(a_child.owners).to.have.length 0

            a_parent.push a_child.owned_by(a_parent), other, another_child.owned_by(a_parent)
            expect(a_child).to.have.property 'owners'
            expect(a_child.owners).to.be.an 'array'
            expect(a_child.owners).to.have.length 1

            expect(a_child.owners[0]).to.be.a Relation
            expect(a_child.owners).to.contain a_parent.metadata[1]
            expect(another_child.owners).to.contain a_parent.metadata[3]

            expect(other.owners).to.be.empty()

         it 'are maintained by other metadata-modifying operations', ->
            a_parent = new Thing; a_child  = new Thing; another_child = new Thing

            a_parent.unshift a_child.owned_by(a_parent)
            rel = a_parent.metadata[1]

            expect(a_child.owners).to.contain rel

            a_parent.set 1, another_child.owned_by(a_parent)
            expect(a_parent.metadata[1]).to.not.equal rel
            expect(another_child.owners).to.contain a_parent.metadata[1]

         it 'are discarded when the child is removed', ->
            first = new Thing; second = new Thing; third = new Thing
            a_parent = new Thing first.owned_by(a_parent), second.owned_by(a_parent), third.owned_by(a_parent)

            expect(first.owners) .to.have.length 1
            expect(second.owners).to.have.length 1
            expect(third.owners) .to.have.length 1

            a_parent.set 2, undefined
            expect(second.owners).to.have.length 0

            a_parent.shift()
            expect(first.owners) .to.have.length 0

            a_parent.pop()
            expect(third.owners) .to.have.length 0

         it 'are removed *and* added when directly setting elements by index', ->
            a_parent = new Thing; a_child  = new Thing; another_child = new Thing; other = new Thing
            a_parent.push a_child.owned_by(a_parent), other

            original_relation = a_parent.metadata[1]
            expect(a_child.owners).to.contain original_relation

            a_parent.set 1, another_child.owned_by(a_parent)
            expect(a_parent.metadata[1]).to.not.be original_relation
            expect(a_child.owners).to.be.empty()
            expect(another_child.owners).to.contain a_parent.metadata[1]

      describe '~ Responsibility', ->
         it 'is expressed as a set of current ‘custodians’', ->
            a Thing
            expect(a.thing).to.have.property 'custodians'


      # ### Thing: Metadata methods ###

      describe '::clone', ->
         it 'creates a new Thing', ->
            thing = new Thing
            expect(thing.clone()).to.not.be thing

         it 'duplicates the metadata of the receiver', ->
            thing = new Thing new Thing, new Thing, new Thing
            clone = thing.clone()

            expect(clone.metadata).to.have.length 4
            clone.metadata.forEach (rel, i) -> if rel
               expect(clone.at i).to.be.ok()
               expect(rel).not.to.be thing.metadata[i]
               expect(rel.to).to.be  thing.metadata[i].to

         it 'updates the `from`-linkage on the copied metadata', ->
            thing = new Thing new Thing, new Thing, new Thing
            clone = thing.clone()

            clone.metadata.forEach (rel, i) -> if rel
               expect(rel.from).to.not.be thing
               expect(rel.from).to.be     clone

         it 'handles empty elements gracefully', ->
            thing = new Thing new Thing, undefined, new Thing

            expect(-> thing.clone()).to.not.throwError()

         it 'can copy metadata to an existing other-Thing instead of creating one', ->
            thing1 = new Thing new Thing, new Thing, new Thing
            thing2 = new Thing new Thing
            old_metadata = thing2.metadata

            result = thing1.clone(thing2)
            expect(result).to.be thing2
            expect(thing2.metadata).to.not.be old_metadata

         it 'does not copy active responsibility', ->
            thing = new Thing new Thing, new Thing, new Thing

            thing.dedicate a Liability, (an Execution), thing

            expect(thing.custodians.direct).to.not.be.empty()
            clone = thing.clone()
            expect(clone.custodians.direct).to.be.empty()

      describe '::toArray', ->
         it 'reduces the receiver Thing to an Array', ->
            it = new Thing
            expect(-> it.toArray()).to.not.throwException()
            expect(   it.toArray()).to.be.an 'array'
            expect(   it.toArray()).to.be.empty()

            another = new Thing new Thing, new Thing, new Thing
            expect(another.toArray()).to.be.an 'array'
            expect(another.toArray()).to.not.be.empty()

         it 'returns Things, not the Relation objects from the receiver', ->
            first = new Thing; second = new Thing; third = new Thing
            it = new Thing first, second, third

            array = it.toArray()
            expect(array).to.have.length 3
            expect(array[0]).to.not.be.a Relation
            expect(array[0]).to.be.a Thing

         it 'excludes the noughty by default', ->
            first = new Thing; second = new Thing; third = new Thing
            it = new Thing first, second, third

            array = it.toArray()
            expect(array).to.have.length 3
            expect(array[0]).to.be first

         it 'retains empty slots', ->
            first = new Thing; third = new Thing
            it = new Thing first, undefined, third

            array = it.toArray()
            expect(array).to.have.length 3
            expect(array[0]).to.be first
            expect(array[1]).to.be undefined
            expect(array[2]).to.be third

      describe '::pair', ->
         it 'creates a new Thing', ->
            expect(Thing.pair()).to.be.a Thing

         it 'turns the first argument into a Label', ->
            a_pair = Thing.pair 'foo'
            expect(a_pair.at 1).to.be.a Label
            expect(a_pair.at(1).alien).to.be 'foo'

            a_pair = Thing.pair Label('bar')
            expect(a_pair.at 1).to.be.a Label
            expect(a_pair.at(1).alien).to.be 'bar'

         it 'creates the pair as owning the key-Label', ->
            foo = new Thing
            a_pair = Thing.pair 'foo', foo

            expect(a_pair.at(1).alien).to.be 'foo'
            expect(a_pair.metadata[1]).to.be.owned()

         it 'creates the pair as *not* owning the value', ->
            foo = new Thing
            a_pair = Thing.pair 'foo', foo

            expect(a_pair.at(2)).to.be foo
            expect(a_pair.metadata[2]).to.not.be.owned()

         it 'can be instructed to create the pair as owning the value', ->
            foo = new Thing
            a_pair = Thing.pair 'foo', foo, yes

            expect(a_pair.at(2)).to.be foo
            expect(a_pair.metadata[2]).to.be.owned()

         it 'takes existing ownership of a passed Relation by default', ->
            foo = new Thing
            rel = new Relation null, foo, yes
            a_pair = Thing.pair 'foo', rel

            expect(a_pair.at(2)).to.be foo
            expect(a_pair.metadata[2]).to.be.owned()

         it 'can be instructed to *override* existing ownership of a passed Relation', ->
            foo = new Thing
            rel = new Relation null, foo, yes
            a_pair = Thing.pair 'foo', rel, no

            expect(a_pair.at(2)).to.be foo
            expect(a_pair.metadata[2]).to.not.be.owned()

      describe '::define', ->
         it 'adds a pair to the end of the receiver', ->
            a_thing = Thing.construct foo: new Thing
            another_thing = new Thing

            a_thing.define 'bar', another_thing
            expect(a_thing.find('bar')[0].isPair()).to.be yes
            expect(a_thing.find('bar')[0].valueish()).to.be another_thing

      describe '::find', ->
         first = new Thing; second = new Thing; third = new Thing
         foo_bar_foo = new Thing Thing.pair('foo', first),
                                 Thing.pair('bar', second),
                                 Thing.pair('foo', third)

         it 'produces an Array of Things', ->
            expect(foo_bar_foo.find Label 'nope').to.be.an 'array'

         it 'finds Things matching a given key', ->
            results = foo_bar_foo.find Label 'foo'
            expect(results.length).to.be.greaterThan 0
            results.forEach (result) ->
               expect(result).to.be.a Thing

         it "excludes Things that don't match the key", ->
            results = foo_bar_foo.find Label 'foo'
            expect(results).to.have.length 2
            expect(util.pluck results, 'metadata.2.to').to.not.contain second # FIXME: ugly.

         it 'produces the results in reverse order', ->
            results = foo_bar_foo.find Label 'foo'
            expect(results[0].valueish()).to.be third
            expect(results[1].valueish()).to.be first

         it 'handles Things with non-pair members gracefully', ->
            thing = new Thing Thing.pair('foo', first),
                              new Thing,
                              Thing.pair('bar', second),
                              Thing.pair('foo', third)
            expect(thing.find Label 'foo').to.have.length 2

         it 'can take a JavaScript primitive as a key instead of a Label', ->
            expect(foo_bar_foo.find 'bar').to.have.length 1

      describe '~ The root `receiver`', ->
         caller = undefined; receiver = undefined
         beforeEach ->
            caller   = new Execution
            receiver = Thing::receiver.clone()

         it 'preforms a `::find`', ->
            a_thing = Thing.construct foo: another_thing = new Thing
            params = Execution.create_params caller, a_thing, new Label 'foo'
            sinon.spy a_thing, 'find'

            bit = receiver.advance params
            bit.apply receiver, [params]

            expect(a_thing.find).was.calledOnce()

         # FIXME: This should really be an *integration* test.
         it 'finds a matching pair-ish Thing in the subject', ->
            a_thing = Thing.construct foo: another_thing = new Thing
            params = Execution.create_params caller, a_thing, new Label 'foo'
            sinon.spy caller, 'queue'

            bit = receiver.advance params
            bit.apply receiver, [params]

            expect(caller.queue).was.calledWith __.has 'params', [another_thing]

         it 'stages the caller if there is a result', ->
            a_thing = Thing.construct foo: another_thing = new Thing
            params = Execution.create_params caller, a_thing, new Label 'foo'
            sinon.spy caller, 'queue'

            bit = receiver.advance params
            bit.apply receiver, [params]

            expect(caller.queue).was.calledOnce()

         it 'does not stage the caller if there is no result', ->
            a_thing = Thing.construct foo: another_thing = new Thing
            params = Execution.create_params caller, a_thing, new Label 'bar'
            sinon.spy caller, 'queue'

            bit = receiver.advance params
            bit.apply receiver, [params]

            expect(caller.queue).was.notCalled()

      # NB: A lot of this is duplicating effort from the Giraphe tests; but hey.
      describe '::_walk_descendants', ->
         it 'exists', ->
            a Thing
            expect(a.thing._walk_descendants).to.be.a 'function'

         it "doesn't throw when given no arguments", ->
            expect(-> (a Thing)._walk_descendants()).to.not.throwException()

         it 'accepts a callback', ->
            a.thing = Thing.construct
               foo: foo = new Thing, bar: bar = Thing.construct
                  widget: widget = new Thing

            expect(-> a.thing._walk_descendants(->)).to.not.throwException()

         it.skip 'provides a method to cache results during a particular reactor-step'

         it 'returns a mapping object', ->
            a Thing

            rv = a.thing._walk_descendants()
            expect(rv).to.be.an 'object'

         it 'collects owned descendants into the returned object', ->
            a.thing = Thing.construct
               foo: foo = new Thing, bar: bar = Thing.construct
                  widget: widget = new Thing

            rv = a.thing._walk_descendants()
            expect(util.values(rv)).to.contain foo
            expect(rv[foo.id]).to.be foo

         it 'calls the callback on each node walked', ->
            a.thing = Thing.construct
               foo: foo = new Thing, bar: bar = Thing.construct
                  widget: widget = new Thing

            a.thing._walk_descendants cb = sinon.spy()
            expect(cb).was.calledOn a.thing
            expect(cb).was.calledOn foo
            expect(cb).was.calledOn bar
            expect(cb).was.calledOn widget

         it 'skips objects for which the callback returns false', ->
            a.thing = Thing.construct
               foo: foo = new Thing, bar: bar = Thing.construct
                  widget: widget = new Thing

            descendants = a.thing._walk_descendants cb = sinon.spy ->
               return false if this is bar

            expect(cb).was.calledOn bar
            expect(descendants[foo.id]).to.be foo
            expect(descendants[bar.id]).to.be undefined

         it 'can be instructed to cease iteration', ->
            a.thing = Thing.construct
               foo: foo = new Thing, bar: bar = Thing.construct
                  widget: widget = new Thing

            rv = a.thing._walk_descendants cb = sinon.spy ->
               return Thing.abortIteration if this is foo

            expect(rv).to.not.be.ok()

         it 'skips descendants of objects for which the callback returns false', ->
            a.thing = Thing.construct
               foo: foo = new Thing, bar: bar = Thing.construct
                  widget: widget = new Thing

            descendants = a.thing._walk_descendants cb = sinon.spy ->
               return false if this is bar

            # FIXME: Yes, this is awkwardly-worded. It's pending sinon-expect#5:
            #        <https://github.com/lightsofapollo/sinon-expect/issues/5>
            expect(!cb.calledOn widget)
            expect(descendants[widget.id]).to.be undefined

         it "doesn't touch contained (not-owned) descendants", ->
            a.thing = Thing.construct
               foo: foo = new Thing, bar: bar = Thing.construct
                  widget: widget = (new Thing).contained_by(bar)

            descendants = a.thing._walk_descendants cb = sinon.spy()

            # FIXME: See above.
            expect(!cb.calledOn widget)
            expect(descendants[widget.id]).to.be undefined

         it 'touches each descendant only once, in the presence of cyclic graphcs', ->
            a.thing = Thing.construct
               child: child = new Thing
            child.define('cyclic', a.thing)

            a.thing._walk_descendants cb = sinon.spy()
            # FIXME: This could probably be better expressed (slash less-tightly-coupled)
            expect(cb.callCount).to.be 6

      # ### Thing: Responsibility methods ###

      describe '::available_to', ->
         it 'exists', ->
            expect((a Thing).available_to).to.be.a 'function'

         it 'accepts a Liability', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a Liability, (an Execution), a_thing

            expect(-> a_thing.available_to a.liability).to.not.throwException()

         it 'succeeds if the root has no children and is not adopted', ->
            expect((a Thing).available_to a Liability).to.be yes

         it "succeeds if none of the receiver's descendants are adopted", ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                  bar = Thing.construct widget: widget = new Thing

            expect(a_thing.available_to a Liability).to.be true

         it 'succeeds if the receiver is already adopted by the execution', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a Liability, (an Execution), a_thing

            a_thing.dedicate new Liability an.execution, a_thing
            expect(a_thing.available_to a.liability).to.be yes

         it 'fails if the receiver is adopted by another execution', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a Liability, (an Execution), a_thing

            a_thing.dedicate new Liability (another Execution), a_thing, 'write'
            expect(a_thing.available_to a.liability).to.be no

         it "fails when one of the root's descendants is adopted by another execution", ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            an Execution; a Liability

            widget.dedicate new Liability (another Execution), widget, 'write'
            expect(a_thing.available_to a.liability).to.be no

      describe '::belongs_to', ->
         it 'exists', ->
            expect((a Thing).belongs_to).to.be.a 'function'

         it 'accepts an Execution', ->
            expect(-> (a Thing).belongs_to an Execution).to.not.throwException()

         it 'accepts a Liability', ->
            expect(-> (a Thing).belongs_to a Liability).to.not.throwException()

         it 'accepts a Thing with parents', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a Liability, (an Execution), a_thing

            expect(-> widget.belongs_to a.Liability).to.not.throwException()

         it 'indicates false if there are no custodians', ->
            expect((a Thing).belongs_to a Liability).to.be no

         describe '~ Direct responsibility', ->
            it 'succeeds if the receiver belongs to the passed Liability', ->
               (a Thing).dedicate a Liability, new Execution, a.thing

            it 'fails if it has other custodians, but not the passed Liability', ->
               (a Thing).dedicate a Liability, (an Execution), a.thing, 'write'
               another Liability, (another Execution), a.thing, 'read'

               expect(a.thing.belongs_to another.liability).to.be no

            it 'succeeds if the receiver already belongs to the Exec with the same license', ->
               (a Thing).dedicate a Liability, (an Execution), a.thing, 'read'

               expect(a.thing.belongs_to an.execution, 'read').to.be yes

            it 'succeeds if it already belongs to the the Exec with a greater license', ->
               (a Thing).dedicate a Liability, (an Execution), a.thing, 'write'

               expect(a.thing.belongs_to an.execution, 'read').to.be yes

            it 'fails if it already belongs to the the Exec with a lesser license', ->
               (a Thing).dedicate a Liability, (an Execution), a.thing, 'read'

               expect(a.thing.belongs_to an.execution, 'write').to.be no

            it 'fails if it has other custodians, but not the passed Exec', ->
               (a Thing).dedicate a Liability, (an Execution), a.thing, 'write'

               expect(a.thing.belongs_to (another Execution), 'read').to.be no

         describe '~ Indirect responsibility', ->
            it 'succeeds if a parent of the receiver belongs to the passed Liability', ->
               a_thing = Thing.construct foo: foo = new Thing, bar:
                   bar = Thing.construct widget: widget = new Thing

               a_thing.dedicate a Liability, (an Execution), a_thing

               expect(widget.belongs_to a.liability).to.be yes

            it 'fails if a parent has other custodians, but not the passed Liability', ->
               a_thing = Thing.construct foo: foo = new Thing, bar:
                   bar = Thing.construct widget: widget = new Thing

               a_thing.dedicate a Liability, (an Execution), a_thing, 'write'
               another Liability, (another Execution), a_thing, 'read'

               expect(widget.belongs_to another.liability).to.be no

      describe '::dedicate', ->
         it 'exists', ->
            expect((a Thing).dedicate).to.be.a 'function'

         it 'adds a passed Liability to the custodians', ->
            a Liability, (an Execution), a Thing

            expect(a.thing.custodians.direct).to.be.empty()

            rv = a.thing.dedicate a.liability
            expect(rv).to.be yes

            expect(a.thing.custodians.direct).to.be.an 'array'
            expect(a.thing.custodians.direct).to.contain a.liability

         it 'climbs descendants, adding the Liability to every owned node', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a Liability, (an Execution), a_thing

            rv = a_thing.dedicate a.liability
            expect(rv).to.be yes

            expect(foo   .custodians.inherited).to.contain a.liability
            expect(widget.custodians.inherited).to.contain a.liability

         it 'succeeds if there is existing, *non-conflicting* responsibility on the receiver', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a       Liability, (an      Execution), a_thing, 'read'
            another Liability, (another Execution), a_thing, 'read'

            a_thing.dedicate a.liability

            rv = a_thing.dedicate another.liability
            expect(rv).to.be yes

            expect(a_thing.custodians.direct   ).to.contain a.liability
            expect(a_thing.custodians.direct   ).to.contain another.liability
            expect(widget .custodians.inherited).to.contain a.liability
            expect(widget .custodians.inherited).to.contain another.liability

         it 'fails if there is conflicting responsibility on the receiver', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a       Liability, (an      Execution), a_thing, 'write'
            another Liability, (another Execution), a_thing, 'read'

            a_thing.dedicate a.liability

            rv = a_thing.dedicate another.liability
            expect(rv).to.be no

            expect(a_thing.custodians.direct   ).to.not.contain another.liability
            expect(widget .custodians.inherited).to.not.contain another.liability

         it 'fails if there is conflicting responsibility a descendant', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a       Liability, (an      Execution), widget, 'write'
            another Liability, (another Execution), a_thing, 'read'

            widget.dedicate a.liability

            rv = a_thing.dedicate another.liability
            expect(rv).to.be no

            expect(a_thing.custodians.direct).to.not.contain another.liability
            expect(a_thing.custodians.direct).to.be.empty()

         it "adds multiple passed Liabilities to the receiver's custodians", ->
            a       Liability, (an      Execution), a Thing
            another Liability, (another Execution), a.thing

            rv = a.thing.dedicate a.liability, another.liability
            expect(rv).to.be yes

            expect(a.thing.custodians.direct).to.contain a.liability
            expect(a.thing.custodians.direct).to.contain another.liability

         it 'climbs descendants, adding all Liabilities to every owned node', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a       Liability, (an      Execution), a_thing
            another Liability, (another Execution), a_thing

            rv = a_thing.dedicate a.liability, another.liability
            expect(rv).to.be yes

            expect(foo   .custodians.inherited).to.contain a.liability
            expect(foo   .custodians.inherited).to.contain another.liability
            expect(widget.custodians.inherited).to.contain a.liability
            expect(widget.custodians.inherited).to.contain another.liability

         it 'adds *no* liabilities if there is conflicting responsibility on the receiver', ->
            # NOTE: It's important that this addition fails on the *second* liability added; it's
            #       explicitly supposed to be testing that the first, *valid* liability isn't
            #       accidetnally left hanging around.
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            some    Liability, (some    Execution), a_thing, 'read'
            a       Liability, (an      Execution), a_thing, 'read'
            another Liability, (another Execution), a_thing, 'write'

            a_thing.dedicate some.liability

            rv = a_thing.dedicate a.liability, another.liability
            expect(rv).to.be no

            expect(a_thing.custodians.direct   ).to.not.contain a.liability
            expect(a_thing.custodians.direct   ).to.not.contain another.liability
            expect(widget .custodians.inherited).to.not.contain a.liability
            expect(widget .custodians.inherited).to.not.contain another.liability

         it 'adds *no* liabilities if there is conflicting responsibility on a descendant', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            some    Liability, (some    Execution), widget,  'read'
            a       Liability, (an      Execution), a_thing, 'read'
            another Liability, (another Execution), a_thing, 'write'

            widget.dedicate some.liability

            rv = a_thing.dedicate a.liability, another.liability
            expect(rv).to.be no

            expect(a_thing.custodians.direct   ).to.not.contain a.liability
            expect(a_thing.custodians.direct   ).to.not.contain another.liability
            expect(widget .custodians.inherited).to.not.contain a.liability
            expect(widget .custodians.inherited).to.not.contain another.liability

      describe '::emancipate', ->
         it 'exists', ->
            expect((a Thing).emancipate).to.be.a 'function'

         it "succeeds if the receiver didn't belong to the Liability", ->
            a Liability, (an Execution), a Thing

            rv = a.thing.emancipate a.liability
            expect(rv).to.be yes

         it 'succeeds if the receiver belongs to the Liability', ->
            a Liability, (an Execution), a Thing

            a.thing.dedicate a.liability

            rv = a.thing.emancipate a.liability
            expect(rv).to.be yes

         it 'removes the passed Liability from the custodians of this node', ->
            a Liability, (an Execution), a Thing

            a.thing.dedicate a.liability
            expect(a.thing.custodians.direct).to.contain a.liability

            rv = a.thing.emancipate a.liability
            expect(rv).to.be yes
            expect(a.thing.custodians.direct).to.not.contain a.liability

         it 'climbs descendants, removing the Liability from every owned node', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a Liability, (an Execution), a_thing

            a_thing.dedicate a.liability
            expect(foo   .custodians.inherited).to.contain a.liability
            expect(widget.custodians.inherited).to.contain a.liability

            rv = a_thing.emancipate a.liability
            expect(rv).to.be yes

            expect(foo   .custodians.inherited).not.to.contain a.liability
            expect(widget.custodians.inherited).not.to.contain a.liability

         it 'succeeds if the receiver belongs to at least one of the Liabilities', ->
            a Liability,       (an      Execution), a Thing
            another Liability, (another Execution), a.thing

            a.thing.dedicate another.liability

            rv = a.thing.emancipate a.liability, another.liability
            expect(rv).to.be yes

         it 'removes all passed Liabilities from the custodians of this node', ->
            a Liability,       (an      Execution), a Thing
            another Liability, (another Execution), a.thing

            a.thing.dedicate another.liability

            rv = a.thing.emancipate a.liability, another.liability
            expect(rv).to.be yes

            expect(a.thing.custodians.direct).to.not.contain a.liability

         it 'climbs descendants, removing all Liabilities from every owned node', ->
            a_thing = Thing.construct foo: foo = new Thing, bar:
                bar = Thing.construct widget: widget = new Thing
            a Liability,       (an      Execution), a_thing
            another Liability, (another Execution), a_thing

            a_thing.dedicate another.liability

            rv = a_thing.emancipate a.liability, another.liability
            expect(rv).to.be yes

            expect(foo   .custodians.inherited).not.to.contain another.liability
            expect(widget.custodians.inherited).not.to.contain another.liability


      # ### Thing: Utility / convenience methods and functions ###

      describe '.construct', ->
         it 'constructs a new Thing', ->
            expect(Thing.construct()).to.be.a Thing

         it 'constructs Things with a noughty-slot', ->
            constructee = Thing.construct()
            expect(constructee.metadata).to.have.length 1
            expect(constructee.at 0).to.be undefined

         it 'constructs pairs for the new Thing', ->
            a_thing = new Thing
            constructee = Thing.construct {foo: a_thing}
            expect(constructee.metadata).to.have.length 2

            pair = constructee.at 1
            expect(pair).to.be.a Thing
            expect(pair.isPair()).to.be true

         it "turns passed JavaScript objects' keys into corresponding definition-pairs", ->
            a_thing = new Thing
            constructee = Thing.construct {foo: a_thing}
            expect(constructee.metadata).to.have.length 2

            pair = constructee.at 1
            expect(pair.at(1).alien).to.be 'foo'
            expect(pair.at 2).to.be a_thing

         it 'successfully constructs multiple such definition-pairs', ->
            thing_1 = new Thing; thing_2 = new Thing
            constructee = Thing.construct {foo: thing_1, bar: thing_2}

            expect(constructee.metadata).to.have.length 3
            expect(constructee.find('foo')[0].valueish()).to.be thing_1
            expect(constructee.find('bar')[0].valueish()).to.be thing_2

         it 'creates the construct as owning its definition-pairs', ->
            constructee = Thing.construct {something: new Thing}
            expect(constructee.metadata[1]).to.be.owned()

         it 'also creates the construct as owning its *members*, by default', ->
            constructee = Thing.construct {something: new Thing}
            expect(constructee.at(1).metadata[2]).to.be.owned()

         it "can be instructed to create structures that *don't* own their members", ->
            constructee = Thing.with(own: no).construct {something: new Thing}
            expect(constructee.metadata[1]).to.be.owned()
            expect(constructee.at(1).metadata[2]).to.not.be.owned()

         it 'generates nested structures', ->
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

         it 'passes Functions onwards to Native.synchronous', ->
            constructee = Thing.construct {foo: new Function}

            pair = constructee.at 1
            expect(pair.at 1).to.be.a Label
            expect(pair.at 2).to.be.an Execution
            expect(pair.at 2).to.have.property 'synchronous'


   # ### Thing: Supporting types ###

   describe 'Relation', -> # ---- ---- ---- ---- ----                                       Relation
      it 'exists', ->
         expect(Relation).to.be.ok()
         expect(Relation).to.be.a 'function'

      it 'expresses a containing / non-owning relationship, by default', ->
         expect((new Relation).owns).to.be no

      it 'can create an owning relationship, as well', ->
         rel = new Relation undefined, undefined, yes
         expect(rel.owns).to.be yes

      it 'if passed an existing relation during construction, copies itself from that', ->
         existing = new Relation new Thing, new Thing, yes

         clone = new Relation existing
         expect(clone.from).to.not.be.a Relation # /reg

         expect(new Relation existing).to.not.be existing
         expect(new Relation existing).to.eql existing

         new_parent = new Thing
         another_clone = new Relation new_parent, existing
         expect(another_clone).to.not.be existing
         expect(another_clone.owns).to.equal existing.owns
         expect(another_clone.to)  .to.equal existing.to
         expect(another_clone.from).to.not.equal existing.from

         expect(another_clone.from).to.be new_parent

      describe '::clone', ->
         it 'creates a new Relation', ->
            a_thing = new Thing; another_thing = new Thing
            rel = new Relation a_thing, another_thing
            expect(rel.clone()     ).to.not.be rel
            expect(rel.clone().from).to.be a_thing
            expect(rel.clone().to  ).to.be another_thing
            expect(rel.clone().owns).to.be no

         it "doesn't change the existing ownership of a cloned Relation", ->
            rel = new Relation new Thing, new Thing, yes
            expect(rel.clone().owns).to.be yes

         it.skip 'does not copy data to a provided `other`, as Relations are immutable! /reg', ->
            # I'm going to need a more robust ‘nuhhuh’ system for mutating Relations. As noted in
            # `datagraph.coffee`, I'm thinking about making Relations immutable *once they've been
            # included in a Thing*.
            rel = new Relation Thing(), Thing(); other = new Relation Thing(), Thing()
            expect(rel.clone other).to.not.be other
            expect(rel.clone other).to.not.eql other


   describe 'Liability', -> # ---- ---- ---- ---- ----                                     Liability
      it 'exists', ->
         expect(Liability).to.be.ok()
         expect(Liability).to.be.a 'function'

      it 'constructs successfully', ->
         expect(-> new Liability).not.to.throwError()
         expect(new Liability).to.be.a Liability
         expect(-> Liability()).not.to.throwError()
         expect(Liability()).to.be.a Liability

      it 'constructs with a custodian and a ward', ->
         a_thing = Thing(); an_exec = Execution()
         expect(-> Liability an_exec, a_thing).not.to.throwError()

         li = Liability an_exec, a_thing
         expect(li).to.be.a Liability
         expect(li.custodian).to.be an_exec
         expect(li.ward).to.be a_thing

      it 'creates write-exclusive (sequential-read) responsibility, by default', ->
         a_thing = Thing(); an_exec = Execution()

         li = Liability an_exec, a_thing
         expect(li.read()).to.be yes
         expect(li.write()).to.be no

      it 'can be instructed to construct as write-responsibility, instead', ->
         a_thing = Thing(); an_exec = Execution()

         li = Liability an_exec, a_thing, yes
         expect(li.read()).to.be no
         expect(li.write()).to.be yes

      it 'can invoke the relevant adoption-operations on the associated Execution and Thing'
      it 'can invoke the relevant relinquishment-operations on the associated Execution and Thing'


   describe 'Label', -> # ---- ---- ---- ---- ----                                             Label
      it 'contains a String', ->
         foo = new Label 'foo'
         expect(foo).to.be.a Thing
         expect(foo.alien).to.be.a 'string'
         expect(foo.alien).to.be 'foo'

      it 'accepts an existing Label instead of an alien, which it then clones', ->
         orig = new Label 'bar'
         bar = new Label orig
         expect(bar).to.be.a Label
         expect(bar).to.not.be orig

         expect(bar.alien).to.be.a 'string'
         expect(bar.alien).to.be 'bar'

      describe '::clone', ->
         it 'retains Thing-metadata', ->
            foo = new Label 'foo'
            pair = Thing.pair('abc', new Label '123')

            foo.push pair
            clone = foo.clone()
            expect(clone.at(1)).to.be pair

         it 'copies associated string-data', ->
            foo = new Label 'foo'

            clone = foo.clone()
            expect(clone.alien).to.be 'foo'

      it 'compares as equal to another Label when they contain the same String', ->
         foo1 = new Label 'foo'
         foo2 = new Label 'foo'
         expect(foo1.compare foo2).to.be true



   describe 'Execution', -> # ---- ---- ---- ---- ----                                     Execution

      # ### Execution: Core functionality ###

      it 'constructs as a Native instead when passed function-bits', ->
         expect(new Execution ->).to.be.a Native
         expect(    Execution ->).to.be.a Native

      it 'constructs as a libspace Execution when passed an expression', ->
         expect(new Execution new Sequence).to.be.an Execution
         expect(new Execution new Sequence).not.to.be.a Native
         expect(    Execution new Sequence).to.be.an Execution
         expect(    Execution new Sequence).not.to.be.a Native

         expect(new Execution  ).to.be.an Execution
         expect(new Execution  ).not.to.be.a Native
         expect(    Execution()).to.be.an Execution
         expect(    Execution()).not.to.be.a Native

      describe '~ Locals storage', ->
         it 'is provided at construction', ->
            exe = new Execution
            expect(exe.locals).to.be.a Thing
            expect(exe.locals.metadata).to.have.length 2

            # Seperate locals-tests into their own suite
            expect(exe.find 'locals').to.not.be.empty()
            expect(exe       .at(1).valueish()).to.be exe.locals
            expect(exe       .at(1).metadata[2].owns).to.be yes
            expect(exe.locals.at(1).valueish()   ).to.be exe.locals
            expect(exe.locals.at(1).metadata[2].owns).to.be no

      describe '~ Position', ->
         it 'begins in a pristine state', ->
            expect((new Execution).pristine).to.be yes

         it 'exists already-completed if created with no instructions', ->
            expect((new Execution).complete()).to.be yes

         it 'is set during creation of the Execution', ->
            seq = new Sequence new Expression

            expect(-> new Execution seq).to.not.throwException()

            exec = new Execution seq
            expect(exec.instructions[0].expression()).to.be seq.at 0

         it 'has knowledge of completion', ->
            ex = new Execution Expression.from ['foo']
            expect(ex.complete()).to.be false

            ex.advance()
            expect(ex.complete()).to.be false

            ex.advance()
            expect(ex.complete()).to.be true

         it 'is exposed during advancement', ->
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

      describe '~ The operation queue', ->
         it 'is initialized', ->
            ex = new Execution
            expect(ex.ops).to.be.ok()
            expect(ex.ops).to.be.an 'array'

         it 'can be added to', ->
            ex = new Execution
            op = new Operation 'foo'

            expect(ex.ops).to.have.length 0

            ex.queue op
            expect(ex.ops).to.have.length 1
            expect(ex.ops[0]).to.be op

            a_thing = new Thing
            ex.queue 'bar', a_thing
            expect(ex.ops).to.have.length 2
            expect(ex.ops[1]).to.have.property 'op'
            expect(ex.ops[1].op).to.be 'bar'
            expect(ex.ops[1].params).to.contain a_thing

         it "provides a convenience method to quickly add 'advance' operations", ->
            ex = new Execution

            expect(ex.ops).to.have.length 0

            a_thing = new Thing
            ex.respond a_thing
            expect(ex.ops).to.have.length 1
            expect(ex.ops[0]).to.have.property 'op'
            expect(ex.ops[0].op).to.be 'advance'
            expect(ex.ops[0].params).to.contain a_thing

      describe '~ Responsibility tracking', ->
         it 'stores a set of wards', ->
            an Execution
            expect(an.execution.wards).to.be.ok()
            expect(an.execution.wards).to.be.an 'array'

         it 'can accept a Liability', ->
            a Liability, (an Execution), a Thing
            expect(an.execution.wards).to.be.empty()

            expect(-> an.execution.accept a.liability ).to.not.throwException()

         it 'adds an accepted Liability to its wards', ->
            a Liability, (an Execution), a Thing
            expect(an.execution.wards).to.be.empty()

            an.execution.accept a.liability
            expect(an.execution.wards).to.not.be.empty()
            expect(an.execution.wards).to.contain a.liability

         it 'can abjure Liability', ->
            a Liability, (an Execution), a Thing
            an.execution.accept a.liability

            expect(-> an.execution.abjure a.liability ).to.not.throwException()

         it 'adds an accepted Liability to its wards', ->
            a Liability, (an Execution), a Thing
            expect(an.execution.wards).to.be.empty()
            an.execution.accept a.liability
            expect(an.execution.wards).to.not.be.empty()

            an.execution.abjure a.liability
            expect(an.execution.wards).to.be.empty()


      # ### Execution: Methods ###

      describe '::clone', ->
         it 'creates a new Execution', ->
            ex = new Execution (new Sequence)
            expect(-> ex.clone()).to.not.throwException()
            expect(   ex.clone()).to.be.an Execution
            expect(   ex.clone()).to.not.be ex

         it 'preserves the instructions and results', ->
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

         it 'also clones the locals-Thing', ->
            ex = new Execution (new Sequence)
            clone = ex.clone()

            expect(clone.locals).to.not.equal ex.locals
            expect(clone.find('locals')[0].valueish()).to.equal clone.locals
            expect(clone.locals.toArray()).to.eql ex.locals.toArray()

         it 'retains a reference to old locals when cloning', ->
            ex = new Execution (new Sequence)
            clone = ex.clone()

            expect(clone.locals).to.not.equal ex.locals
            expect(clone.find('locals')[1].valueish()).to.equal ex.locals

      describe '::advance', ->
         it "doesn't modify a completed Native", ->
            completed_alien = new Native
            expect(completed_alien.complete()).to.be.ok()

            expect(completed_alien.advance new Thing).to.be undefined

         it 'flags a modified Native as un-pristine', ->
            func1 = new Function; func2 = new Function
            an_alien = new Native func1, func2

            an_alien.advance new Thing
            expect(an_alien.pristine).to.be no

         it 'advances the bits of a Native', ->
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

         it "retains the previous result at the parent's level,
             and juxtaposes against that when exiting", ->
            expr = Expression.from ['something', ['other']]
            an_xec = new Execution expr
            an_xec.advance()

            something = new Thing
            an_xec.advance something

            other = new Object
            combo = an_xec.advance other
            expect(combo.subject).to.be something
            expect(combo.message).to.be other

         it 'descends into multiple levels of nested-immediate sub-expressions', ->
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

         it 'handles an *immediate* sub-expression', ->
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

         it 'descends into multiple levels of *immediate* nested sub-expressions', ->
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

      # ### Execution: Combination-receiver ###

      describe '~ The default `receiver`', ->
         caller = undefined; receiver = undefined
         beforeEach ->
            caller   = new Execution
            receiver = Execution::receiver.clone()

         it 'clones the subject,', ->
            an_exec = new Execution; something = new Thing
            params = Execution.create_params caller, an_exec, something

            sinon.spy an_exec, 'clone'

            bit = receiver.advance params
            bit.apply receiver, [params]

            expect(an_exec.clone).was.called()

         it 'resumes that clone,', ->
            an_exec = new Execution; something = new Thing
            params = Execution.create_params caller, an_exec, something
            sinon.spy an_exec, 'clone'

            bit = receiver.advance params
            bit.apply receiver, [params]

            clone = an_exec.clone.returnValues[0]
            expect(clone.ops).to.have.length 1
            expect(clone.ops[0].op).to.be 'advance'
            expect(clone.ops[0].params).to.contain something

         it 'does not re-stage the caller', ->
            an_exec = new Execution; something = new Thing
            params = Execution.create_params caller, an_exec, something

            bit = receiver.advance params
            bit.apply receiver, [params]

            expect(caller.ops).to.have.length 0

   describe 'Native', -> # ---- ---- ---- ---- ----                                           Native

      # ### Native: Core functionality & methods ###

      it 'constructs with a series of procedure-bits', ->
         a = (->); b = (->); c = (->)

         expect(-> new Execution a, b, c).to.not.throwException()
         expect(   new Execution a, b, c).to.be.a Native

         expect(  (new Execution a, b, c).bits).to.have.length 3
         expect(  (new Execution a, b, c).bits).to.eql [a, b, c]

      describe '::complete', ->
         it 'knows whether the Native is complete', ->
            ex = new Execution ->
            expect(ex.complete()).to.be false

            ex.bits.length = 0
            expect(ex.complete()).to.be true

      describe '::clone', ->
         it 'creates a new Native', ->
            ex = new Execution ->
            expect(-> ex.clone()).to.not.throwException()
            expect(   ex.clone()).to.be.a Native

         it '... that has the same bits after cloning', ->
            funcs =
               one: ->
               two: ->
               three: ->
            ex = new Execution funcs.one, funcs.two, funcs.three

            clone = ex.clone()
            expect(clone.bits).to.not.be ex.bits
            expect(clone.bits).to.eql [funcs.one, funcs.two, funcs.three]

         # FIXME: Why did I expect this to behave differently when it was a `Native`!?
         it.skip 'shares locals with created clones', ->
            ex = new Execution ->
            clone = ex.clone()

            expect(clone.locals).to.equal ex.locals

      # ### Native: Utility / convenience methods and functions ###

      describe '.synchronous', ->
         synchronous = Native.synchronous

         it 'accepts a function', ->
            expect(   synchronous).to.be.ok()
            expect(-> synchronous ->).to.not.throwException()

         it 'creates a new Native', ->
            expect(synchronous ->).to.be.a Native

         it 'adds bits corresponding to the arity of the function', ->
            expect( (synchronous (a, b)->)       .bits).to.have.length 3
            expect( (synchronous (a, b, c, d)->) .bits).to.have.length 5

         describe '~ Produces bits that,', ->
            a = null
            beforeEach -> a =
               caller: new Execution
               thing:  new Label 'foo'

            call = (it, response)->
               bit = it.advance response
               bit.call it, response

            it 'are Functions', ->
               exe = synchronous (a, b, c)->
               expect(exe.bits[0]).to.be.a Function
               expect(exe.bits[1]).to.be.a Function
               expect(exe.bits[2]).to.be.a Function
               expect(exe.bits[3]).to.be.a Function

            it 'mostly expect a caller and value', ->
               exe = synchronous (a, b, c)->
               expect(exe.bits[1]).to.have.length 2
               expect(exe.bits[2]).to.have.length 2

            it 'the first of which expects only value-to-become-caller', ->
               exe = synchronous (a, b, c)->
               expect(exe.bits[0]).to.have.length 1

            # FIXME: lodash's `_.partial` doesn't export a correct `length`, nor does it provide
            #        access to the original, wrapped `Function`; I don't know how to test this.
            it.skip 'the last of which *additionally* expects several other arguments', ->
               body = (a, b, c)->
               exe  = synchronous body
               expect(exe.bits[3]).to.have.length 4 + 1

            it 'can be invoked with a caller', ->
               exe = synchronous (a, b, c)->
               sinon.spy a.caller, 'queue'

               expect(-> call exe, a.caller).to.not.throwException()
               expect(a.caller.queue).was.calledWith __ params: [exe]

            it 'can be invoked with further parameters', ->
               exe = synchronous (a, b, c)->
               sinon.spy a.caller, 'queue'
               call exe, a.caller

               expect(-> call exe, a.thing).to.not.throwException()
               expect(-> call exe, a.thing).to.not.throwException()

               expect(a.caller.queue).was.calledWith __ params: [exe]
               expect(a.caller.queue).was.calledThrice()

            it 'are each provided the `caller` passed to the first bit', ->
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

            it 'resume the `caller` after consuming an argument', ->
               exe = synchronous (a, b, c)->
               queue = sinon.spy a.caller, 'queue'

               call exe, a.caller
               expect(queue.callCount).to.be 1
               expect(queue.thisValues[0]).to.be a.caller
               expect(queue.args[0][0].params).to.contain exe

               call exe, new Label 123
               expect(queue.callCount).to.be 2
               expect(queue.thisValues[1]).to.be a.caller
               expect(queue.args[1][0].params).to.contain exe

               call exe, new Label 456
               expect(queue.callCount).to.be 3
               expect(queue.thisValues[2]).to.be a.caller
               expect(queue.args[2][0].params).to.contain exe

              #call exe, new Label 456

            it 'do not re-stage the `caller` after all coproduction if there is no result', ->
               result = new Label "A result!"
               exe = synchronous (a, b)->
               queue = sinon.spy a.caller, 'queue'

               call exe, a.caller
               expect(queue.callCount).to.be 1
               expect(queue.thisValues[0]).to.be a.caller
               expect(queue.args[0][0].params).to.contain exe

               call exe, new Label 123
               expect(queue.callCount).to.be 2
               expect(queue.thisValues[1]).to.be a.caller
               expect(queue.args[1][0].params).to.contain exe

               call exe, new Label 456
               expect(queue.callCount).to.not.be 3

            it 're-stage the `caller` after all coproduction if a result is returned', ->
               result = new Label "A result!"
               exe = synchronous (a)-> return result
               queue = sinon.spy a.caller, 'queue'

               call exe, a.caller
               expect(queue.callCount).to.be 1
               expect(queue.thisValues[0]).to.be a.caller
               expect(queue.args[0][0].params).to.contain exe

               call exe, new Label 123
               expect(queue.callCount).to.be 2
               expect(queue.thisValues[1]).to.be a.caller
               expect(queue.args[1][0].params).to.contain result

            it 're-stage the `caller` immediately if no arguments is required', ->
               queue = sinon.spy a.caller, 'queue'
               result = new Label "A result!"
               exe = synchronous -> return result

               call exe, a.caller
               expect(queue.callCount).to.be 1
               expect(queue.thisValues[0]).to.be a.caller
               expect(queue.args[0][0].params).to.contain result

            it 'call the passed function exactly once, when exhausted', ->
               some_function = sinon.spy (a, b, c)->
               exe = synchronous some_function

               call exe, a.caller
               call exe, new Label 123
               call exe, new Label 456
               call exe, new Label 789

               expect(some_function).was.calledOnce()

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

               expect(some_function).was.calledWithExactly things.first, things.second, things.third

            it 'inject context into the passed function', ->
               some_function = sinon.spy (arg)->
               exe = synchronous some_function

               call exe, a.caller
               call exe, a.thing

               expect(some_function.firstCall.thisValue).to.have.property 'caller'
               expect(some_function.firstCall.thisValue.caller).to.be.an Execution
               expect(some_function.firstCall.thisValue.caller).to.be a.caller

               expect(some_function.firstCall.thisValue).to.have.property 'execution'
               expect(some_function.firstCall.thisValue.execution).to.be.an Execution
               expect(some_function.firstCall.thisValue.execution).to.be exe


   # ### Execution: Supporting types ###

   describe 'Operation', -> # ---- ---- ---- ---- ----                                     Operation
      it 'consists of of a stringly-typed operation,', ->
         expect(-> new Operation 'foo').to.not.throwError()

      it 'can have some arguments', ->
         expect(-> new Operation 'foo', new Thing, new Thing).to.not.throwError()

      it 'maintains a global map of known operations', ->
         expect(Operation.operations).to.be.ok()
         expect(Operation.operations).to.be.an 'object'

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

   # ### Execution: Available operations ###

   describe "~ The 'advance' operation", -> # ---- ---- ---- ---- ----                Ops['advance']
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

      it "clones an Combination's receiver", sinon.test ->
         a_subject = new Label 'foo'
         an_exec = new Execution parse '_ bar'
         a_receiver = new Native
         @spy a_subject.receiver, 'clone'

         an_exec.advance()

         op = new Operation 'advance', new Thing
         op.perform an_exec

         expect(a_subject.receiver.clone).was.calledOnce()
         expect(a_subject.receiver.ops).to.be.empty()

      it 'queues a further advancement operation for that receiver-clone', sinon.test ->
         an_exec = new Execution (new Sequence)
         a_subject = new Thing; a_message = new Thing
         a_receiver = new Native

         @stub(an_exec, 'advance').returns new Combination a_subject, a_message
         @stub(a_subject.receiver, 'clone').returns a_receiver

         op = new Operation 'advance', new Thing
         op.perform an_exec

         expect(a_receiver.ops).to.not.be.empty()
         expect(a_receiver.ops[0].params).to.not.be.empty()

         params = a_receiver.ops[0].params[0]
         expect(params.at 0).to.be an_exec
         expect(params.at 1).to.be a_subject
         expect(params.at 2).to.be a_message

      it 'uses locals at the edges of expressions', sinon.test ->
         @spy Label::receiver, 'clone'
         an_exec = new Execution parse 'foo []'

         op = new Operation 'advance', new Thing
         op.perform an_exec

         receiver = Label::receiver.clone.firstCall.returnValue
         expect(receiver.ops.length).to.be.above 0
         expect(receiver.ops[0].params).to.not.be.empty()

         params = receiver.ops[0].params[0]
         expect(params.at 1).to.be an_exec.locals

   describe "~ The 'adopt' operation", -> # ---- ---- ---- ---- ----                    Ops['adopt']
      it 'exists'
      it 'does things'
