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
    
    this.scope = paws.scope.beget();
  };
  
  // ‘Runs’ a routine; either farming out the (native) implementation, or
  // passing the AST to `routine.interpret()`.
  routine.run = function () {
    if (typeof this.nate !== 'undefined') { this.nate.apply(this, arguments) }
                                     else { this.interpret(arguments) }
  };
  
  return routine;
})()
