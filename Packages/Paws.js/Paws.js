var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var paws;
  paws = new(Object);
  
     paws.list = from.relative('list.js').wait();
  paws.routine = from.relative('routine.js').wait();
  
  return paws;
})();
