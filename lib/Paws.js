return (function(){
  var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait(),
       paws = new(Object);
  
  paws.routine = (function(){
    // UHH: Should this be begat from `paws.object`? How are we going to
    //      handle inheritance on the JavaScript side, anyway? I suppose we
    //      want the basic objects on a `paws.object` available on a
    //      `paws.routine`. Then again, a `paws.routine` should really have an
    //      attached `paws.object` *anyhow*… hrm.
    var routine = new(Object);
    
    // Constructs a `paws.routine`, given a routine blueprint. If a `body`
    // element is available on the blueprint, that will be used as the
    // `routine.body`.
    routine.constructor = function (blueprint) {
      if (typeof blueprint      !== 'undefined' &&
          typeof blueprint.body !== 'undefined') {
             this.body = blueprint.body  }
      else { this.body = ['routine', []] }
    };
    
    // ‘Runs’ a routine; either farming out the (native) implementation, or
    // passing the AST to `routine.interpret()`.
    routine.run = function () {
      if (typeof this.body === 'function') { this.body.apply(this, arguments) }
                                      else { this.interpret(arguments) }
    };
    
    // Iterates over an AST stored in a `paws.routine`’s `routine.body`,
    // farming out lookups.
    // --
    // TODO: EVERYTHING
    // TODO: Routine calls with arguments
    // TODO: Infix operators (UGH, I know, STFU)
    routine.interpret = function (argumentObject) {
      
    };
    
    return routine;
  })();
  
  return paws;
})()
