/**
 * ### Some supporting type-level functionality
 */

type headOf<TupleType extends unknown[]> = TupleType extends [unknown, ...unknown[]]
   ? TupleType[0]
   : never

type tailOf<TupleType extends unknown[]> = ((..._a: TupleType) => unknown) extends (
   _head: never,
   ...tail: infer TailType
) => unknown
   ? TailType
   : []

type hasTail<T extends unknown[]> = T extends [] | [unknown] ? false : true

type firstParameterOf<FunctionType extends (..._a: never[]) => unknown> =
   FunctionType extends (..._a: infer Parameters) => unknown ? headOf<Parameters> : never

type restParameterOf<FunctionType extends (..._a: never[]) => unknown> =
   FunctionType extends (..._a: infer Parameters) => unknown ? tailOf<Parameters> : never

type hasTailParameters<FunctionType extends (..._a: never[]) => unknown> =
   FunctionType extends (..._a: infer Parameters) => unknown ? hasTail<Parameters> : never

/**
 * ### The meat
 */

/*
 * The return-type of `partial()`, this ...
 * DOCME:
 */
type PartialApplicationResult<FunctionType extends (..._a: never[]) => unknown> =
   hasTailParameters<FunctionType> extends true
      ? (...rest: restParameterOf<FunctionType>) => ReturnType<FunctionType>
      : () => ReturnType<FunctionType>

export function partial<FunctionType extends (..._a: never[]) => unknown>(
   f: FunctionType,
   parameter: firstParameterOf<FunctionType>,
): PartialApplicationResult<FunctionType> {
   return function (
      this: ThisParameterType<FunctionType>,
      ...rest: restParameterOf<FunctionType>
   ) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-return -- no idea why this breaks
      return f.call(this, parameter, ...rest) as ReturnType<FunctionType>
   }
}
