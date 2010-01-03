// A `bool` is, to be absolutely explicit, simply a unique object, in this
// interpreter implementation. It really exists to serve no purpose, except as
// a common ancestor of `true`, `false`, and `void`. Thus, the single shared
// functionality of those elements, is that they cannot be duplicated, begat,
// or replaced in any way. Hence, `paws.bool` implements that functionality.
return (function(){ var bool;
  bool = paws.tuple.beget();
  
  bool.errors = {
    unique: new(Error)("Bool values are unique, and may not be inherited")
  };
  
  bool.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    that = this;
    (function(){ var primitive;
      // These are private methods. Do not use them; use `bool.primitive()`
      // instead.
      that._primitive = function () { return primitive };
      that._setPrimitive = function (val) { primitive = new(Boolean)(val).valueOf() };
    })();
    
    if (typeof blueprint           !== 'undefined' &&
        typeof blueprint.primitive !== 'undefined' ) {
      this._setPrimitive(blueprint.primitive) };
  };
  
  
  // ==================
  // = JavaScript API =
  // ==================
  
  // Returns the primitive associated with this lists’s native implementation
  bool.primitive = function () {
    return this._primitive()
  };
  
  (function(){ var undefined;
    bool.constructor({ primitive : undefined });
    
    bool['true'] = bool.beget({ primitive : true });
    bool['false'] = bool.beget({ primitive : false });
    bool['void'] = bool.beget({ primitive : null });
  })();
  
  bool.beget = function () { throw(bool.errors.unique) };
  
  // TODO: Implement `lookup()` on `void`, and make it act like a routine.
  
  return bool;
})()
