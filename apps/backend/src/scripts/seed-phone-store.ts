import type { ExecArgs } from "@medusajs/framework/types"
import {
  ContainerRegistrationKeys,
  MedusaError,
  Modules,
  ProductStatus,
} from "@medusajs/framework/utils"
import {
  createApiKeysWorkflow,
  createInventoryLevelsWorkflow,
  createProductCategoriesWorkflow,
  createProductsWorkflow,
  createRegionsWorkflow,
  createSalesChannelsWorkflow,
  createShippingOptionsWorkflow,
  createStockLocationsWorkflow,
  createStoresWorkflow,
  linkSalesChannelsToApiKeyWorkflow,
  linkSalesChannelsToStockLocationWorkflow,
  updateRegionsWorkflow,
  updateStoresWorkflow,
} from "@medusajs/medusa/core-flows"

import { buildPhoneProducts, PHONE_CATALOG } from "./phone-catalog"

const PHONE_CATEGORY_NAME = "Điện thoại"
const SALES_CHANNEL_NAME = "Default Sales Channel"
const PUBLISHABLE_KEY_TITLE = "Default Publishable API Key"
const REGION_NAME = "Vietnam"
const STOCK_LOCATION_NAME = "Vietnam Phone Store Warehouse"
const FULFILLMENT_SET_NAME = "Vietnam Phone Store Delivery"
// Demo quantity only; replace with the verified physical stock count.
const STOCKED_QUANTITY_PER_VARIANT = 5

// These are demo estimates. Replace them with the carrier's real rates before
// accepting customer orders.
const STANDARD_DELIVERY_PRICE_VND = 30000
const EXPRESS_DELIVERY_PRICE_VND = 50000

