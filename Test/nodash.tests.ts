import { expect } from "chai"

import { partial } from "../Source/nodash/function/partial"

describe('JavaScript utility-functions ("nodash"):', () => {
   describe("Function", () => {
      describe("partial()", () => {
         it("exists", () => {
            expect(partial).to.be.a("function")
         })

         it("takes, and returns, a function", () => {
            const fun = (a: number, b: string, c: () => boolean): number | string =>
               c() ? a : b

            const result = partial(fun, 123)

            expect(result).to.be.a("function")
         })

         it("partially-applies a given value to the function", () => {
            const multiply = (a: number, b: number): number => a * b

            const double = partial(multiply, 2)

            expect(double).to.be.a("function")
            expect(double(6)).to.equal(12)
         })

         it("can partially-apply the last argument, returning a null-arity thunk", () => {
            const double = (a: number): number => a * 2

            const result = partial(double, 6)

            expect(result).to.be.a("function")
            expect(result()).to.equal(12)
         })

         it("can be used on its own output", () => {
            const multiply = (a: number, b: number): number => a * b

            const double = partial(multiply, 2)
            const result = partial(double, 6)

            expect(result).to.be.a("function")
            expect(result()).to.equal(12)
         })
      })
   })
})
