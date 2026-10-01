import { toProductBrand } from "../metadata"

describe("product search metadata", () => {
  it("normalizes a brand value for filtering", () => {
    expect(toProductBrand({ brand: "  Samsung  " })).toBe("Samsung")
  })

  it("omits missing or blank brands", () => {
    expect(toProductBrand(null)).toBeNull()
    expect(toProductBrand({ brand: "  " })).toBeNull()
    expect(toProductBrand({ brand: 12 })).toBeNull()
  })
})
