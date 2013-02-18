module.exports =
utilities =

   runInNewContext: do ->
      server = (source, context) ->
         require('vm').createScript(source).runInNewContext(context)
      
      client = (source, context) ->
      
      (source, context) ->
         (if process?.browser then client else server).apply this, arguments
