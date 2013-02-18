module.exports =
utilities =

   runInNewContext: do ->
      server = (source, context) ->
         #@browserify-ignore
         require('vm').createScript(source).runInNewContext(context)
      
      client = (source, context) ->
      
      return (source, context) ->
         (if process?.browser then client else server).apply this, arguments
