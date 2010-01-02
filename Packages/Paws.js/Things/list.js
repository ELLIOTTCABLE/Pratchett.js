return (function(){ var list;
  list = new(Object);
  
  list.errors = {
    invalidChild: new(Error)("Lists may only contain lists as children")
  };
  
  list.constructor = function (blueprint) { var that, naughty;
    // This is the unique per-object lexical scope in which to store our
    // private data
    that = this;
    (function(){ var store;
      store = new(Array);
      
      // These are private methods. Do not use them; use `list.get()`,
      // `list.set()`, and `list.length()` instead.
      that._get = function (i) { return store[i] };
      that._set = function (i, val) { store[i] = val };
      that._length = function () { return store.length };
    })();
    
    if (typeof blueprint                   === 'undefined' ||
               blueprint.initializeNaughty !== false ) {
      naughty = list.beget({ initializeNaughty : false });
      naughty._set(0, naughty);
         that._set(0, naughty);
    };
    
    // TODO: Preform the extensive checks to see if `blueprint.content` is an
    //       array; if not, treat it as a hash (i.e. turn each key/value pair
    //       into a definition tuple)
    if (typeof blueprint         !== 'undefined' &&
        typeof blueprint.content !== 'undefined' ) {
      for (var a = blueprint.content, l = a.length, i = 0, element = a[i];
               i < l; element = a[++i]) { this.set(i + 1, element) } };
  };
  
  // Hard-fetchs an element from the datastore, by numeric index. Does *not*
  // negotiate lookups in *any* way.
  //--
  // TODO: `undefined` results from the store should map into
  //       `infrastructure null` responses.
  list.get = function (index) {
    return this._get(index)
  };
  
  // Hard-sets an element in the datastore, by numeric index. Only accepts
  // `paws.list` descendants of some sort; you cannot archive objects not
  // accessible from libspace into this store.
  //--
  // TODO: `infrastructure null` should map into a `delete` operation on the
  //       store.
  list.set = function (index, listObject) {
    if (list.isPrototypeOf(listObject) || list === listObject) {
      return this._set(index, listObject) }
    else { throw(list.errors.invalidChild) }
  };
  
  // Returns the current length of this `list`.
  // 
  // This is not akin to the JavaScript `length` property; it is the index of
  // the last item in the list, and the number of user-defined objects in the
  // list. It is 1-indexed, and does not count the naughty list.
  list.length = function () {
    return this._length - 1
  };
  
  // Stores another `list` in the position *after* the last element
  list.append = function (other) { this.set(this.length() + 1, other) };
  
  // `list` *is* our root `infrastructure list`. Thus, *it* needs to be
  // initialized properly.
  list.constructor();
  
  return list;
})()
