// A `bool` is, to be absolutely explicit, simply a unique object, in this
// interpreter implementation. It really exists to serve no purpose, except as
// a common ancestor of `true`, `false`, and `null`. Thus, the single shared
// functionality of those elements, is that they cannot be duplicated, begat,
// or replaced in any way. Hence, `paws.bool` implements that functionality.
return (function(){ var bool;
  bool = paws.tuple.beget();
  
  bool.errors = {
    unique: new(Error)("Bool values are unique, and may not be inherited")
  };
  
  bool.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    // This is the unique per-object lexical scope in which to store our
    // private data
    that = this;
    (function(){ var nate;
      // These are private methods. Do not use them; use `bool.nate()` instead.
      that._nate = function () { return nate };
      that._setNate = function (val) { nate = new(Boolean)(val).valueOf() };
    })();
    
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.nate !== 'undefined' ) {
      this._setNate(blueprint.nate) };
  };
  
  // Retreives the natively-implemented nate
  bool.nate = function () {
    return this._nate()
  };
  
  (function(){ var undefined;
    bool.constructor({ nate : undefined });
    
    bool['true'] = bool.beget({ nate : true });
    bool['false'] = bool.beget({ nate : false });
    bool['null'] = bool.beget({ nate : null });
  })();
  
  bool.beget = function () { throw(bool.errors.unique) };
  
  // TODO: Implement `lookup()` on `null`, and make it act like a routine.
  
  return bool;
})()
