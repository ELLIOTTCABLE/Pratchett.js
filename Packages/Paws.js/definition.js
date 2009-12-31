var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var definition, rootDefinition;
  rootDefinition = [
    paws.string.beget({ body : '' }),
    paws['null'],
    paws.list.beget()
  ];
  definition = paws.tuple.beget({ content : rootDefinition });
  
  definition.errors = {
    nameError: new(Error)("The first element of a definition must be a string"),
    structureError: new(Error)("A definition must contain either two or " +
                               "three elements: name, value, and an " +
                               "optional metadata list")
  };
  
  definition.constructor = function (blueprint) {
    // Hell, definitions are really just tuples that are a bit stricter about
    // their content
    if ( typeof blueprint         !== 'undefined' &&
         typeof blueprint.content !== 'undefined' ) {
      if (!paws.string.isPrototypeOf(blueprint.content[0]) &&
          !paws.string === blueprint.content[0]) {
        throw(definition.errors.nameError) };
      if (blueprint.content.length > 4 || blueprint.content.length < 3) {
        throw(definition.errors.structureError) };
    };
    
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
})();
