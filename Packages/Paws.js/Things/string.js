return (function(){ var string, table, inheritedBeget;
  // FIXME: For now, `infrastructure string`s are not only immutable, but are
  //        also `tuple`s, which means they can’t be given any list elements.
  //        I *think* this is important, as they are globally unique; putting
  //        something in a `infrastructure string` would make it accessible
  //        *everywhere*. I’m trying to avoid that sort of global state.
  //        
  //        However, I’m certainly not sure, so… if you’ve got any good
  //        arguments for inheriting this from `infrastructure list` instead,
  //        I’d be glad to hear them.
  string = paws.tuple.beget();
  
  string.errors = {
    preexistent: new(Error)("That string already exists in the system; " +
                            "strings must be globally unique")
  };
  
  // `infrastructure string` objects are intended to be globally unique, a lá
  // Ruby’s ‘symbols.’ Hence, we stuff them into a table when creating them.
  table = new(Object);
  
  string.beget = function (blueprint) { var memoized;
    // This would normally be preformed in the `constructor`, but we need to
    // pull out `nate` to check for a memoized version.
    if (typeof blueprint === 'string') { blueprint = { nate : blueprint } };
    
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.nate !== 'undefined' ) {
      memoized = table[ (new(String)(blueprint.nate)).valueOf() ];
      if (typeof memoized !== 'undefined') { return memoized };
    };
    
    return Object.prototype.beget.apply(this, arguments);
  };
  
  string.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    // This is the unique per-object lexical scope in which to store our
    // private data
    that = this;
    (function(){ var nate;
      // These are private methods. Do not use them; use `string.nate()` and
      // `string.nateLength()` instead.
      that._nate = function () { return nate };
      that._setNate = function (val) { var natePrimative;
        if (typeof nate !== 'undefined') {
          delete table[nate.valueOf()] };
        
        nate = new(String)(val);
        
        natePrimative = nate.valueOf();
        if (typeof table[natePrimative] !== 'undefined') {
          throw(string.errors.preexistent) };
        table[natePrimative] = this;
      };
      that._nateLength = function () { return nate.length };
    })();
    
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.nate !== 'undefined' ) {
      this._setNate(blueprint.nate) };
  };
  
  // Retreives the natively-implemented nate
  string.nate = function () {
    return this._nate()
  };
  
  // Returns the length of the native string
  string.nateLength = function () {
    return this._nateLength()
  };
  
  // `list` *is* our root `infrastructure list`. Thus, *it* needs to be
  // initialized properly.
  string.constructor({ nate : '' });
  
  return string;
})()
