/**
 * Close over `parameter`, prepending it to any arguments passed to `f`.
 *
 * This is a bit like a poorman's `curry()`:
 *
 * ```ts
 * const multiply = (a, b) => a * b
 * const doubler = partial(multiply, 2)
 *
 * multiply(6, 2) //=> 12
 * ```
 *
 * @param f The function to wrap
 * @typeParam First the type of `f`'s first parameter
 * @param parameter A value to prepend to any arguments used in subsequent calls
 * @typeParam Rest a tuple-type for the rest of `f`'s parameters
 * @typeParam Result the return-type of `f`
 * @return The wrapped version of `f` that will prepend the given argument
 */
export function partial<First, Rest extends unknown[], Result>(
   f: (this: void, first: First, ...rest: Rest) => Result,
   parameter: First,
): (...parameters: Rest) => Result

/**
 * Close over `parameter`, prepending it to any arguments passed to `f`.
 *
 * This is a bit like a poorman's `curry()`:
 *
 * ```ts
 * const multiply = (a, b) => a * b
 * const doubler = partial(multiply, 2)
 *
 * multiply(6, 2) //=> 12
 * ```
 *
 * @param f The function to wrap
 * @typeParam First the type of `f`'s first parameter
 * @param parameter A value to prepend to any arguments used in subsequent calls
 * @typeParam Rest a tuple-type for the rest of `f`'s parameters
 * @typeParam Result the return-type of `f`
 * @return The wrapped version of `f` that will prepend the given argument
 */
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
