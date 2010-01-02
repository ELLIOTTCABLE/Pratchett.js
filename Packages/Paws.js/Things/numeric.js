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
    // This would normally be preformed in the `constructor`, but we need to
    // pull out `nate` to check for a memoized version.
    if (typeof blueprint === 'number') { blueprint = { nate : blueprint } };
    
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.nate !== 'undefined' ) {
      memoized = table[ (new(Number)(blueprint.nate)).valueOf() ];
      if (typeof memoized !== 'undefined') { return memoized };
    };
    
    return Object.prototype.beget.apply(this, arguments);
  };
  
  numeric.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    // This is the unique per-object lexical scope in which to store our
    // private data
    that = this;
    (function(){ var nate;
      // These are private methods. Do not use them; use `numeric.nate()`
      // instead.
      that._nate = function () { return nate };
      that._setNate = function (val) { var natePrimitive;
        if (typeof nate !== 'undefined') {
          delete table[nate.valueOf()] };
        
        nate = new(Number)(val);
        
        natePrimative = nate.valueOf();
        if (typeof table[natePrimitive] !== 'undefined') {
          throw(numeric.errors.preexistent) };
        table[natePrimitive] = this;
      };
    })();
    
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.nate !== 'undefined' ) {
      this._setNate(blueprint.nate) };
  };
  
  // Retreives the natively-implemented nate
  numeric.nate = function () {
    return this._nate()
  };
  
  // `list` *is* our root `infrastructure list`. Thus, *it* needs to be
  // initialized properly.
  numeric.constructor({ nate : 0 });
  
  return numeric;
})()