export default async function seedPhoneStore({ container }: ExecArgs) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER)
  const query = container.resolve(ContainerRegistrationKeys.QUERY)
  const link = container.resolve(ContainerRegistrationKeys.LINK)
  const fulfillmentModuleService = container.resolve(Modules.FULFILLMENT)

  logger.info("Preparing Vietnam phone-store configuration...")

  const { data: salesChannels } = await query.graph({
    entity: "sales_channel",
    fields: ["id", "name"],
  })
  let salesChannelId = salesChannels.find(
    (channel) => channel.name === SALES_CHANNEL_NAME,
  )?.id

  if (!salesChannelId) {
    const { result } = await createSalesChannelsWorkflow(container).run({
      input: {
        salesChannelsData: [
          {
            name: SALES_CHANNEL_NAME,
            description: "Default storefront and Flutter mobile app channel",
          },
        ],
      },
    })
    salesChannelId = result[0]?.id
  }

  if (!salesChannelId) {
    throw new MedusaError(
      MedusaError.Types.NOT_FOUND,
      "Could not create or find the default sales channel.",
    )
  }

  const { data: publishableKeys } = await query.graph({
    entity: "api_key",
    fields: ["id", "title", "type", "sales_channels.id"],
    filters: { type: "publishable" },
  })
  const existingPublishableKey = publishableKeys.find(
    (key) => key.title === PUBLISHABLE_KEY_TITLE,
  )
  let publishableKeyId = existingPublishableKey?.id
  const linkedSalesChannelIds = (
    existingPublishableKey?.sales_channels ?? []
  ).map((channel) => channel?.id)

  if (!publishableKeyId) {
    const { result } = await createApiKeysWorkflow(container).run({
      input: {
        api_keys: [
          {
            title: PUBLISHABLE_KEY_TITLE,
            type: "publishable",
            created_by: "",
          },
        ],
      },
    })
    publishableKeyId = result[0]?.id
  }

  if (!publishableKeyId) {
    throw new MedusaError(
      MedusaError.Types.NOT_FOUND,
      "Could not create or find the publishable API key.",
    )
  }

  if (!linkedSalesChannelIds.includes(salesChannelId)) {
    await linkSalesChannelsToApiKeyWorkflow(container).run({
      input: {
        id: publishableKeyId,
        add: [salesChannelId],
      },
    })
  }

  const supportedCurrencyCodes = ["vnd", "eur", "usd"]
  const { data: stores } = await query.graph({
    entity: "store",
    fields: [
      "id",
      "default_sales_channel_id",
      "supported_currencies.currency_code",
      "supported_currencies.is_default",
    ],
  })
  const store = stores[0]

  if (store) {
    const existingCurrencies = (store.supported_currencies ?? [])
      .map((currency) => currency?.currency_code)
      .filter((currency): currency is string => Boolean(currency))
    const currencies = Array.from(
      new Set([...supportedCurrencyCodes, ...existingCurrencies]),
    ).map((currency_code) => ({
      currency_code,
      is_default: currency_code === "vnd",
    }))

    await updateStoresWorkflow(container).run({
      input: {
        selector: { id: store.id },
        update: {
          supported_currencies: currencies,
          default_sales_channel_id: salesChannelId,
        },
      },
    })
  } else {
    await createStoresWorkflow(container).run({
      input: {
        stores: [
          {
            name: "Phone Store",
            supported_currencies: supportedCurrencyCodes.map(
              (currency_code) => ({
                currency_code,
                is_default: currency_code === "vnd",
              }),
            ),
            default_sales_channel_id: salesChannelId,
          },
        ],
      },
    })
  }

  const { data: regions } = await query.graph({
    entity: "region",
    fields: ["id", "name", "currency_code", "countries.iso_2"],
  })
  const existingVietnamRegion = regions.find(
    (region) => region.name === REGION_NAME,
  )
  let vietnamRegionId = existingVietnamRegion?.id

  if (existingVietnamRegion) {
    const countryCodes = (existingVietnamRegion.countries ?? []).map(
      (country) => country?.iso_2?.toLowerCase(),
    )
    if (
      existingVietnamRegion.currency_code !== "vnd" ||
      !countryCodes.includes("vn")
    ) {
      await updateRegionsWorkflow(container).run({
        input: {
          selector: { id: existingVietnamRegion.id },
          update: {
            name: REGION_NAME,
            currency_code: "vnd",
            countries: ["vn"],
          },
        },
      })
    }
  } else {
    const { result } = await createRegionsWorkflow(container).run({
      input: {
        regions: [
          {
            name: REGION_NAME,
            currency_code: "vnd",
            countries: ["vn"],
          },
        ],
      },
    })
    vietnamRegionId = result[0]?.id
  }

  if (!vietnamRegionId) {
    throw new MedusaError(
      MedusaError.Types.NOT_FOUND,
      "Could not create or find the Vietnam region.",
    )
  }

  const { data: stockLocations } = await query.graph({
    entity: "stock_location",
    fields: [
      "id",
      "name",
      "sales_channels.id",
      "fulfillment_providers.id",
      "fulfillment_sets.id",
    ],
  })
  const existingStockLocation = stockLocations.find(
    (location) => location.name === STOCK_LOCATION_NAME,
  )
  let stockLocationId = existingStockLocation?.id
  let stockLocationSalesChannelIds = (
    existingStockLocation?.sales_channels ?? []
  ).map((channel) => channel?.id)
  let fulfillmentProviderIds = (
    existingStockLocation?.fulfillment_providers ?? []
  ).map((provider) => provider?.id)
  let locationFulfillmentSetIds = (
    existingStockLocation?.fulfillment_sets ?? []
  ).map((set) => set?.id)

  if (!stockLocationId) {
    const { result } = await createStockLocationsWorkflow(container).run({
      input: {
        locations: [
          {
            name: STOCK_LOCATION_NAME,
            address: {
              city: "Ho Chi Minh City",
              country_code: "VN",
              address_1: "",
            },
          },
        ],
      },
    })
    stockLocationId = result[0]?.id
  }

  if (!stockLocationId) {
    throw new MedusaError(
      MedusaError.Types.NOT_FOUND,
      "Could not create or find the Vietnam stock location.",
    )
  }

  if (!stockLocationSalesChannelIds.includes(salesChannelId)) {
    await linkSalesChannelsToStockLocationWorkflow(container).run({
      input: {
        id: stockLocationId,
        add: [salesChannelId],
      },
    })
    stockLocationSalesChannelIds = [...stockLocationSalesChannelIds, salesChannelId]
  }

  if (!fulfillmentProviderIds.includes("manual_manual")) {
    await link.create({
      [Modules.STOCK_LOCATION]: {
        stock_location_id: stockLocationId,
      },
      [Modules.FULFILLMENT]: {
        fulfillment_provider_id: "manual_manual",
      },
    })
    fulfillmentProviderIds = [...fulfillmentProviderIds, "manual_manual"]
  }

  const { data: fulfillmentSets } = await query.graph({
    entity: "fulfillment_set",
    fields: ["id", "name", "service_zones.id"],
  })
  const existingFulfillmentSet = fulfillmentSets.find(
    (set) => set.name === FULFILLMENT_SET_NAME,
  )
  let fulfillmentSetId = existingFulfillmentSet?.id
  let serviceZoneId = existingFulfillmentSet?.service_zones?.[0]?.id

  if (!fulfillmentSetId) {
    const fulfillmentSet = await fulfillmentModuleService.createFulfillmentSets({
      name: FULFILLMENT_SET_NAME,
      type: "shipping",
      service_zones: [
        {
          name: "Vietnam",
          geo_zones: [
            {
              country_code: "vn",
              type: "country",
            },
          ],
        },
      ],
    })
    fulfillmentSetId = fulfillmentSet.id
    serviceZoneId = fulfillmentSet.service_zones?.[0]?.id
  }

  if (!fulfillmentSetId) {
    throw new MedusaError(
      MedusaError.Types.NOT_FOUND,
      "Could not create or find the Vietnam fulfillment set.",
    )
  }

  if (!locationFulfillmentSetIds.includes(fulfillmentSetId)) {
    await link.create({
      [Modules.STOCK_LOCATION]: {
        stock_location_id: stockLocationId,
      },
      [Modules.FULFILLMENT]: {
        fulfillment_set_id: fulfillmentSetId,
      },
    })
    locationFulfillmentSetIds = [...locationFulfillmentSetIds, fulfillmentSetId]
  }

  if (!serviceZoneId) {
    throw new MedusaError(
      MedusaError.Types.INVALID_DATA,
      "Vietnam fulfillment set has no service zone.",
    )
  }

  const { data: shippingProfiles } = await query.graph({
    entity: "shipping_profile",
    fields: ["id"],
  })
  const shippingProfile = shippingProfiles[0]

  if (!shippingProfile) {
    throw new MedusaError(
      MedusaError.Types.NOT_FOUND,
      "No shipping profile is available for phone products.",
    )
  }

  const { data: existingShippingOptions } = await query.graph({
    entity: "shipping_option",
    fields: ["id", "name", "service_zone_id"],
  })
  const deliveryOptions = [
    {
      name: "Standard Delivery",
      amount: STANDARD_DELIVERY_PRICE_VND,
      code: "standard-delivery-vn",
      description: "Standard delivery in Vietnam (demo option).",
    },
    {
      name: "Express Delivery",
      amount: EXPRESS_DELIVERY_PRICE_VND,
      code: "express-delivery-vn",
      description: "Express delivery in Vietnam (demo option).",
    },
  ]
  const missingDeliveryOptions = deliveryOptions.filter(
    (option) =>
      !existingShippingOptions.some(
        (existing) =>
          existing.name === option.name &&
          existing.service_zone_id === serviceZoneId,
      ),
  )

  if (missingDeliveryOptions.length) {
    await createShippingOptionsWorkflow(container).run({
      input: missingDeliveryOptions.map((option) => ({
        name: option.name,
        price_type: "flat" as const,
        provider_id: "manual_manual",
        service_zone_id: serviceZoneId,
        shipping_profile_id: shippingProfile.id,
        type: {
          label: option.name.replace(" Delivery", ""),
          description: option.description,
          code: option.code,
        },
        prices: [
          {
            currency_code: "vnd",
            amount: option.amount,
          },
          {
          region_id: vietnamRegionId,
            amount: option.amount,
          },
        ],
        rules: [
          {
            attribute: "enabled_in_store",
            value: "true",
            operator: "eq" as const,
          },
          {
            attribute: "is_return",
            value: "false",
            operator: "eq" as const,
          },
        ],
      })),
    })
  }

  const { data: categories } = await query.graph({
    entity: "product_category",
    fields: ["id", "name"],
  })
  let phoneCategoryId = categories.find(
    (category) => category.name === PHONE_CATEGORY_NAME,
  )?.id

  if (!phoneCategoryId) {
    const { result } = await createProductCategoriesWorkflow(container).run({
      input: {
        product_categories: [
          {
            name: PHONE_CATEGORY_NAME,
            is_active: true,
          },
        ],
      },
    })
    phoneCategoryId = result[0]?.id
  }

  if (!phoneCategoryId) {
    throw new MedusaError(
      MedusaError.Types.NOT_FOUND,
      "Could not create or find the phone product category.",
    )
  }

  const phoneProducts = buildPhoneProducts({
    categoryId: phoneCategoryId,
    salesChannelId,
    shippingProfileId: shippingProfile.id,
  }).map((product) => ({
    ...product,
    status: ProductStatus.PUBLISHED,
  }))
  const phoneHandles = phoneProducts.map((product) => product.handle)
  const phoneSkus = phoneProducts.flatMap((product) =>
    product.variants.map((variant) => variant.sku),
  )
  const { data: existingPhoneProducts } = await query.graph({
    entity: "product",
    fields: ["id", "handle"],
    filters: { handle: phoneHandles },
  })
  const existingHandles = new Set(
    existingPhoneProducts.map((product) => product.handle),
  )
  const productsToCreate = phoneProducts.filter(
    (product) => !existingHandles.has(product.handle),
  )

  if (productsToCreate.length) {
    await createProductsWorkflow(container).run({
      input: { products: productsToCreate },
    })
    logger.info(`Created ${productsToCreate.length} phone product(s).`)
  } else {
    logger.info("Phone products already exist; product creation was skipped.")
  }

  const { data: phoneInventoryItems } = await query.graph({
    entity: "inventory_item",
    fields: ["id", "sku"],
  })
  const phoneInventoryItemIds = phoneInventoryItems
    .filter((item) => item.sku && phoneSkus.includes(item.sku))
    .map((item) => item.id)
  const foundPhoneSkus = new Set(
    phoneInventoryItems
      .map((item) => item.sku)
      .filter((sku): sku is string => Boolean(sku && phoneSkus.includes(sku))),
  )
  const missingPhoneSkus = phoneSkus.filter((sku) => !foundPhoneSkus.has(sku))

  if (missingPhoneSkus.length) {
    throw new MedusaError(
      MedusaError.Types.INVALID_DATA,
      `Inventory items were not created for ${missingPhoneSkus.length} phone variant(s).`,
    )
  }

  const { data: existingInventoryLevels } = await query.graph({
    entity: "inventory_level",
    fields: ["inventory_item_id", "location_id"],
    filters: { location_id: stockLocationId },
  })
  const existingInventoryItemIds = new Set(
    existingInventoryLevels.map((level) => level.inventory_item_id),
  )
  const inventoryLevelsToCreate = phoneInventoryItemIds
    .filter((id) => !existingInventoryItemIds.has(id))
    .map((inventory_item_id) => ({
      inventory_item_id,
      location_id: stockLocationId,
      stocked_quantity: STOCKED_QUANTITY_PER_VARIANT,
    }))

  if (inventoryLevelsToCreate.length) {
    await createInventoryLevelsWorkflow(container).run({
      input: { inventory_levels: inventoryLevelsToCreate },
    })
  }

  logger.info(
    `Phone inventory levels ready: ${phoneInventoryItemIds.length - inventoryLevelsToCreate.length} existing, ${inventoryLevelsToCreate.length} created.`,
  )

  const { data: indexedPhoneProducts } = await query.graph({
    entity: "product",
    fields: ["id"],
    filters: { handle: phoneHandles },
  })
  const search = container.resolve(Modules.SEARCH)

  if (indexedPhoneProducts.length) {
    await search.ingest({
      name: "product.created",
      data: indexedPhoneProducts.map((product) => ({ id: product.id })),
    } as never)
  }

  logger.info(
    `Phone-store seed complete: ${PHONE_CATALOG.length} models, ${phoneSkus.length} variants, Vietnam/VND.`,
  )
}
