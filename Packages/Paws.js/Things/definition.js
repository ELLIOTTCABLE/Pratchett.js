return (function(){ var definition, rootDefinition;
  rootDefinition = [
    paws.string.beget({ nate : '' }),
    paws.bool['null']
  ];
  definition = paws.tuple.beget({ content : rootDefinition });
  
  definition.errors = {
    invalidName: new(Error)("The first element of a definition must be an " +
                            "`infrastructure string`"),
    invalidStructure: new(Error)("A definition must contain either two or " +
                                 "three elements: name, value, and an " +
                                 "optional metadata list")
  };
  
  definition.constructor = function (blueprint) { var keys = [], values = [], me;
    me = arguments.callee;
    
    // Hell, definitions are really just tuples that are a bit stricter about
    // their content
    if ( typeof blueprint         !== 'undefined' &&
         typeof blueprint.content !== 'undefined' ) {
      if (blueprint.content instanceof Array) {
        
        if (!paws.string.isPrototypeOf(blueprint.content[0]) &&
            !paws.string === blueprint.content[0]) {
          throw(definition.errors.invalidName) };
        if (blueprint.content.length > 3 || blueprint.content.length < 2) {
          throw(definition.errors.invalidStructure) };
        
        if (blueprint.content.length === 2) {
          blueprint.content.push(paws.list.beget()) };
        
      } else {
        
        for(key in blueprint.content) {
          keys.unshift(key); values.unshift(blueprint.content[key]) };
        blueprint.content = [keys[0], values[0]];
        
        me.apply(this, arguments); return;
        
      } };
    
    paws.tuple.constructor.apply(this, arguments);
  };
  
  // `tuple` *is* `infrastructure tuple`. Thus, *it* needs to be initialized
  // properly.
  //--
  // FIXME: Is running `paws.tuple.constructor` twice dangerous? Because we
  //        already ran it above, when `beget()`ing `paws.definition` from
  //        `paws.tuple`.
  definition.constructor({ content : rootDefinition });
  
  return definition;
})()
