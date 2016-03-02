expect  = require 'expect.js'
Paws = require '../Source/Paws.coffee'
_ = Paws.utilities

# That's right, I'm about to trod *all* over your globals. 🐘
globals = (->@)()

globals.createInstanceContainer = (set_name)->    # Oooo. Smells like Java.
   globals[set_name] = createTestingInstance = (type, args...)->
      unless type.name?
         throw new TypeError "Testing-instances require a constructor with a `name` property`."
      globals[set_name][type.name.toLowerCase()] = new type(args...)

   createTestingInstance.reset = _.partial createInstanceContainer, set_name

beforeEach ->
   createInstanceContainer 'a'
   createInstanceContainer 'an'
   createInstanceContainer 'another'
   createInstanceContainer 'some'

Assertion = expect.Assertion
i = expect.stringify

Assertion::owned = ->
   expect(@obj).to.be.a(Paws.Relation);

   this.assert @obj.owns,
      (-> 'expected ' + i(@obj) + ' to be owning' ),
      (-> 'expected ' + i(@obj) + ' to not be owning' )
