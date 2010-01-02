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
    // pull out `primitive` to check for a memoized version.
    if (typeof blueprint === 'string') { blueprint = { primitive : blueprint } };
    
    if (typeof blueprint           !== 'undefined' &&
        typeof blueprint.primitive !== 'undefined' ) {
      memoized = table[ (new(String)(blueprint.primitive)).valueOf() ];
      if (typeof memoized !== 'undefined') { return memoized };
    };
    
    return Object.prototype.beget.apply(this, arguments);
  };
  
  string.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    that = this;
    (function(){ var primitive;
      // These are private methods. Do not use them; use `string.primitive()`
      // and `string.characters()` instead.
      that._primitive = function () { return primitive };
      that._setPrimitive = function (val) {
        if (typeof primitive !== 'undefined') {
          delete table[primitive] };
        
        primitive = new(String)(val).valueOf();
        
        if (typeof table[primitive] !== 'undefined') {
          throw(string.errors.preexistent) };
        table[primitive] = this;
      };
      that._primitiveLength = function () { return primitive.length };
    })();
    
    if (typeof blueprint           !== 'undefined' &&
        typeof blueprint.primitive !== 'undefined' ) {
      this._setPrimitive(blueprint.primitive) };
  };
  
  // Returns the primitive associated with this lists’s native implementation
  string.primitive = function () {
    return this._primitive()
  };
  
  // Returns the length of the native string
  string.characters = function () {
    return paws.numeric.beget(this._primitiveLength())
  };
  
  string.constructor('');
  
  return string;
})()
