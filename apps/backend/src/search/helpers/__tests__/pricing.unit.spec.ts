import { PRICE_CURRENCIES, toProductPricing } from "../pricing"

describe("product search pricing", () => {
  it("indexes calculated VND prices for the phone store", () => {
    expect(PRICE_CURRENCIES).toContain("vnd")

    const pricing = toProductPricing({
      vnd: [
        {
          calculated_price: {
            calculated_amount: 34990000,
            original_amount: 36990000,
          },
        },
        {
          calculated_price: {
            calculated_amount: 40990000,
            original_amount: 40990000,
          },
        },
      ],
    })

    expect(pricing).toMatchObject({
      min_price_vnd: 34990000,
      max_price_vnd: 40990000,
      original_price_vnd: 36990000,
      on_sale_vnd: true,
    })
  })
})
