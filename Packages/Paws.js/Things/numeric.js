return (function(){ var numeric, table, inheritedBeget;
  // FIXME: see the FIXME at the top of `string.js`. Same problems apply to
  //        the globally-unique `infrastructure numeric`.
  numeric = paws.tuple.beget();
  
  numeric.errors = {
    preexistent: new(Error)("That `numeric` already exists in the system; " +
                            "`numeric`s must be globally unique"),
    isNotANumber: new(Error)("`numeric`s cannot be created with non-numeric " +
                             "values")
  };
  
  // `infrastructure numeric` objects are intended to be globally unique, a lá
  // Ruby’s ‘symbols.’ Hence, we stuff them into a table when creating them.
  table = new(Object);
  
  numeric.beget = function (blueprint) { var memoized;
    // This would normally be preformed in the `constructor`, but we need to
    // pull out `primitive` to check for a memoized version.
    if (typeof blueprint === 'number') {
      blueprint = { primitive : blueprint } };
    
    if (typeof blueprint           !== 'undefined' &&
        typeof blueprint.primitive !== 'undefined' ) {
      if (Number.isANumber(blueprint.primitive)) {
        memoized = table[ (new(Number)(blueprint.primitive)).valueOf() ];
        if (typeof memoized !== 'undefined') { return memoized }; }
      else { throw(numeric.errors.isNotANumber) } };
    
    return paws.list.beget.apply(this, arguments);
  };
  
  numeric.constructor = function (blueprint) { var that;
    paws.tuple.constructor.apply(this, arguments);
    
    that = this;
    (function(){ var primitive;
      // These are private methods. Do not use them; use `numeric.primitive()`
      // instead.
      that._primitive = function () { return primitive };
      that._setPrimitive = function (val) {
        if (typeof primitive !== 'undefined') {
          delete table[primitive] };
        
        primitive = new(Number)(val).valueOf();
        
        if (typeof table[primitive] !== 'undefined') {
          throw(numeric.errors.preexistent) };
        table[primitive] = this;
      };
    })();
    
    if (typeof blueprint           !== 'undefined' &&
        typeof blueprint.primitive !== 'undefined' ) {
      this._setPrimitive(blueprint.primitive) };
  };
  
  numeric._lens = function (eyes, styles) {
    return eyes.stylize(this._primitive().toString(), styles.number, styles) };
  
  
  // ==================
  // = JavaScript API =
  // ==================
  
  // Returns the primitive associated with this lists’s native implementation
  numeric.primitive = function () {
    return this._primitive()
  };
  
  numeric.constructor(0);
  
  return numeric;
})()
