var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var paws;
  paws = new(Object);
  
  // FIXME: Huge, annoying problem. Since inheritance is implemented libspace,
  //        none of the primatives will provide inheritance. That is,
  //        `infrastructure tuple` won’t properly inherit from `infrastructure
  //        list`, and so on and so forth.
  
        paws.list = from.relative('Things/list.js').export({ paws : paws }).wait();
       paws.tuple = from.relative('Things/tuple.js').export({ paws : paws }).wait();
        paws.bool = from.relative('Things/bool.js').export({ paws : paws }).wait();
     paws['true'] = paws.bool['true'];
    paws['false'] = paws.bool['false'];
     paws['null'] = paws.bool['null'];
     paws.numeric = from.relative('Things/numeric.js').export({ paws : paws }).wait();
      paws.string = from.relative('Things/string.js').export({ paws : paws }).wait();
  paws.definition = from.relative('Things/definition.js').export({ paws : paws }).wait();
  
       paws.scope = from.relative('Things/scope.js').export({ paws : paws }).wait();
     paws.routine = from.relative('Things/routine.js').export({ paws : paws }).wait();
  
  return paws;
})();
