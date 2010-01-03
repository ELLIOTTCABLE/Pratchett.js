return (function(){ var scope;
  scope = paws.list.beget();
  
  scope.errors = {
    invalidEnclosing: new(Error)("Enclosing scopes must be `paws.scope`s")
  };
  
  scope.constructor = function (blueprint) {
    paws.list.constructor.apply(this, arguments);
    
    if (typeof blueprint           !== 'undefined' &&
        typeof blueprint.enclosing !== 'undefined') {
      if (!scope.isPrototypeOf(blueprint.enclosing)) {
        throw(scope.errors.invalidEnclosing) };
      this.enclosing = blueprint.enclosing;
    };
    
    this.assign(paws.string.beget('locals'), this);
  };
  
  scope.constructor();
  
  return scope;
})()
