export function partial<First, Rest extends unknown[], Result>(
   f: (this: void, first: First, ...rest: Rest) => Result,
   parameter: First,
): (...parameters: Rest) => Result

export function partial<This, First, Rest extends unknown[], Result>(
   f: (this: This, first: First, ...rest: Rest) => Result,
   parameter: First,
): (this: This, ...parameters: Rest) => Result

export function partial<This, First, Rest extends unknown[], Result>(
   f: (this: This, first: First, ...rest: Rest) => Result,
   parameter: First,
): (this: This, ...parameters: Rest) => Result {
   return function (this: This, ...rest: Rest) {
      return f.call(this, parameter, ...rest)
   }
}
