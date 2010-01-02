return (function(){ var routine;
  routine = paws.list.beget();
  
  // Constructs a `paws.routine`, given a routine blueprint. If a `nate`
  // element is available on the blueprint, that will be used as the
  // `routine.nate`. The same is true of `body`.
  routine.constructor = function (blueprint) {
    paws.list.constructor.apply(this, arguments);
    
    if        (typeof blueprint      !== 'undefined') {
      if      (typeof blueprint.nate !== 'undefined') {
          this.nate = blueprint.nate }
      else if (typeof blueprint.body !== 'undefined') {
          this.body = blueprint.body }
      else {
          this.body = ['routine', []] } };
    
    // FIXME: This should be defined *on the list*. Not on the JS `Object`.
    this.scope = paws.scope.beget();
    // FIXME: This should be private
    this.binding = paws['null'];
  };
  
  // Executes a routine; either farming out the (native) implementation, or
  // passing the AST to `routine.interpret()`.
  // 
  // Native implementations will be called with `this` as the bound object,
  // and given `argument` as their first argument. The `paws.routine` object
  // itself will be handed over as the second argument, if the function needs
  // it.
  //-
  // TODO: Automatically handle native-returns from native routines
  routine.call = function (argument) {
    if (typeof this.nate !== 'undefined') {
      this.nate.apply(this.binding, [argument, this]) }
    else { this.interpret(argument) }
  };
  
  return routine;
})()
