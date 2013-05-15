expect = require 'expect.js'

describe "Paws' utilities", ->
   
   utilities = require '../Source/utilities'
   it 'should exist', ->
      expect(utilities).to.be.ok()
   
   run = utilities.runInNewContext
   describe '#runInNewContext', ->
      it 'should return a value', ->
         expect(run '42').to.be 42
      
      it 'should use a new JavaScript execution-context', ->
         expect(run 'Object').to.not.be(Object)
         expect(run 'new Object').to.not.be.an(Object)
   
   if process.browser then describe '#runInNewContext (client)', ->
      it 'should not leave trash in the DOM', ->
         iframes = window.document.getElementsByTagName 'iframe'
         expect(iframes).to.be.empty()
