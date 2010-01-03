return (function(){ var tuple;
  tuple = paws.list.beget();
  
  tuple.errors = {
    immutable: new(Error)("Tuples may not be modified after creation")
  };
  
  tuple.constructor = function (blueprint) { var content;
    // We pop `content` off of the blueprint before passing it up, because
    // `list.constructor` will try to `this.set()`, which we block.
    if ( typeof blueprint         !== 'undefined' &&
         typeof blueprint.content !== 'undefined' ) {
      content = blueprint.content;
         delete blueprint.content;
    };
    
    paws.list.constructor.apply(this, arguments);
    
    if (typeof content !== 'undefined') {
      for (var a = content, l = a.length, i = 0, element = a[i];
               i < l; element = a[++i]) {
        paws.list.set.apply(this, [paws.numeric.beget(i), element]) } };
  };
  
  
  // ==================
  // = JavaScript API =
  // ==================
  
  // Simply informs the user that tuples cannot be modified.
  //--
  // FIXME: `infrastructure tuple` cannot be extended in libspace via
  //        inheritance, for obvious reasons. Construct a workaround.
  tuple.set = function () {
    throw(tuple.errors.immutable);
  };
  
  tuple.constructor();
  
  return tuple;
})()
