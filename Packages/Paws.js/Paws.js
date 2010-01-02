var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait();

return (function(){ var paws, things;
  paws = new(Object);
  
  // FIXME: Huge, annoying problem. Since inheritance is implemented libspace,
  //        none of the primatives will provide inheritance. That is,
  //        `infrastructure tuple` won’t properly inherit from `infrastructure
  //        list`, and so on and so forth.
  
  things = ['list'
,   'tuple'
,   'bool'
,   'numeric'
,   'string'
,   'definition'
,   'scope'
,   'routine'
  ];
  
  for (var a = things, l = a.length, i = 0, element = a[i];
           i < l; element = a[++i]) {
    paws[element] = from.relative('Things/'+element+'.js')
      .export({ paws : paws }).wait() };
  
  return paws;
})();
