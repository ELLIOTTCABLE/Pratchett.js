expect = require 'expect.js'

describe "Paws' utilities", ->
   
   utilities = require '../Source/utilities'
   it 'should exist', ->
      expect(utilities).to.be.ok()
   
   run = utilities.runInNewContext
   describe '#runInNewContext', ->
      it 'should not error out', ->
         expect(-> run 'true')    .to.not.throwException()
         expect(-> run 'Function').to.not.throwException()
      
      it 'should return values', ->
         expect(run '42').to.be 42
      it 'should return functions', ->
         expect(run 'Function').to.be.a 'function'
      
      it 'should use a new JavaScript execution-context', ->
         # FIXME: The following test currently fails on Testling, for reasons unknown.
         expect(run 'Object').to.not.be Object
         expect(run 'new Object').to.not.be.an Object
         
         expect(run 'Function').to.not.be Function
         expect(run 'new Object').to.not.be.an Object
   
   if process.browser then describe '#runInNewContext (client)', ->
      it 'should not leave trash in the DOM', ->
         iframes = window.document.getElementsByTagName 'iframe'
         expect(iframes).to.be.empty()
