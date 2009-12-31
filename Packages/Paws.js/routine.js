var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var routine;
  // UHH: Should this be begat from `paws.object`? How are we going to
  //      handle inheritance on the JavaScript side, anyway? I suppose we
  //      want the basic objects on a `paws.object` available on a
  //      `paws.routine`. Then again, a `paws.routine` should really have an
  //      attached `paws.object` *anyhow*… hrm.
  routine = paws.list.beget();
  
  routine.errors = {
    invalidAST: new(Error)("Syntax tree contains invalid structure")
  };
  
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
  //--
  // TODO: *Do* something with argumentObject
  routine.interpret = function (argumentObject, ast) { var me, type;
    me = arguments.callee;
    
    if (typeof ast === 'undefined') { ast = this.body.slice(0) };
    
    // Routine ASTs must have an `('routine', …)` element as their root.
    if ((type = ast.shift()) !== 'routine') {
      throw(routines.errors.invalidAST) };
    
    for (var a = ast, l = a.length, i = 0, element = a[i];
             i < l; element = a[++i]) {
      // Routine ASTs may only currently have `('statement', …)` elements as
      // children.
      if (element[0] !== 'statement') {
        throw(routine.errors.invalidAST) };
      
      me.statement(element);
    };
  };
  
  // Interprets a statement in the context of this routine
  //--
  // TODO: Routine calls with arguments (*do* something with argumentObject)
  // TODO: Infix operators (UGH, I know, STFU)
  routine.interpret.statement = function (ast) { var me, type;
    me = arguments.callee, type = ast.shift();
    
    for (var a = ast, l = a.length, i = 0, element = a[i];
             i < l; element = a[++i]) {
      
      switch (element.shift()) {
        case 'word':
          // Wooo!
          process.stdio.write(JSON.stringify(element) + '\n');
          break;
        default: throw(routine.errors.invalidAST);
      }
    };
    
  };
  
  return routine;
})();
