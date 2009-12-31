var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var paws;
  paws = new(Object);
  
  // FIXME: Huge, annoying problem. Since inheritance is implemented libspace,
  //        none of the primatives will provide inheritance. That is,
  //        `infrastructure tuple` won’t properly inherit from `infrastructure
  //        list`, and so on and so forth.
  
        paws.list = from.relative('list.js').export({ paws : paws }).wait();
     paws['null'] = paws.list.beget(); // TODO: Implement actual `paws.null`.
       paws.tuple = from.relative('tuple.js').export({ paws : paws }).wait();
      paws.string = from.relative('string.js').export({ paws : paws }).wait();
  paws.definition = from.relative('definition.js').export({ paws : paws }).wait();
     paws.routine = from.relative('routine.js').export({ paws : paws }).wait();
  
  return paws;
})();
