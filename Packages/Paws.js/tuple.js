var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var tuple;
  tuple = paws.list.beget();
  
  tuple.errors = {
    immutable: new(Error)("Tuples may not be modified after creation")
  };
  
  tuple.constructor = function (blueprint) { var contents;
    // We pop `contents` off of the blueprint before passing it up, because
    // `list.constructor` will try to `this.set()`, which we block.
    if (typeof blueprint          !== 'undefined' &&
        typeof blueprint.contents !== 'undefined' ) {
      contents = blueprint.contents;
          delete blueprint.contents;
    };
    
    paws.list.constructor.apply(this, arguments);
    
    if (typeof contents !== 'undefined') {
      for (var a = contents, l = a.length, i = 0, element = a[i];
               i < l; element = a[++i]) {
        paws.list.set.apply(this, [i + 1, element]) } };
  };
  
  // Simply informs the user that tuples cannot be modified.
  // 
  // FIXME: `infrastructure tuple` cannot be extended in libspace via
  //        inheritance, for obvious reasons. Construct a workaround.
  tuple.set = function (index, listObject) {
    throw(tuple.errors.immutable);
  };
  
  // `tuple` *is* `infrastructure tuple`. Thus, *it* needs to be initialized
  // properly.
  tuple.constructor();
  
  return tuple;
})();
