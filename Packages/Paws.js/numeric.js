var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var numeric, table, inheritedBeget;
  // FIXME: see the FIXME at the top of `string.js`. Same problems apply to
  //        the globally-unique `infrastructure numeric`.
  numeric = paws.tuple.beget();
  
  numeric.errors = {
    preexistent: new(Error)("That numeric already exists in the system; " +
                            "numeric must be globally unique")
  };
  
  // `infrastructure numeric` objects are intended to be globally unique, a lá
  // Ruby’s ‘symbols.’ Hence, we stuff them into a table when creating them.
  table = new(Object);
  
  numeric.beget = function (blueprint) { var memoized;
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.body !== 'undefined' ) {
      memoized = table[ (new(Number)(blueprint.body)).valueOf() ];
      if (typeof memoized !== 'undefined') { return memoized };
    };
    
    return Object.prototype.beget.apply(this, arguments);
  };
  
  numeric.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    // This is the unique per-object lexical scope in which to store our
    // private data
    that = this;
    (function(){ var body;
      // These are private methods. Do not use them; use `numeric.body()` and
      // `numeric` instead.
      that._body = function () { return body };
      that._setBody = function (val) { var bodyPrimative;
        if (typeof body !== 'undefined') {
          delete table[body.valueOf()] };
        
        body = new(Number)(val);
        
        bodyPrimative = body.valueOf();
        if (typeof table[bodyPrimative] !== 'undefined') {
          throw(numeric.errors.preexistent) };
        table[bodyPrimative] = this;
      };
    })();
    
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.body !== 'undefined' ) {
      this._setBody(blueprint.body) };
  };
  
  // Retreives the natively-implemented body
  numeric.body = function () {
    return this._body()
  };
  
  // `list` *is* our root `infrastructure list`. Thus, *it* needs to be
  // initialized properly.
  numeric.constructor({ body : 0 });
  
  return numeric;
})();
