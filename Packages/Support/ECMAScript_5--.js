// This file is intended to spoof some of ECMAScript 5’s new features on top
// of older implementations, specifically V8.

return (function () {
  
  if (typeof Object.prototype['isPrototypeOf'] !== 'function') {
    // Tests for our presence in another object’s prototype chain.
    Object.prototype['isPrototypeOf'] = function (object) {
      // Nothing seems to document whether ES5’s isPrototypeOf will return
      // `true` or `false` when you `o.isPrototypeOf(o)`. I’m going with
      // `true`, for this implementation.
      do { if (object === this) { return true } }
      while (object = object.__proto__);
      return false;
    }
  };
  
  return Object.prototype;
})()
