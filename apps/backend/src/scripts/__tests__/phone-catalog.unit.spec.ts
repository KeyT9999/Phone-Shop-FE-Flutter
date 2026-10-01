import {
  buildPhoneProducts,
  PHONE_BRANDS,
  PHONE_CATALOG,
} from "../phone-catalog"

describe("phone catalog seed data", () => {
  it("contains 20 phone models across the four supported brands", () => {
    expect(PHONE_CATALOG).toHaveLength(20)
    expect(new Set(PHONE_CATALOG.map((phone) => phone.brand))).toEqual(
      new Set(PHONE_BRANDS),
    )

    for (const brand of PHONE_BRANDS) {
      expect(PHONE_CATALOG.filter((phone) => phone.brand === brand)).toHaveLength(
        5,
      )
    }
  })

  it("builds unique Storage and Color variants with VND prices and specs", () => {
    const products = buildPhoneProducts({
      categoryId: "phone-category",
      salesChannelId: "mobile-channel",
      shippingProfileId: "default-shipping-profile",
    })

    expect(products).toHaveLength(PHONE_CATALOG.length)

    for (const product of products) {
      expect(product.category_ids).toEqual(["phone-category"])
      expect(product.sales_channels).toEqual([{ id: "mobile-channel" }])
      expect(product.shipping_profile_id).toBe("default-shipping-profile")
      expect(product.metadata).toMatchObject({
        brand: expect.any(String),
        screen: expect.any(String),
        chipset: expect.any(String),
        ram: expect.any(String),
        battery: expect.any(String),
        camera: expect.any(String),
        os: expect.any(String),
        release_year: expect.any(Number),
        warranty: expect.any(String),
      })
      expect(product.options.map((option) => option.title)).toEqual([
        "Storage",
        "Color",
      ])
      expect(product.variants.length).toBeGreaterThan(0)
      expect(new Set(product.variants.map((variant) => variant.sku)).size).toBe(
        product.variants.length,
      )

      for (const variant of product.variants) {
        expect(variant.options.Storage).toBeTruthy()
        expect(variant.options.Color).toBeTruthy()
        expect(variant.sku).toMatch(/^[A-Z0-9-]+$/)
        expect(variant.manage_inventory).toBe(true)
        expect(variant.allow_backorder).toBe(false)
        expect(variant.prices).toEqual([
          {
            amount: expect.any(Number),
            currency_code: "vnd",
          },
        ])
      }
    }
  })
})
