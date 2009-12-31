var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var paws;
  paws = new(Object);
  
        paws.list = from.relative('list.js').export({ paws : paws }).wait();
       paws.tuple = from.relative('tuple.js').export({ paws : paws }).wait();
      paws.string = from.relative('string.js').export({ paws : paws }).wait();
     paws.routine = from.relative('routine.js').export({ paws : paws }).wait();
  
  return paws;
})();
