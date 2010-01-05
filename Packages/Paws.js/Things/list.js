return (function(){ var list;
  list = new(Object);
  
  list.errors = {
    invalidChild: new(Error)("Lists may only contain lists as children")
  };
  
  list.beget = function (blueprint) { var result;
    result = Object.prototype.beget.apply(this, arguments);
    paws._inspect(blueprint, 'blueprint');
    paws._inspect(result, 'begat');
    return result;
  };
  
  
  list.constructor = function (blueprint) { var that, naughty;
    // This is the unique per-object lexical scope in which to store our
    // private data
    that = this;
    (function(){ var store;
      store = new(Array);
      
      // These are private methods. Do not use them; use `list.get()`,
      // `list.set()`, and `list.length()` instead.
      that._store = function () { return store };
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
               i < l; element = a[++i]) {
        this.set(paws.numeric.beget(i), element) } };
  };
  
  list._lens = function (eyes, styles) {
    return eyes.stylize('(' + this._store().map(function (item) {
      return item._get(0) === item ? '=' :
        eyes.stringify(item, styles) }).join(', ') + ')',
      styles.list, styles) };
  
  
  // ==================
  // = JavaScript API =
  // ==================
  
  // Hard-fetches an element from the datastore, by numeric index. Does *not*
  // negotiate lookups in *any* way.
  // 
  // Takes a `paws.numeric` as the argument.
  //--
  // TODO: `undefined` results from the store should map into
  //       `infrastructure void` responses.
  list.get = function (index) { return this._get(index.primitive() + 1) };
  
  // Hard-sets an element in the datastore, by numeric index. Only accepts
  // `paws.list` descendants of some sort; you cannot archive objects not
  // accessible from libspace into this store.
  // 
  // Takes a `paws.numeric` as the index argument, and any `paws.list`
  // descendant as the storee.
  //--
  // TODO: `infrastructure void` should map into a `delete` operation on the
  //       store.
  list.set = function (index, storee) {
    if (list.isPrototypeOf(storee) || list === storee) {
      this._set(index.primitive() + 1, storee) }
    else { throw(list.errors.invalidChild) }
  };
  
  // Returns the current length of this `list`.
  // 
  // This is not akin to the JavaScript `length` property; it is the index of
  // the last item in the list, and the number of user-defined objects in the
  // list. It is 1-indexed, and does not count the naughty list.
  list.length = function () { return paws.numeric.beget(this._length() - 1) };
  
  // Stores another `list` in the position *after* the last element
  list.append = function (other) {
    this.set(paws.numeric.beget(this.length().primitive() + 1), other) };
  
  // Appends a definition
  list.assign = function (key, value) {
    this.append(paws.definition.beget([key, value])) };
  
  // The core hard-lookup on a definition list.
  // 
  // This function takes an `infrastructure string` (or other libspace list),
  // not a native.
  // 
  // The intracacies of the interactions between this and the libspace
  // `lookup`s are extremely important:
  // 
  // - This function will *always* be called to lookup `metalookup` on the
  //   naughty
  // - This function will initially be wrapped into a native routine as
  //   the primary `lookup` (also stored on the naughty)
  // - Thus, this function will *also* be wrapped into the initial
  //   `metalookup` as a native
  //--
  // TODO: Numeric lookups
  list.hardLookup = function (key) {
    for (var l = this.length().primitive(), i = 1,
             element = this.get(paws.numeric.beget(i));
             i <= l; element = this.get(paws.numeric.beget(++i))) {
      // TODO: Implement `definition.key()` and `definition.value()` to clean
      //       this mess up
      if (paws.definition.isPrototypeOf(element) &&
          element.get(paws.numeric.beget(1)) === key) {
        return element.get(paws.numeric.beget(2)) } }
  };
  
  // A convenience method to traverse the ‘lookup chain’ from the JavaScript
  // API. This method is unrelated to the lookup chain itself.
  list.lookup = function (key) { var naughty, metalookup, lookup;
    naughty = this._get(0);
    metalookup = naughty.hardLookup(paws.string.beget('metalookup'));
                        // It’s probably worth pointing out, that this is
                        // `routine.apply()`, not `Function.prototype.apply()`
    lookup = metalookup.apply(this, paws.string.beget('lookup'));
    return lookup.apply(this, paws.string.beget('lookup'));
  };
  
  // Exposes a JavaScript function in libspace.
  // 
  // This will wrap the JavaScript function in a `paws.routine`, and expose it
  // to lookups and calls on the libspace list.
  // 
  // Note: native functions wrapped into routines are only given one
  // meaningful arugment; that the argument is a `paws.list` descendant; and
  // that if a return value is provided, and the last argument was a
  // `paws.routine`, then that routine will be called with your return value
  // as the argument.
  // 
  // Said breifly, your function should ‘act’ like a `routine`: take a `list`
  // descendant, return a `list` descendant or nothing at all. Otherwise
  // things may break.
  // 
  // If no `pawsName` is provided, one will be constructed from the `jsName`.
  // Specifically, `camelCase` will be converted to `dot.case`, with the
  // exception of abbreviations and acronyms, such as `whatDoesWTFMean`:
  // `what.does.WTF.mean`.
  list.expose = function (jsName, pawsName) { var routine;
    if (typeof pawsName === 'undefined') {
      pawsName = jsName.replace(
        /([^A-Z])([A-Z])(?=[A-Z])|(.)([A-Z])(?=[^A-Z])/g,
        function (_, a1, a2, b1, b2) {
          return (a1 || b1) +'.'+ (a2 || b2.toLowerCase()) }) };
    
    this.assign(paws.string.beget(pawsName),
      routine = paws.routine.beget(this[jsName]));
    return routine;
  };
  
  
  // ============
  // = Paws API =
  // ============
  
  
  /* -- --- -- -!- -- --- -- */
  
  list.constructor();
  
  return list;
})()
