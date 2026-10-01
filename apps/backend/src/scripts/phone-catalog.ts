export const PHONE_BRANDS = ["Apple", "Samsung", "Xiaomi", "OPPO"] as const

export type PhoneBrand = (typeof PHONE_BRANDS)[number]

type PhoneStorage = {
  value: string
  priceVnd: number
}

type PhoneSpecs = {
  screen: string
  chipset: string
  ram: string
  battery: string
  camera: string
  os: string
  release_year: number
  warranty: string
}

type PhoneDefinition = {
  brand: PhoneBrand
  title: string
  handle: string
  storage: PhoneStorage[]
  colors: string[]
  specs: PhoneSpecs
}

export const PHONE_CATALOG: PhoneDefinition[] = [
  {
    brand: "Apple",
    title: "iPhone 17 Pro",
    handle: "phone-apple-iphone-17-pro",
    storage: [
      { value: "256GB", priceVnd: 34990000 },
      { value: "512GB", priceVnd: 40990000 },
      { value: "1TB", priceVnd: 46990000 },
    ],
    colors: ["Cosmic Orange", "Deep Blue", "Silver"],
    specs: {
      screen: "6.3-inch Super Retina XDR OLED",
      chipset: "Apple A19 Pro",
      ram: "Not published by Apple",
      battery: "Not published by Apple",
      camera: "48MP Pro Fusion camera system",
      os: "iOS 26",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Apple",
    title: "iPhone 17",
    handle: "phone-apple-iphone-17",
    storage: [
      { value: "256GB", priceVnd: 24990000 },
      { value: "512GB", priceVnd: 30990000 },
    ],
    colors: ["Black", "Lavender", "Mist Blue", "Sage", "White"],
    specs: {
      screen: "6.3-inch Super Retina XDR OLED",
      chipset: "Apple A19",
      ram: "Not published by Apple",
      battery: "Not published by Apple",
      camera: "48MP dual-camera system",
      os: "iOS 26",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Apple",
    title: "iPhone 16 Pro",
    handle: "phone-apple-iphone-16-pro",
    storage: [
      { value: "128GB", priceVnd: 28990000 },
      { value: "256GB", priceVnd: 31990000 },
      { value: "512GB", priceVnd: 37990000 },
    ],
    colors: ["Black Titanium", "Natural Titanium", "White Titanium"],
    specs: {
      screen: "6.3-inch Super Retina XDR OLED",
      chipset: "Apple A18 Pro",
      ram: "Not published by Apple",
      battery: "Not published by Apple",
      camera: "48MP Pro camera system",
      os: "iOS 18 (upgradeable)",
      release_year: 2024,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Apple",
    title: "iPhone 16",
    handle: "phone-apple-iphone-16",
    storage: [
      { value: "128GB", priceVnd: 19990000 },
      { value: "256GB", priceVnd: 22990000 },
      { value: "512GB", priceVnd: 28990000 },
    ],
    colors: ["Black", "Pink", "Teal", "Ultramarine", "White"],
    specs: {
      screen: "6.1-inch Super Retina XDR OLED",
      chipset: "Apple A18",
      ram: "Not published by Apple",
      battery: "Not published by Apple",
      camera: "48MP Fusion dual-camera system",
      os: "iOS 18 (upgradeable)",
      release_year: 2024,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Apple",
    title: "iPhone 15",
    handle: "phone-apple-iphone-15",
    storage: [
      { value: "128GB", priceVnd: 15990000 },
      { value: "256GB", priceVnd: 18990000 },
    ],
    colors: ["Black", "Blue", "Green", "Pink", "Yellow"],
    specs: {
      screen: "6.1-inch Super Retina XDR OLED",
      chipset: "Apple A16 Bionic",
      ram: "Not published by Apple",
      battery: "Not published by Apple",
      camera: "48MP Main camera with 2x Telephoto",
      os: "iOS 17 (upgradeable)",
      release_year: 2023,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Samsung",
    title: "Samsung Galaxy S25 Ultra",
    handle: "phone-samsung-galaxy-s25-ultra",
    storage: [
      { value: "256GB", priceVnd: 33990000 },
      { value: "512GB", priceVnd: 37990000 },
      { value: "1TB", priceVnd: 43990000 },
    ],
    colors: ["Titanium Black", "Titanium Gray", "Titanium Silverblue"],
    specs: {
      screen: "6.9-inch Dynamic AMOLED 2X",
      chipset: "Snapdragon 8 Elite for Galaxy",
      ram: "12GB",
      battery: "5000mAh",
      camera: "200MP quad rear camera system",
      os: "Android 15 / One UI 7",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Samsung",
    title: "Samsung Galaxy S25+",
    handle: "phone-samsung-galaxy-s25-plus",
    storage: [
      { value: "256GB", priceVnd: 26990000 },
      { value: "512GB", priceVnd: 30990000 },
    ],
    colors: ["Navy", "Icy Blue", "Mint", "Silver Shadow"],
    specs: {
      screen: "6.7-inch Dynamic AMOLED 2X",
      chipset: "Snapdragon 8 Elite for Galaxy",
      ram: "12GB",
      battery: "4900mAh",
      camera: "50MP triple rear camera system",
      os: "Android 15 / One UI 7",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Samsung",
    title: "Samsung Galaxy S25",
    handle: "phone-samsung-galaxy-s25",
    storage: [
      { value: "256GB", priceVnd: 22990000 },
      { value: "512GB", priceVnd: 26990000 },
    ],
    colors: ["Navy", "Icy Blue", "Mint", "Silver Shadow"],
    specs: {
      screen: "6.2-inch Dynamic AMOLED 2X",
      chipset: "Snapdragon 8 Elite for Galaxy",
      ram: "12GB",
      battery: "4000mAh",
      camera: "50MP triple rear camera system",
      os: "Android 15 / One UI 7",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Samsung",
    title: "Samsung Galaxy A56 5G",
    handle: "phone-samsung-galaxy-a56-5g",
    storage: [
      { value: "128GB", priceVnd: 10990000 },
      { value: "256GB", priceVnd: 11990000 },
    ],
    colors: ["Awesome Graphite", "Awesome Lightgray", "Awesome Olive"],
    specs: {
      screen: "6.7-inch Super AMOLED",
      chipset: "Exynos 1580",
      ram: "8GB (demo configuration)",
      battery: "5000mAh",
      camera: "50MP triple rear camera system",
      os: "Android 15 / One UI 7",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Samsung",
    title: "Samsung Galaxy A36 5G",
    handle: "phone-samsung-galaxy-a36-5g",
    storage: [
      { value: "128GB", priceVnd: 8990000 },
      { value: "256GB", priceVnd: 9990000 },
    ],
    colors: ["Awesome Black", "Awesome Lavender", "Awesome White"],
    specs: {
      screen: "6.7-inch Super AMOLED",
      chipset: "Snapdragon 6 Gen 3",
      ram: "8GB (demo configuration)",
      battery: "5000mAh",
      camera: "50MP triple rear camera system",
      os: "Android 15 / One UI 7",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Xiaomi",
    title: "Xiaomi 15",
    handle: "phone-xiaomi-15",
    storage: [{ value: "512GB", priceVnd: 22990000 }],
    colors: ["Black", "White", "Green"],
    specs: {
      screen: "6.36-inch CrystalRes AMOLED",
      chipset: "Snapdragon 8 Elite",
      ram: "12GB",
      battery: "5240mAh (typical)",
      camera: "Leica 50MP triple camera system",
      os: "Xiaomi HyperOS 2",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Xiaomi",
    title: "Xiaomi 14T Pro",
    handle: "phone-xiaomi-14t-pro",
    storage: [
      { value: "256GB", priceVnd: 15990000 },
      { value: "512GB", priceVnd: 17990000 },
    ],
    colors: ["Titan Black", "Titan Blue", "Titan Gray"],
    specs: {
      screen: "6.67-inch AMOLED 144Hz",
      chipset: "MediaTek Dimensity 9300+",
      ram: "12GB",
      battery: "5000mAh",
      camera: "Leica 50MP triple camera system",
      os: "Xiaomi HyperOS",
      release_year: 2024,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Xiaomi",
    title: "Redmi Note 14 Pro+ 5G",
    handle: "phone-xiaomi-redmi-note-14-pro-plus-5g",
    storage: [
      { value: "256GB", priceVnd: 10990000 },
      { value: "512GB", priceVnd: 11990000 },
    ],
    colors: ["Frost Blue", "Midnight Black", "Lavender Purple"],
    specs: {
      screen: "6.67-inch CrystalRes AMOLED 120Hz",
      chipset: "Snapdragon 7s Gen 3",
      ram: "8GB (demo configuration)",
      battery: "5110mAh",
      camera: "200MP triple rear camera system",
      os: "Xiaomi HyperOS",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Xiaomi",
    title: "Redmi Note 14 5G",
    handle: "phone-xiaomi-redmi-note-14-5g",
    storage: [
      { value: "128GB", priceVnd: 6990000 },
      { value: "256GB", priceVnd: 7990000 },
    ],
    colors: ["Coral Green", "Midnight Black", "Lavender Purple"],
    specs: {
      screen: "6.67-inch AMOLED 120Hz",
      chipset: "MediaTek Dimensity 7025-Ultra",
      ram: "8GB (demo configuration)",
      battery: "5110mAh",
      camera: "108MP triple rear camera system",
      os: "Xiaomi HyperOS",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "Xiaomi",
    title: "POCO X7 Pro",
    handle: "phone-xiaomi-poco-x7-pro",
    storage: [
      { value: "256GB", priceVnd: 8990000 },
      { value: "512GB", priceVnd: 9990000 },
    ],
    colors: ["Black", "Green", "Yellow"],
    specs: {
      screen: "6.67-inch CrystalRes AMOLED 120Hz",
      chipset: "MediaTek Dimensity 8400-Ultra",
      ram: "8GB (demo configuration)",
      battery: "6000mAh",
      camera: "50MP OIS dual rear camera system",
      os: "Xiaomi HyperOS 2",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "OPPO",
    title: "OPPO Find X8 Pro",
    handle: "phone-oppo-find-x8-pro",
    storage: [
      { value: "512GB", priceVnd: 29990000 },
      { value: "1TB", priceVnd: 33990000 },
    ],
    colors: ["Space Black", "Pearl White"],
    specs: {
      screen: "6.78-inch AMOLED 120Hz",
      chipset: "MediaTek Dimensity 9400",
      ram: "16GB (demo configuration)",
      battery: "5910mAh (typical)",
      camera: "50MP Hasselblad quad camera system",
      os: "ColorOS 15",
      release_year: 2024,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "OPPO",
    title: "OPPO Find X8",
    handle: "phone-oppo-find-x8",
    storage: [
      { value: "256GB", priceVnd: 22990000 },
      { value: "512GB", priceVnd: 25990000 },
    ],
    colors: ["Shell Pink", "Star Grey"],
    specs: {
      screen: "6.59-inch AMOLED 120Hz",
      chipset: "MediaTek Dimensity 9400",
      ram: "16GB (demo configuration)",
      battery: "5630mAh (typical)",
      camera: "50MP Hasselblad triple camera system",
      os: "ColorOS 15",
      release_year: 2024,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "OPPO",
    title: "OPPO Reno13 Pro 5G",
    handle: "phone-oppo-reno13-pro-5g",
    storage: [
      { value: "256GB", priceVnd: 18990000 },
      { value: "512GB", priceVnd: 20990000 },
    ],
    colors: ["Graphite Gray", "Plume Purple"],
    specs: {
      screen: "6.83-inch AMOLED 120Hz",
      chipset: "MediaTek Dimensity 8350",
      ram: "12GB",
      battery: "5800mAh (typical)",
      camera: "50MP triple rear camera system",
      os: "ColorOS 15",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "OPPO",
    title: "OPPO Reno13 5G",
    handle: "phone-oppo-reno13-5g",
    storage: [
      { value: "256GB", priceVnd: 14990000 },
      { value: "512GB", priceVnd: 16990000 },
    ],
    colors: ["Luminous Blue", "Plume White"],
    specs: {
      screen: "6.59-inch AMOLED 120Hz",
      chipset: "MediaTek Dimensity 8350",
      ram: "12GB",
      battery: "5600mAh (typical)",
      camera: "50MP triple rear camera system",
      os: "ColorOS 15",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
  {
    brand: "OPPO",
    title: "OPPO A5 Pro 5G",
    handle: "phone-oppo-a5-pro-5g",
    storage: [
      { value: "128GB", priceVnd: 6990000 },
      { value: "256GB", priceVnd: 7990000 },
    ],
    colors: ["Mocha Brown", "Olive Green"],
    specs: {
      screen: "6.67-inch LCD 120Hz",
      chipset: "MediaTek Dimensity 6300",
      ram: "8GB (demo configuration)",
      battery: "5800mAh (typical)",
      camera: "50MP dual rear camera system",
      os: "ColorOS 15",
      release_year: 2025,
      warranty: "12 months (demo policy; verify before sale)",
    },
  },
]

export type PhoneProductRelations = {
  categoryId: string
  salesChannelId: string
  shippingProfileId: string
}

export function buildPhoneProducts({
  categoryId,
  salesChannelId,
  shippingProfileId,
}: PhoneProductRelations) {
  return PHONE_CATALOG.map((phone) => ({
    title: phone.title,
    subtitle: phone.brand,
    handle: phone.handle,
    description: `${phone.title} — dữ liệu catalog demo cho cửa hàng điện thoại. Giá, cấu hình phân phối và tồn kho cần được đối chiếu trước khi bán thật.`,
    category_ids: [categoryId],
    shipping_profile_id: shippingProfileId,
    sales_channels: [{ id: salesChannelId }],
    metadata: {
      brand: phone.brand,
      screen: phone.specs.screen,
      chipset: phone.specs.chipset,
      ram: phone.specs.ram,
      battery: phone.specs.battery,
      camera: phone.specs.camera,
      os: phone.specs.os,
      release_year: phone.specs.release_year,
      warranty: phone.specs.warranty,
      catalog_data_status: "demo",
    },
    options: [
      {
        title: "Storage",
        values: phone.storage.map(({ value }) => value),
      },
      {
        title: "Color",
        values: phone.colors,
      },
    ],
    variants: phone.storage.flatMap((storage) =>
      phone.colors.map((color) => ({
        title: `${storage.value} / ${color}`,
        sku: `${phone.handle}-${storage.value}-${color}`
          .toUpperCase()
          .replace(/[^A-Z0-9]+/g, "-"),
        options: {
          Storage: storage.value,
          Color: color,
        },
        manage_inventory: true,
        allow_backorder: false,
        prices: [
          {
            amount: storage.priceVnd,
            currency_code: "vnd",
          },
        ],
      })),
    ),
  }))
}
