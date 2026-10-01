export function toProductBrand(
  metadata: Record<string, unknown> | null | undefined,
): string | null {
  const brand = metadata?.brand

  if (typeof brand !== "string") {
    return null
  }

  return brand.trim() || null
}
