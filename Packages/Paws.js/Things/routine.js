return (function(){ var routine;
  routine = paws.list.beget();
  
  routine.errors = {
    invalidBinding: new(Error)("Routines may only be bound to `list`s"),
    invalidArgument: new(Error)("Routines may only be called with a `list`"),
    invalidBody: new(Error)("Routines’ body must be a native `Function`, " +
                            "or an abstracted syntax tree")
  };
  
  // Constructs a `paws.routine`, given a routine blueprint. If a `body`
  // element is available on the blueprint, that will be used as the
  // routine’s implementation (be it an AST or native `Function`).
  routine.constructor = function (blueprint) { var that;
    paws.list.constructor.apply(this, arguments);
    
    that = this;
    (function(){ var body, binding;
      // These are private methods. Do not use them; use their public-API
      // equivalents instead.
      that._binding = function () { return binding };
      that._bind = function (list) { 
        if (!paws.list.isPrototypeOf(list)) {
          throw(routine.errors.invalidBinding) };
        binding = list;
      };
      
      that._setBody = function (val) {
        if (!val instanceof Array && typeof val !== 'function') {
          throw(routine.errors.invalidBody) }
        body = val;
      };
      that._call = function (argument) {
        if (!paws.list.isPrototypeOf(argument)) {
          throw(routine.errors.invalidArgument) };
        
        if (typeof body === 'function') {
          body.apply(binding, [argument, that]) }
        else { /* FIXME: What? */ };
      };
      
    })();
    
    this._bind(paws.bool['void']);
    
    if (typeof blueprint      !== 'undefined') {
      if (typeof blueprint === 'function') { this._setBody(blueprint) }
      else if (typeof blueprint.body !== 'undefined') {
        this._setBody(blueprint.body) }
      else { this._setBody([]) };
    };
    
    this.assign(paws.string.beget('scope'), paws.scope.beget());
  };
  
  routine._lens = function (eyes, styles) {
    return eyes.stylize('{}' + paws.list._lens.apply(this, arguments),
      styles.special, styles) };
  
  
  // ==================
  // = JavaScript API =
  // ==================
  
  // Executes a routine; either farming out the (native) implementation, or
  // passing the AST to `routine.interpret()`.
  // 
  // Native implementations will be called with `this` as the bound object,
  // and given `argument` as their first argument. The `paws.routine` object
  // itself will be handed over as the second argument, if the function needs
  // it.
  //-
  // TODO: Automatically handle native-returns from native routines
  routine.call = function (argument) { this._call(argument) };
  
  routine.constructor();
  
  return routine;
})()
