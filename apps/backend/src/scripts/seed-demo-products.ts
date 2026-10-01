/**
 * Backward-compatible path for the former apparel demo seeder. It now forwards
 * to the phone-store seed so no seed entrypoint creates clothing products.
 */
export { default } from "./seed-phone-store"
