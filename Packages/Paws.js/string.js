var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

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
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.body !== 'undefined' ) {
      memoized = table[ (new(String)(blueprint.body)).valueOf() ];
      if (typeof memoized !== 'undefined') { return memoized };
    };
    
    return Object.prototype.beget.apply(this, arguments);
  };
  
  string.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    // This is the unique per-object lexical scope in which to store our
    // private data
    that = this;
    (function(){ var body;
      // These are private methods. Do not use them; use `string.body()` and
      // `string.bodyLength()` instead.
      that._body = function () { return body };
      that._setBody = function (val) { var bodyPrimative;
        if (typeof body !== 'undefined') {
          delete table[body.valueOf()] };
        
        body = new(String)(val);
        
        bodyPrimative = body.valueOf();
        if (typeof table[bodyPrimative] !== 'undefined') {
          throw(string.errors.preexistent) };
        table[bodyPrimative] = this;
      };
      that._bodyLength = function () { return body.length };
    })();
    
    if (typeof blueprint      !== 'undefined' &&
        typeof blueprint.body !== 'undefined' ) {
      this._setBody(blueprint.body) };
  };
  
  // Retreives the natively-implemented body
  string.body = function () {
    return this._body()
  };
  
  // Returns the length of the native string
  string.bodyLength = function () {
    return this._bodyLength()
  };
  
  // `list` *is* our root `infrastructure list`. Thus, *it* needs to be
  // initialized properly.
  string.constructor({ body : '' });
  
  return string;
})();
