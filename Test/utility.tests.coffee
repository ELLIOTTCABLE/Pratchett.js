expect = require 'expect.js'

Paws   = require "../Source/Paws.coffee"


describe "Paws' utilities:", ->
   _ = utilities = require "../Source/utilities.coffee"

   it 'exist', ->
      expect(utilities).to.be.ok()

   it "includes Node's `util` package", ->
      expect(utilities.node).to.be.ok()
      expect(utilities.node).to.have.key 'inherits'

   describe '.isShallowEqual', ->
      it 'exists', ->
         expect(_.isShallowEqual).to.be.ok()
         expect(_.isShallowEqual).to.be.a 'function'

      it 'succeeds two equal objects', ->
         it = {a: 123}; other = {a: 123}

         expect(it).to.not.be other
         expect(it).to.eql other
         expect(_.isShallowEqual it, other).to.be yes

      it 'fails two different objects', ->
         it = {a: 123}; other = {a: 456}
         expect(_.isShallowEqual it, other).to.be no

      it 'fails when the second is missing a property', ->
         it = {a: 123, b: 456}; other = {a: 123}
         expect(_.isShallowEqual it, other).to.be no

      it 'fails when the first is missing a property', ->
         it = {a: 123}; other = {a: 123, b: 456}
         expect(_.isShallowEqual it, other).to.be no

      it 'succeeds when a property is NaN', ->
         it = {a: 123, b: NaN}; other = {a: 123, b: NaN}
         expect(_.isShallowEqual it, other).to.be yes

      it 'succeeds when a property is undefined', ->
         it = {a: 123, b: undefined}; other = {a: 123, b: undefined}
         expect(_.isShallowEqual it, other).to.be yes

      it 'fails when a property is undefined in one, and missing in the other', ->
         it = {a: 123, b: undefined}; other = {a: 123}
         expect(_.isShallowEqual it, other).to.be no


   describe '.selfify', -> # ---- ---- ---- ---- ----                                      selfify()
      composed = utilities.selfify -> 'whee'
      it 'always returns the `this` value', ->
         object = new Object
         expect(composed.call object).to.be object

   describe '.modifier', -> # ---- ---- ---- ---- ----                                    modifier()
      composed = utilities.modifier (foo)-> return 'yep' if foo == 'foo'
      it 'returns the return-value of the body ...', ->
         expect(composed 'foo').to.be 'yep'
      it '... unless the body returns nothing', ->
         object = new Object
         expect(composed object).to.be object


   describe '.constructify', -> # ---- ---- ---- ---- ----                            constructify()
      constructify = _.constructify

      it '... basically functions', ->
         expect(constructify).to.be.ok()
         expect(-> constructify ->).to.not.throwException()
         expect(constructify ->).to.be.a 'function'
         Ctor = constructify ->
         expect(-> new Ctor).to.not.throwException()
         class Klass
            constructor: constructify ->
         expect(-> new Klass).to.not.throwException()

      it 'accepts options', ->
         expect(-> constructify(foo: 'bar') ->).to.not.throwException()

      it 'returns a *new* function, not the constructor-body passed to it', ->
         body = ->
         Ctor = constructify body
         expect(constructify).to.not.be body
         class Klass
            constructor: constructify body
         expect(Klass).to.not.be body

      it 'passes the `arguments` object intact', ->
         Ctor = constructify(arguments: 'intact') (args)->
            @caller = args.callee.caller
         it = null; func = null
         expect(-> (func = -> it = new Ctor)() ).to.not.throwException()
         expect(it).to.have.property 'caller'
         expect(it.caller).to.be func

      it "causes constructors it's called on to always return instances", ->
         Ctor = constructify ->
         expect(new Ctor)  .to.be.a Ctor
         expect(    Ctor()).to.be.a Ctor
         expect(new Ctor().constructor).to.be Ctor
         expect(    Ctor().constructor).to.be Ctor
         class Klass
            constructor: constructify ->
         expect(new Klass)  .to.be.a Klass
         expect(    Klass()).to.be.a Klass

      it.skip 'uses a really hacky system that requires you not to call the wrapper before CoffeeScript does', ->
         Paws.notice "-- SILENCING ALL DEBUGGING OUTPUT!"
         verbosity = Paws.debugging.verbosity(); Paws.debugging.VERBOSE 2

         Ctor = null
         class Klass
            constructor: Ctor = constructify ->
         Ctor()
         expect(-> new Klass).to.throwException()

         Paws.debugging.VERBOSE verbosity
         Paws.wtf "-- Resuming debugging output"

      it 'can be called multiple times /reg', ->
         Ctor1 = constructify ->
         expect(-> new Ctor1).to.not.throwException()
         expect(-> new Ctor1).to.not.throwException()
         Ctor2 = constructify ->
         expect(-> Ctor2()).to.not.throwException()
         expect(-> Ctor2()).to.not.throwException()
         class Klass1
            constructor: constructify ->
         expect(-> new Klass1).to.not.throwException()
         expect(-> new Klass1).to.not.throwException()
         class Klass2
            constructor: constructify ->
         expect(-> Klass2()).to.not.throwException()
         expect(-> Klass2()).to.not.throwException()

      it 'executes the function-body passed to it, on new instances', ->
         Ctor = constructify -> @called = yes
         expect(new Ctor().called).to.be.ok()

      it "returns the return-value of the body, if it isn't nullish", ->
         Ctor = constructify (rv)-> return rv
         obj = new Object
         expect(new Ctor(obj)).to.be obj
         expect(    Ctor(obj)).to.be obj

      it 'returns the new instance, otherwise', ->
         Ctor = constructify (rv)-> return 123
         expect(new Ctor)  .not.to.be 123
         expect(    Ctor()).not.to.be 123
         expect(new Ctor)  .to.be.a Ctor
         expect(    Ctor()).to.be.a Ctor

      it 'can be configured to *always* return the instance', ->
         Ctor = constructify(return: this) -> return new Array
         expect(new Ctor()).not.to.be.an 'array'
         expect(    Ctor()).not.to.be.an 'array'

      it 'calls any ancestor that exists', ->
         Ancestor = constructify -> @ancestor_called = true
         class Parent extends Ancestor
            constructor: constructify -> @parent_called = true
         class Child extends Parent
            constructor: constructify -> @child_called = true

         expect(new Parent)  .to.be.an Ancestor
         expect(    Parent()).to.be.an Ancestor
         expect(new Child)  .to.be.an Ancestor
         expect(    Child()).to.be.an Ancestor
         expect(new Child)  .to.be.a Parent
         expect(    Child()).to.be.a Parent

         expect(new Parent)  .to.have.property 'ancestor_called'
         expect(    Parent()).to.have.property 'ancestor_called'
         expect(new Child)  .to.have.property 'ancestor_called'
         expect(    Child()).to.have.property 'ancestor_called'
         expect(new Child)  .to.have.property 'parent_called'
         expect(    Child()).to.have.property 'parent_called'

      it 'provides the name of the original constructor', ->
         class Klass
            constructor: constructify ->
         instance = new Klass
         # FIXME: Why is this commented out?
        #expect(instance.constructor.__name__).to.be 'Klass'

         instance = Klass()
         expect(instance.constructor.__name__).to.be 'Klass'


   describe '.parameterizable', -> # ---- ---- ---- ---- ----                      parameterizable()
      _.parameterizable class Whatever
         constructor: -> return this

      it 'creates a parameterizable constructor', ->
         constructor = new Whatever.with(foo: 'bar')
         expect(constructor).to.be.a 'function'
         expect(constructor()).to.be.a Whatever
         expect(constructor()._.foo).to.be 'bar'

      it 'provides parameterizable methods', ->
         what = new Whatever
         expect(what.with(foo: 'bar')).to.be what
         expect(what._.foo).to.be 'bar'

      it 'does not leave cruft around on the object', (complete)->
         what = new Whatever.with({})()
         setTimeout => # *Intentionally* using setTimeout instead of nextTick
            expect(what._).to.be undefined
            complete()
         , 0

   describe '.delegated', -> # ---- ---- ---- ---- ----                                  delegated()
      it 'creates definitions for super methods', ->
         class Delegatee
            operate: (arg)-> return this: this, argument: arg

         Something = _.delegated('a_member', Delegatee) class Something
            constructor: (@a_member)->

         expect(Something::operate).to.be.ok()

      it 'delegates calls to missing methods to those super-methods', ->
         class Delegatee
            operate: (arg)-> return this: this, argument: arg

         Something = utilities.delegated('a_member', Delegatee) class Something
            constructor: (@a_member)->

         expect(Something::operate).to.be.ok()

         foo = new Delegatee
         instance = new Something(foo)
         expect(-> instance.operate()).to.not.throwException()
         expect(instance.operate('bar').this).to.be foo
         expect(instance.operate('bar').argument).to.be 'bar'

      it 'does not shadow re-implemented methods', ->
         correct_shadowed = ->
         class Delegatee
            shadowed: ->

         Something = utilities.delegated('foo', Delegatee) class Something
            shadowed: correct_shadowed
            constructor: (@foo)->

         expect(Something::shadowed).to.be correct_shadowed

      it 'does not delegate non-function properties', ->
         class Delegatee
            somebody: 'Micah'
         correct_shadowed = ->

         Something = utilities.delegated('foo', Delegatee) class Something
            constructor: (@foo)->

         expect(Object.getOwnPropertyNames Something::).to.not.contain 'somebody'

      it 'delegates to ancestors', ->
         class Ancestor
            operate: (arg)-> return this: this, argument: arg

         class Delegatee extends Ancestor

         Something = utilities.delegated('a_member', Delegatee) class Something
            constructor: (@a_member)->

         expect(Something::operate).to.be.ok()

         foo = new Delegatee
         instance = new Something(foo)
         expect(instance.operate('bar').this).to.be foo
         expect(instance.operate('bar').argument).to.be 'bar'

      it 'handles built-ins well /reg', ->
         Something = utilities.delegated('stuff', Array) class Something
            constructor: (@stuff)->

         expect(Something::shift).to.be.ok()

         instance = new Something([1, 2, 3])
         expect(instance.shift()).to.be 1
         expect(instance.stuff).to.have.length 2
