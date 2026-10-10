# Roadmap phát triển Phone Store — Medusa v2 + Flutter

**Trạng thái cập nhật 2026-10-10:** UI/UX Flutter và checkout source đã triển khai; dart analyze sạch, 24 Flutter tests pass, Flutter Web release build pass. Backend kết nối database Supabase do chủ dự án cung cấp; seed đã tạo region Vietnam/VND, 20 điện thoại/4 hãng và 137 variants có inventory. App tải catalog và tìm kiếm iPhone thành công. Shipping/COD/order E2E và seed rerun safety chưa xác minh. GitHub Actions mobile workflow đã được thêm; CI chưa chạy từ GitHub. Android/iOS store release và public deploy chưa cấu hình đích/signing.

Tài liệu triển khai: [`tasks/spec.md`](tasks/spec.md) · [`tasks/design.md`](tasks/design.md) · [`tasks/plan.md`](tasks/plan.md) · [`tasks/todo.md`](tasks/todo.md) · [`DEMO_GUIDE.md`](DEMO_GUIDE.md).

Các mục **2–4** bên dưới là baseline audit ban đầu, có một số ghi chú lịch sử trước khi Phase 1–4 được triển khai. Dùng phần trạng thái theo phase và mục 13–14 làm nguồn hiện hành; không dùng baseline đó làm danh sách việc còn lại.

## UI/UX PRO MAX — lần triển khai hiện tại

- Đã áp dụng template **Flagship Tech Boutique** cho 12 màn Flutter bằng theme/tokens tập trung, component dùng chung, navigation 4 tab và layout responsive; không thêm package UI/state.
- Đã thêm `cartRevision` để cart tab tải lại server response sau khi thêm sản phẩm; widget test bao phủ flow từ catalog tới cart.
- Đã sửa customer attach theo Store API: gọi endpoint attach customer, sau đó gửi email và shipping/billing address trong cart update. Có service regression test.
- Kiểm tra local: format sạch, analyzer trực tiếp sạch, 24 tests pass và Web release build pass. Browser smoke-check ở 320 px và desktop hiện error state đúng khi thiếu key; không chứng minh được dữ liệu thật.
- CI workflow chưa chạy từ GitHub; sẽ chạy khi push/PR hoặc dispatch. Workflow lưu artifact Web 14 ngày; deploy public/native vẫn cần hosting/store và signing được chọn.
- Theo dõi các bước run/demo còn lại trong [`tasks/ui-ux-plan.md`](tasks/ui-ux-plan.md) và [`DEMO_GUIDE.md`](DEMO_GUIDE.md).

## 1. Mục tiêu MVP

Luồng cần demo được: Home/catalog → tìm và lọc điện thoại → chọn đúng variant → cart → customer/address → shipping → payment session → Medusa complete cart → order success/history.

Chỉ hiển thị đặt hàng thành công khi Store API trả về order thật và order đó nhìn thấy trong Medusa Admin. Cart local, snackbar, payment session hoặc lời gọi complete tự nó không chứng minh order đã được tạo/đã thu tiền.

Phạm vi chính là apps/backend và apps/mobile. apps/storefront có mặt để tham khảo; không phải frontend mục tiêu. Dùng entity commerce native của Medusa; không tạo Product, Cart hay Order database riêng.

## 2. Phạm vi scan và bằng chứng

### Đã kiểm tra

- AGENTS.md, CLAUDE.md; không thấy AGENTS.md lồng trong apps/backend, apps/mobile hoặc apps/storefront.
- Root package.json, pnpm-workspace.yaml, turbo.json, README.md; package manager là pnpm 10.11.1.
- Backend manifest/config, API routes/middleware, search index/helpers, migration seed, demo seed, Jest setup/config và README.
- Flutter manifest, main, model, service, ba screens, Android manifest, README và widget test.
- Storefront manifest và các data/search modules liên quan product/cart/customer/shipping/payment/order.
- Chỉ đọc tên biến trong env template và tên file env; không đọc giá trị trong apps/backend/.env.
- Git status ban đầu có .serena/ chưa được track. Giữ nguyên, không đọc nội dung hay sửa.
- Không gọi API, không kiểm tra live DB, Admin, thiết bị hoặc dữ liệu sản phẩm đang tồn tại.

### Phiên bản và cấu trúc

| Khu vực | Bằng chứng |
|---|---|
| Root | pnpm 10.11.1, Turborepo; Node engine khai báo ^20.19.0 hoặc >=22.12.0 |
| Backend | @medusajs/medusa, framework, CLI, Admin packages khóa ở 2.21.1 |
| Flutter | apps/mobile độc lập; pubspec yêu cầu Dart ^3.13.2, phụ thuộc http và intl; chưa có package state-management |
| Next.js reference | apps/storefront có Next.js 15.5.24 và Medusa JS SDK 2.21.1 |
| Admin | Dùng Medusa Admin tiêu chuẩn; không thấy custom widget/page nghiệp vụ |
| Runtime | Flutter static analysis đã chạy; backend/DB, publishable key/channel, provider và API runtime chưa xác minh |

### Baseline checks

- **pnpm run lint:** lỗi tại storefront do thiếu NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY. Root task dừng vì lỗi đó.
- **Backend lint riêng:** chạy lâu không có kết quả; đã ngắt, trạng thái chưa xác minh.
- **flutter test:** thất bại vì widget_test.dart còn test Counter và mong tìm text “0”, nhưng PhoneStoreApp không render counter.
- **flutter analyze:** lần chạy đầu lỗi parse JSON LSP; `dart analyze lib` qua mapped drive exit 0, không có error. Còn info lint (một số thuộc source cũ; radio deprecation trong checkout đã được thay).
- **flutter build apk --debug:** chưa thành công. Kotlin incremental cache lỗi khi Flutter plugin source ở C: và workspace ở F:. Pub cache cùng ổ F: báo thiếu Windows Developer Mode để tạo plugin symlink.
- Không chạy test, seed/migration hoặc backend integration tests. Không có backend test suite trong file inventory ngoài Jest setup/config; integration sẽ cần PostgreSQL.

## 3. Audit hiện trạng

### Backend — verified từ source

- Medusa v2.21.1 là commerce backend. Store, Product, Variant, Cart, Customer, Fulfillment, Payment, Order và Admin nên tiếp tục dùng native Medusa.
- apps/backend/medusa-config.ts cấu hình DATABASE_URL, CORS và JWT/cookie secrets; chưa thấy custom module/provider configuration.
- apps/backend/src/api/middlewares.ts bật product search qua POST /store/search. apps/backend/src/search/product.ts định nghĩa index với title/description, category, tags trong field labels, option_values và giá theo EUR/USD.
- Search index chưa lấy metadata.brand. pricing.ts chỉ khai báo EUR/USD. Comment trong index ghi nhận một số price-list/channel/category changes không phát event nên index có thể cũ.
- GET /store/custom và GET /admin/custom chỉ trả HTTP 200. modules, workflows, links, jobs, subscribers và phần lớn Admin extension là README placeholder.
- initial-data-seed.ts tạo sales channel, publishable key, store EUR/USD, region Europe/EUR, tax, European Warehouse, fulfillment và Standard/Express Shipping; seed bốn sản phẩm may mặc với Size/Color, giá EUR/USD. Cuối file tạo inventory levels 1.000.000 cho mọi inventory item tìm thấy.
- Seed gọi create workflows trực tiếp; không thấy dò/upsert/rerun-safe trước khi tạo region/channel/location/category/options/products. Chạy lại với DB có dữ liệu có thể trùng hoặc lỗi. DB thực tế chưa kiểm tra.
- src/scripts/seed-demo-products.ts là seeder riêng, tạo 50 sản phẩm quần áo; handle deterministic và bỏ qua handle đã tồn tại, nhưng không thấy bước tạo inventory levels. Không có caller nội bộ trong repo; comment hướng dẫn chạy bằng medusa exec.
- Root alias backend:seed gọi Turbo task seed; turbo.json khai báo task này, nhưng apps/backend/package.json không khai báo script seed. Chưa có bằng chứng alias hiện gọi được seed file.
- Template liệt kê tên biến DB/CORS/secrets và vài biến khác; config đã đọc không dùng toàn bộ. Không đọc giá trị .env.

### Flutter — verified từ source

- Navigation bằng Navigator/MaterialPageRoute; state nằm trong StatefulWidget; HTTP service là static class. Chưa có repository/provider/BLoC/router.
- HomeScreen list/search qua GET /store/products với q. Search chỉ submit, không debounce. Brand chips iPhone/Samsung/Xiaomi/OPPO gửi brand như keyword query, không lọc trường brand.
- MedusaService có catalog list/detail, create cart, add line item và retrieve cart. Chưa có update/remove line, region, auth/customer, shipping, payment, complete cart hoặc orders.
- createCart gửi body rỗng. Medusa docs yêu cầu tạo cart gắn region; cart mặc định kế thừa sales channel của publishable API key nếu không chỉ định. Request hiện không gửi region.
- ProductDetailScreen nhận product đã tải từ Home; detail service method không được màn hình gọi. Mỗi variant là một ChoiceChip với title ghép, mặc định chọn variant đầu; chưa chọn Storage và Color riêng, chưa hiện brand/spec/stock, quantity không giới hạn theo stock.
- Product/Variant model thiếu brand, metadata/specs, inventory và currency-aware price. Giá fallback lấy prices[0] mà không chọn currency.
- Base URL hiện localhost cho web/iOS simulator/desktop và 10.0.2.2 cho Android emulator; publishable key nằm trực tiếp trong service. Không lặp lại giá trị key ở tài liệu. Cấu hình phù hợp local dev hơn physical device/deploy.
- Cart ID chỉ nằm trong Home state; app restart không khôi phục. Cart screen chỉ đọc item/total, không sửa/xóa. Nút đặt hàng chỉ hiện snackbar local, không gọi checkout.
- Có loading/error/empty cơ bản trong catalog/cart và error snackbar khi add; chưa chuẩn hóa lỗi/retry cho toàn flow.
- widget_test.dart là counter test mặc định, không khớp app.

### API map — code hiện tại

| Method/path | Tình trạng |
|---|---|
| GET /store/products với q tùy chọn | Flutter list/search; chưa gửi region_id/currency context |
| GET /store/products/{id} | Có service method, product detail screen hiện không gọi |
| POST /store/carts | Tạo cart với region_id Vietnam/VND |
| POST /store/carts/{cart_id}/line-items | Gửi variant_id và quantity |
| POST /store/carts/{cart_id}/line-items/{line_id} | Cập nhật quantity; response cart |
| DELETE /store/carts/{cart_id}/line-items/{line_id} | Xóa item; Medusa response trả updated cart trong parent |
| GET /store/carts/{cart_id} | Tải items/currency/totals cho cart |
| POST /store/search | Middleware backend cho phép product index; Flutter chưa gọi |
| GET /store/custom, GET /admin/custom | Custom mẫu, chỉ trả 200 |
| Update/delete line, address, shipping, payment, complete, customer, orders | Chưa được Flutter gọi |

Tài liệu chính thức hiện hành xác nhận cart cần region; line item có add/update/delete API; checkout tách address, shipping, payment provider/session và complete cart. Complete cart cần kiểm tra response type: order nghĩa là đặt order thành công, cart nghĩa là lỗi; không suy ra payment đã thu chỉ từ việc complete cart trả về. Tham khảo [Cart setup](https://docs.medusajs.com/resources/storefront-development/cart), [cart line items](https://docs.medusajs.com/resources/storefront-development/cart/manage-items), [shipping](https://docs.medusajs.com/resources/storefront-development/checkout/shipping), [payment](https://docs.medusajs.com/resources/storefront-development/checkout/payment), [complete cart](https://docs.medusajs.com/resources/storefront-development/checkout/complete-cart).

### Next.js storefront — reference-only

- App có data modules cho products, cart, customer, fulfillment, payment, orders; dùng Medusa JS SDK cùng phiên bản.
- Search client dùng /store/search; backend index và storefront search client cùng khai báo EUR/USD.
- Có thể tham khảo API call patterns, nhưng không coi storefront là API specification. Xác minh lại qua official docs và source version trước khi copy.
- Không mở rộng storefront trong roadmap chính. Nếu cần chạy nó với VN/VND, thêm task đồng bộ search currency và kiểm tra UI.

### Debt, rủi ro hiện hữu, phần chưa kiểm tra

- **Verified:** source seed là clothing/Europe/EUR trong khi Flutter format VND và UI hướng phone brands.
- **Verified:** root seed alias chưa nối đến backend seed script; source seed ban đầu không thể coi là idempotent.
- **Verified:** cart creation thiếu region; brand filter chỉ là text search; cart/order chưa giao dịch thật.
- **Verified:** local API hosts, hardcoded publishable key, Android cleartext HTTP setting.
- **Inferred:** EUR/USD có thể hiển thị như VND do model/formatter không ràng buộc currency; cần xác minh response runtime sau khi có region VND.
- **Not checked:** dữ liệu DB, key/channel linkage, provider, fulfillment set, inventory thực, Admin order visibility, CORS/network trên thiết bị và API runtime.
- Chưa có bằng chứng cần Brand module. Đề xuất lưu brand trong product metadata và mở rộng search index thành brand filterable/facetable; giữ category “Điện thoại” và native Product Option/Variant.

## 4. File map theo bằng chứng

| File/nhóm | Hành động dự kiến | Phase/ticket | Lý do |
|---|---|---|---|
| apps/backend/src/migration-scripts/initial-data-seed.ts | Modify candidate | 1 / BE-02, BE-03 | Source Europe/EUR, warehouse Europe, apparel, Size, EUR/USD |
| apps/backend/src/scripts/seed-demo-products.ts | Modify candidate hoặc retire candidate sau caller check | 1 / BE-03 | Tạo thêm 50 apparel theo lệnh thủ công |
| apps/backend/package.json | Modify candidate | 1 / BE-01 | Chưa có script seed trong khi root alias nhắm task đó |
| apps/backend/src/scripts/seed-phone-store.ts | Create candidate sau khi xác minh CLI entrypoint | 1 / BE-01 | Có thể tạo custom Medusa CLI entrypoint; tránh hai nguồn seed |
| apps/backend/src/search/product.ts | Modify candidate | 1 / BE-04 | Index hiện không lấy metadata.brand |
| apps/backend/src/search/helpers/pricing.ts | Modify candidate | 1 / BE-04 | Chỉ có EUR/USD, chưa có VND |
| apps/backend/src/search/helpers/option-values.ts | No change dự kiến | 1 / BE-04 | Đã flatten native option values; có thể dùng cho Storage/Color |
| apps/backend/medusa-config.ts | No change dự kiến | 1 | Chưa thấy nhu cầu custom module; provider/config xác minh ở phase tương ứng |
| apps/backend/src/api/middlewares.ts | No change dự kiến | 1 | Đã bật product search middleware |
| apps/backend/src/api/store/custom/route.ts và src/api/admin/custom/route.ts | No change | 1 | Stub không tham gia flow; không xóa khi chưa kiểm tra external caller |
| apps/backend/src/modules, src/workflows, src/links, src/jobs, src/subscribers | No change | 1 | README placeholder; chỉ tạo code nếu chứng minh native Medusa thiếu khả năng |
| apps/mobile/lib/services/medusa_service.dart | Modify candidate | 2–7 / FE-01+ | URL/key/region config và service methods theo contract |
| apps/mobile/lib/models/product.dart | Modify candidate | 2 / FE-02, FE-03 | Thiếu metadata/options/inventory/currency-aware prices |
| apps/mobile/lib/screens/home_screen.dart | Modify candidate | 2 / FE-02 | Brand chip đang dùng keyword |
| apps/mobile/lib/screens/product_detail_screen.dart | Modify candidate | 2 / FE-03 | Object list truyền trực tiếp, variant ghép, thiếu stock/spec/options |
| apps/mobile/lib/screens/cart_screen.dart | Modify | 3 / FE-04 | Đồng bộ line mutations/totals với Medusa, loading/error/retry; checkout thuộc Phase 6 |
| apps/mobile/lib/services/cart_storage.dart | Create | 3 / FE-04 | Lưu guest cart ID trên thiết bị qua SharedPreferencesAsync |
| apps/mobile/lib/main.dart | No change dự kiến | 2 | Entry point đơn giản; chỉ sửa nếu routing/config cần |
| apps/mobile/test/widget_test.dart | Modify candidate | 9 / TEST-03 | Counter test không khớp PhoneStoreApp |
| apps/mobile/pubspec.yaml | Modify | 3 / FE-04 | Thêm shared_preferences cho cart ID bền qua lần mở app |
| apps/mobile/android/app/src/main/AndroidManifest.xml | No change Phase 1 | 2 hoặc 10 | Cleartext HTTP đang bật cho dev; quyết định theo target |
| apps/storefront/src/lib/search-client.ts | No change trong MVP Flutter | — | Reference-only; đồng bộ nếu sau này dùng ở VN |
| apps/backend/.env và generated/dependency folders | Off-limits | Tất cả | Không đọc/in secret; không sửa output/dependency |

Không đánh dấu file nào để xóa ở audit. seed-demo-products.ts chỉ được retire sau khi kiểm tra external use và tình trạng data/DB; không xóa file để xóa dữ liệu hiện có.

## 5. Roadmap theo Phase 0–12

Các phase 0–9 đi theo dependency để hoàn thành core commerce; Phase 10 dành cho MVP+ optional sau core flow; Phase 11 kiểm thử và Phase 12 cleanup/demo. Authentication (Phase 4) tách khỏi Customer/Address (Phase 5). Payment và Checkout cùng ở Phase 7 như yêu cầu.

| Phase | Mục tiêu/deliverables | Dependency | Exit criteria | Rủi ro |
|---|---|---|---|---|
| 0 — Project audit | Baseline, API map, gaps, file map, roadmap; hoàn tất lượt này | — | Không suy diễn live DB; xác định Phase 1 | Runtime chưa kiểm tra |
| 1 — Backend phone store foundation | Seed an toàn; Vietnam/VND, channel, inventory location, standard/express; category, metadata brand/spec, 20–30 phone products, Storage/Color variants, VND index | Phase 0 + INT-02 | API đọc phone products theo region/channel VN/VND; có giá/stock; không dựa clothing; seed rerun-safe ở DB test | DB/provider chưa biết; shipping fee chưa chốt |
| 2 — Flutter catalog | Target API/region config; list/search/brand filter thật; loading/empty/error; product detail/variant selection | Phase 1 source contract; INT-03 gates live verification | Source có thể lọc brand/search; Storage+Color resolve đúng variant với giá/stock từ Store API | DB/key/channel/runtime chưa kiểm tra |
| 3 — Cart | Cart persistence, add/retrieve/update/remove, totals, retry/error | Phase 2 source; INT-04 runtime vẫn pending | Cart đúng region/variant; quantity và total lấy từ Medusa | Cart cũ hoặc region mismatch |
| 4 — Authentication | Register/login/logout/current customer; secure persistent auth; expired/401 handling | Phase 3 | Đăng ký, đăng nhập, logout; app khôi phục trạng thái auth sau restart | Chưa có safe Medusa target/customer để test live |
| 5 — Customer & Address | Profile phone/address; form địa chỉ checkout VN và validation; attach customer/address vào cart | Phase 4 | Lấy/lưu address hợp lệ và dùng được trong cart/checkout | Guest/account association, field contract |
| 6 — Shipping | Load backend options, chọn Standard/Express, update cart | Phase 1 + Phase 5 | Cart có shipping method backend-provided, total cập nhật | Service zone/rate không hợp địa chỉ |
| 7 — Payment & checkout | Providers; payment collection/session; review; complete cart | Phase 6 | Response type order; lỗi không thành success giả | Provider/manual semantics với VND |
| 8 — Order | Success từ returned order; order history/detail và access | Phase 7 | Cùng order xem được trong app và Medusa Admin | Guest order access |
| 9 — UX/error | Loading, empty, retry, validation, timeout, auth, stock, shipping/payment/order errors | Phase 2–8 | Flow chính không crash hoặc báo sai thành công | Chưa có test environment |
| 10 — MVP+ | Promotion, wishlist, recently viewed, sort/filter nâng cao sau khi core flow hoạt động | Phase 0–9 | Optional không chặn checkout/order | Chỉ bắt đầu nếu core flow và deadline cho phép |
| 11 — Testing | Backend/service/widget/integration/manual E2E trên DB an toàn | Phase 1–9 | Flow catalog→order lặp được; Admin xác nhận | Cần PostgreSQL/provider và target an toàn |
| 12 — Cleanup/demo | Dọn placeholder an toàn, setup demo/tài liệu, chốt limitation | Phase 11 | Demo lặp lại được; không xóa seed/data nhầm | Không dọn dữ liệu chưa xác minh |

### Chi tiết Phase 1 — Backend Phone Store Foundation

**Goal:** source setup tạo nền phone store Vietnam/VND bằng Product/Variant/Inventory/Shipping native.

**Current state sau implement:** source seed cấu hình Vietnam/VND, giữ các currency cũ, dùng Default Sales Channel, tạo Vietnam stock location/service zone và Standard/Express Delivery. Root seed alias đã nối tới custom CLI script. Catalog có 20 model/4 brand với Storage/Color, SKU, metadata và tồn mẫu. Search index có brand và VND fields. Chưa seed hoặc xác minh DB/runtime.

**Files đã chạm:** `apps/backend/package.json`; `src/migration-scripts/initial-data-seed.ts` và `src/scripts/seed-demo-products.ts` giữ đường dẫn tương thích và chuyển sang nguồn seed phone duy nhất; `src/scripts/seed-phone-store.ts`; `src/scripts/phone-catalog.ts`; unit tests catalog; `src/search/product.ts`, `src/search/helpers/pricing.ts`, `src/search/helpers/metadata.ts` và unit tests. Không sửa Flutter/storefront ở Phase 1.

**API liên quan:** Store API product list/detail và region; publishable key giới hạn product/cart theo sales channel. /store/search đã cấu hình nhưng mobile chưa dùng. Xác minh payload/fields trên Medusa 2.21.1 trước implementation; không thêm route proxy cho API native.

**Tasks Phase 1:**

- **INT-02 — Contract:** hoàn tất metadata.brand/facet, category “Điện thoại”, Storage/Color options, custom CLI path; phí giao hàng dùng demo estimates 30.000/50.000 VND và cần thay bằng rates của carrier.
- **BE-01 — Seed entrypoint/rerun safety:** source hoàn tất; root alias gọi Medusa custom CLI script; seed tạo/skip setup, products và inventory levels theo idempotent checks. Runtime rerun chưa kiểm chứng.
- **BE-02 — Commerce config:** source hoàn tất cho VN/VND, publishable key/channel linkage, Vietnam location/service zone và Standard/Express options.
- **BE-03 — Phone catalog:** source hoàn tất với 20 model/4 brand, specs metadata, Storage/Color, SKU/VND và 5 tồn ban đầu mỗi variant. Catalog, giá và stock được đánh dấu demo, cần xác minh trước khi bán.
- **BE-04 — Search index:** source hoàn tất cho brand filter/facet, VND price fields và metadata brand extraction. Runtime freshness sau Admin changes chưa kiểm chứng.
- **INT-03 — Verify Phase 1:** pending safe DB; không chạy seed trên DB user. Cần kiểm tra API region/products/search/shipping, channel scope và inventory levels trên disposable database.

**Definition of Done:** Store API đọc 20–30 phone products được publish vào Flutter channel, region VN/VND; category/brand/spec/options/SKU/price/inventory đúng; Standard/Express backend-provided; seed chạy lại an toàn trên DB test; không phụ thuộc clothing seed. Source/build pass chưa đủ nếu chưa xác minh API trên environment phù hợp.

**Còn lại:** safe disposable DB và API evidence; carrier rates/SLA thực tế; xác minh cấu hình/SKU/giá sản phẩm với nguồn phân phối tại VN; xác minh key Flutter đang dùng có channel scope đúng. Không chạy seed vào DB chưa xác minh.

### Chi tiết Phase 2 — Flutter Product Catalog

**Goal:** catalog Flutter đọc sản phẩm, giá, tồn kho, brand và options từ Medusa; người dùng tìm kiếm/lọc và chọn chính xác variant Storage + Color.

**Current state sau implement:** source Phase 2 hoàn tất. Service nhận base URL và publishable key qua `--dart-define`, tự tìm region có currency VND và country VN, tìm kiếm bằng `POST /store/search` với `filters.q`/`filters.brand`, rồi lấy product đầy đủ từ Store API. Giá chỉ đọc từ `variants.calculated_price`; tồn kho yêu cầu `+variants.inventory_quantity`. Detail tải lại dữ liệu mới nhất và đối chiếu option ID để chọn variant. Medusa 2.21.1 đăng ký PostgreSQL Search Provider mặc định ở local development; database search-index migration và index freshness chưa xác minh. Chưa có API/database smoke test, nên chưa xác nhận region, key/channel hoặc payload trong môi trường đang chạy.

**Medusa contract đã xác minh:** Medusa cài trong backend là 2.21.1. Official Store Search nhận `entity: "product"`, `filters` có `q` và giá trị brand đúng; product index source đánh dấu brand filterable/facetable/retrievable và route middleware scope products theo publishable key. Store Product API nhận `region_id`, trả `calculated_price`, cho phép thêm `+variants.inventory_quantity`; product list route trong package cài sẵn cho phép `*variants.options`, `*options.values`, `variants.options.option` và metadata. `GET /store/regions` trả `currency_code`/countries. Contract được đối chiếu docs Medusa cùng source package 2.21.1; live response chưa kiểm tra.

**Files đã chạm:** `apps/mobile/lib/services/medusa_service.dart`, `apps/mobile/lib/models/product.dart`, `apps/mobile/lib/screens/home_screen.dart`, `apps/mobile/lib/screens/product_detail_screen.dart`, một callsite trong `apps/mobile/lib/screens/cart_screen.dart` để dùng service instance mới, và `apps/mobile/README.md` cho target configuration. Không đổi hành vi giỏ hàng/checkout.

**Tasks Phase 2:**

- **FE-01 — API config/service:** source hoàn tất cho base URL/key compile-time defines, region Vietnam/VND, timeout/network/status errors và native product/detail/cart service calls. Key/endpoint của target thật và channel scope chưa xác minh.
- **FE-02 — Catalog/search/filter:** source hoàn tất cho search debounce, brand exact filter, responsive catalog, loading/empty/error/retry và refresh. Search API/provider/index trên DB chưa kiểm tra.
- **FE-03 — Product detail/options:** source hoàn tất cho metadata brand/specs, VND calculated price, current inventory, option pickers, variant matching, stock-aware quantity và retry khi detail lỗi. Chưa có runtime evidence.
- **INT-04 — Verify catalog integration:** pending INT-03 và target API/key; kiểm tra API search, giá/stock, brand chips, Storage/Color trên backend an toàn.

**Definition of Done:** source có static analysis không lỗi; UI search/lọc brand, hiển thị trạng thái tải/lỗi/rỗng, xem thông số và chọn variant từ option ID. Phase 2 runtime gate vẫn pending cho đến khi INT-03/INT-04 xác nhận dữ liệu qua API target. Không đánh dấu API/database DoD chỉ từ source.

**Verification lượt này:** `dart format` hoàn tất; `dart analyze lib` exit 0, còn các lint `info` sẵn có và đề xuất style. `flutter analyze` không trả diagnostic mà dừng do LSP JSON `FormatException`; Flutter tests và DB/API request không chạy.

### Chi tiết Phase 3 — Medusa Cart

**Goal:** giữ cart guest giữa các lần mở app; tạo cart theo region Vietnam/VND; thêm, tải, đổi số lượng và xóa line item qua Medusa; hiển thị currency/totals từ response. Checkout chưa nằm trong phase này.

**Current state sau implement:** source và automated tests cart đã hoàn tất. `CartStorage` dùng `SharedPreferencesAsync` để giữ cart ID; Home khôi phục ID trước khi mở detail/cart; Product Detail giữ ID mới trong state và lưu sau khi tạo cart. Medusa service tạo cart với `region_id`, bổ sung update/remove line routes và parse response `cart`/`parent`. Cart screen hiển thị item/quantity, đổi số lượng/xóa, tải lại/retry và hiển thị tổng server theo `currency_code`. Nút “Đặt hàng ngay” giả đã được bỏ; UI ghi rõ checkout đến phase sau.

**Medusa contract đã xác minh:** Medusa Storefront docs yêu cầu gửi `region_id` khi tạo cart; Add/Update line item trả updated cart, Delete line item trả cart trong `parent`; line-item routes nhận variant/quantity và item ID theo API. GET cart được yêu cầu mở rộng các trường `items.*` và tổng cần cho UI. Shared Preferences package docs khuyến nghị `SharedPreferencesAsync` cho API mới; package `shared_preferences` 2.5.5 đã được thêm qua `flutter pub add`.

**Files đã chạm:** `apps/mobile/lib/services/medusa_service.dart`, `apps/mobile/lib/services/cart_storage.dart`, `apps/mobile/lib/screens/home_screen.dart`, `apps/mobile/lib/screens/product_detail_screen.dart`, `apps/mobile/lib/screens/cart_screen.dart`, `apps/mobile/pubspec.yaml` và lockfile; package manager cập nhật `apps/mobile/macos/Flutter/GeneratedPluginRegistrant.swift`. Tests nằm trong `apps/mobile/test/services/cart_storage_test.dart`, `apps/mobile/test/services/medusa_service_cart_test.dart` và `apps/mobile/test/widget_test.dart`. Không có seed/migration/database request.

**Tasks Phase 3:**

- **FE-04 — Cart source + tests:** hoàn tất cho region-aware create, persistent cart ID, add/retrieve/update/remove, server totals, currency formatting và retry/error. `flutter test` pass toàn bộ 12 tests. `dart analyze lib test` exit 0; còn một lint `info` có sẵn trong `main.dart`.
- **INT-04 — Product/cart integration:** vẫn pending INT-03 và target API/key; cần tạo cart trên safe target, thêm variant đã chọn, sửa/xóa item và đối chiếu total response.

**Definition of Done:** FE-04 source/test gate pass; Phase 3 live integration gate vẫn pending. Cart API/device chưa được gọi, nên region/variant/mutations/totals chưa có runtime evidence trên Medusa. Checkout/address/payment chưa thực hiện.

**Verification Phase 3:** `flutter test` exit 0: toàn bộ 12 tests pass, gồm persistence, region-aware cart creation, line mutations, totals, retry, cart ID reuse và restore. `dart format` hoàn tất; `dart analyze lib test` exit 0 với 1 lint `info` có sẵn ở `main.dart`; `git diff --check` exit 0. Mocked tests không xác minh live Medusa API/database/device. `flutter pub add shared_preferences` hoàn tất; Windows plugin build chưa được kiểm tra.

### Chi tiết Phase 4 — Authentication

**Goal:** register/login/logout/current customer theo Medusa v2; giữ JWT qua lần mở app và bỏ token hết hạn sau HTTP 401. Customer address form thuộc Phase 5.

**Current state sau implement:** Home có đường vào tài khoản. Profile tải trạng thái hiện tại; khách chưa đăng nhập có thể mở Login/Register; đăng nhập thành công tải lại profile; đăng ký tự đăng nhập; logout xóa token ở thiết bị. JWT được lưu bằng `flutter_secure_storage`, không lưu trong Shared Preferences. Medusa service xóa token khi `/store/customers/me` trả 401.

**Medusa contract đã xác minh:** register dùng `POST /auth/customer/emailpass/register`, tạo customer bằng `POST /store/customers` với registration bearer token, rồi đăng nhập lại qua `POST /auth/customer/emailpass` để lấy actor token trước khi gọi `GET /store/customers/me`. Với JWT, logout là xóa token local; không gọi session DELETE. Tham khảo [Medusa register](https://docs.medusajs.com/resources/storefront-development/customers/register), [login](https://docs.medusajs.com/resources/storefront-development/customers/login), [retrieve customer](https://docs.medusajs.com/resources/storefront-development/customers/retrieve), [logout](https://docs.medusajs.com/resources/storefront-development/customers/log-out) và [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage).

**Files đã sửa:** `apps/mobile/lib/services/medusa_service.dart`, `apps/mobile/lib/screens/home_screen.dart`, `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock` và generated plugin registrants của Flutter.

**Files tạo mới:** `apps/mobile/lib/models/customer.dart`, `apps/mobile/lib/services/auth_storage.dart`, `apps/mobile/lib/screens/login_screen.dart`, `apps/mobile/lib/screens/register_screen.dart`, `apps/mobile/lib/screens/profile_screen.dart`, `apps/mobile/test/services/auth_storage_test.dart`, `apps/mobile/test/services/medusa_service_auth_test.dart` và `apps/mobile/test/screens/auth_screens_test.dart`.

**Automated verification:** `flutter test` exit 0, toàn bộ 21 tests pass (12 Phase 3 + 9 Phase 4), gồm auth storage mock, Medusa request/payload, đăng ký/đăng nhập, 401 token cleanup, Home→Profile→Login→Logout, validation và lỗi đăng nhập. `dart analyze lib test` exit 0 với một `info` lint có sẵn trong `lib/main.dart`; `git diff --check` exit 0. Android debug APK build thành công qua `gradlew :app:assembleDebug -Pkotlin.incremental=false`; `flutter build apk --debug` mặc định gặp lỗi Kotlin incremental cache do source nằm trên ổ C: và F:.

**Definition of Done:** source/test gate PASS. Full Phase 4 **NOT YET COMPLETE**: tests dùng mocked HTTP/storage, nên chưa chứng minh được đăng ký/đăng nhập trên Medusa thật hoặc khôi phục secure token khi app restart trên thiết bị. Chưa có safe API target/customer credentials để chạy live auth; không gọi database hay API thật trong lượt này.

## 6. Task breakdown

Owner A = backend/Medusa; B = Flutter; C = integration/QA. Vai trò gợi ý, không phải tên người. Mỗi task có một owner và một kết quả reviewable.

| ID / Priority | Phase / Owner | Dependencies | File scope | Deliverable + acceptance | Verification / blocker |
|---|---|---|---|---|---|
| INT-01 / P0 | 0 / C | — | Root guidance, manifests, backend/mobile source, tests/config | Audit, API map, roadmap; **completed** | Source review + baseline checks; live DB chưa kiểm tra |
| INT-02 / P0 | 1 / A+C | INT-01 | Roadmap + seed contract | Chốt metadata.brand/facet, options, seed target; shipping rates được ghi rõ là demo | Source/docs review; rates thực tế còn cần carrier |
| BE-01 / P0 | 1 / A | INT-02 | apps/backend/package.json; seed entrypoints | Root seed alias, single source, idempotent checks | Typecheck/build; rerun integration chưa kiểm tra |
| BE-02 / P0 | 1 / A | BE-01, INT-02 | Seed source | VN/VND, channel/key linkage, location, zone, Standard/Express | Typecheck/build; DB/API smoke còn pending |
| BE-03 / P0 | 1 / A | BE-02 | Seed source; phone-catalog.ts | 20 phones/four brands, metadata, Storage/Color, SKU, VND, stock | Unit tests pass; safe DB/API query pending |
| BE-04 / P0 | 1 / A | BE-03 | search/product.ts; helpers | Brand + VND indexed/filterable | Unit tests pass; runtime index check pending |
| INT-03 / P0 | 1 / C+A | BE-02–BE-04 | Không bắt buộc sửa file | Xác minh regions/products/variants/inventory/shipping qua API | Cần PostgreSQL disposable/target env |
| FE-01 / P0 | 2 / B | INT-02, BE-04 | apps/mobile/lib/services/medusa_service.dart; apps/mobile/README.md | URL/key compile-time config; chọn VN/VND; Store API service và lỗi rõ; **source done** | `dart analyze lib` pass; target key/channel và API smoke pending INT-03 |
| FE-02 / P0 | 2 / B | FE-01, BE-04 | apps/mobile/lib/screens/home_screen.dart; apps/mobile/lib/models/product.dart | Catalog, debounce, exact brand filter, loading/empty/error/retry; **source done** | `dart analyze lib` pass; search provider/index + UI runtime pending INT-04 |
| FE-03 / P0 | 2 / B | FE-01, BE-03 | apps/mobile/lib/screens/product_detail_screen.dart; apps/mobile/lib/models/product.dart; service | Detail, specs, calculated price, inventory, Storage/Color→variant; **source done** | `dart analyze lib` pass; target payload/stock pending INT-04 |
| INT-04 / P0 | 2–3 / C | FE-02, FE-03, INT-03 | Không bắt buộc sửa file | Catalog→detail→selected variant→cart hoạt động thật | Smoke test với variant có inventory |
| FE-04 / P0 | 3 / B | INT-04, FE-01 | service; cart_screen.dart; cart_storage.dart; pubspec + lock; cart tests | Cart create/retrieve/add/update/remove; giữ cart ID; totals từ response; **source + tests done** | 12 Flutter tests pass; cart API/device runtime pending INT-04 |
| FE-05 / P0 | 4 / B | FE-04, INT-02 | Customer model, secure auth storage, Login/Register/Profile, service | Register/login/current customer/logout và giữ JWT; **source + tests done** | 9 Phase 4 tests pass; live Medusa/device auth pending |
| FE-05B / P0 | 5 / B | FE-05, FE-04 | `customer_address.dart`, address book/form, profile, service, checkout | **Source implemented:** VN form/validation, customer CRUD, copy address to cart | `dart analyze lib` pass; tests và live API pending |
| FE-06 / P0 | 6 / B | BE-02, FE-05B | `shipping_option.dart`, checkout, Medusa service | **Source implemented:** backend options, calculated price, shipping method, refreshed cart totals | `dart analyze lib` pass; real rates/totals pending safe DB |
| BE-05 / P0 | 7 / A | BE-02, INT-02 | Region/provider seed/config source | System/COD ID source contract checked; no fake payment | Region provider list, session and order still need demo DB check |
| FE-07 / P0 | 7 / B | FE-06, BE-05 | `payment_provider.dart`, checkout and review | **Source implemented:** system provider, collection/session, guarded complete and response handling | `dart analyze lib` pass; provider/failure tests pending |
| INT-05 / P0 | 7 / C+A+B | FE-07, BE-05, INT-03 | Shared checkout contract; custom backend only if a proven gap exists | Complete cart; only returned order becomes success | Blocked on safe DB and Admin verification |
| FE-08 / P0 | 8 / B | INT-05, FE-05B | `customer_order.dart`, success/history/detail screens | **Source implemented:** returned order, authenticated list and snapshot detail | `dart analyze lib` pass; app/Admin order visibility pending |
| FE-09 / P1 | 9 / B+C | FE-02–FE-08 | Screens/services đã chạm | Error/empty/retry/auth/stock/payment/order recovery paths are present | Failure matrix and widget checks not run |
| MVP-01 / P2 | 10 / B | FE-08, FE-09 | Optional feature candidates | Promotion/wishlist/recently viewed/sort/filter sau core commerce | Chỉ làm sau khi core flow chạy và có thời gian |
| TEST-01 / P0 | 11 / C | INT-02, INT-03 | Test plan/checklist | Acceptance matrix, fixture và môi trường safe order | Review trước integration; DB/provider available |
| TEST-02 / P0 | 11 / A | BE-01–BE-05, TEST-01 | Backend test files candidate | Seed idempotence/search/provider custom behavior | Unit; integration cần PostgreSQL |
| TEST-03 / P0 | 11 / B | FE-01–FE-08, TEST-01 | widget_test.dart và test files candidate | Service/state/widget/integration tests | `flutter test` và thiết bị target |
| TEST-04 / P0 | 11 / C+A+B | INT-05, FE-08, TEST-02, TEST-03 | Không bắt buộc sửa file | Full flow và Admin order evidence | Chỉ PASS khi có runtime evidence |
| TEST-05 / P0 | 12 / C | TEST-04 | README/setup/demo docs candidate | Repeatable setup, demo catalog/order checklist, limitations | Demo lặp lại được |

## 7. Dependency graph

~~~mermaid
flowchart TD
  I1["INT-01 Phase 0 audit — done"] --> I2["INT-02 data/API/seed contract"]
  I2 --> B1["BE-01 seed runner and safety"]
  B1 --> B2["BE-02 Vietnam/VND/channel/inventory/shipping"]
  B2 --> B3["BE-03 phone catalog and variants"]
  B3 --> B4["BE-04 brand and VND search index"]
  B2 --> I3["INT-03 verify backend in safe DB"]
  B3 --> I3
  B4 --> I3
  I2 --> F1["FE-01 target API config"]
  B4 --> F1
  F1 --> F2["FE-02 catalog and brand search"]
  F1 --> F3["FE-03 details and variant selection"]
  F2 --> I4["INT-04 catalog/detail/cart integration"]
  F3 --> I4
  I3 --> I4
  I4 --> F4["FE-04 cart"]
  F4 --> F5["FE-05 authentication"]
  F5 --> F5B["FE-05B customer and address"]
  F5B --> F6["FE-06 shipping UI"]
  B2 --> F6
  F6 --> B5["BE-05 payment provider verification"]
  B5 --> F7["FE-07 payment and checkout"]
  F7 --> I5["INT-05 complete cart and verify order"]
  I3 --> I5
  I5 --> F8["FE-08 order success/history"]
  F8 --> F9["FE-09 UX/error"]
  F9 --> M1["MVP+ optional after core flow"]
  I2 --> T1["TEST-01 acceptance matrix"]
  T1 --> T2["TEST-02 backend tests"]
  T1 --> T3["TEST-03 Flutter tests"]
  I5 --> T4["TEST-04 end-to-end/Admin"]
  F8 --> T4
  T2 --> T4
  T3 --> T4
  T4 --> T5["TEST-05 Phase 12 demo handoff"]
~~~

Source path: seed/search contract → Flutter API/service → catalog → detail/variant → cart → authentication → customer/address → shipping → payment/checkout → order. Live verification path: safe DB setup → INT-03/INT-04 → real auth and address → provider/session/complete cart → Admin order verification. Phase 11 E2E and Phase 12 demo require runtime evidence; provider and safe target remain blockers.

## 8. Ba-owner split đề xuất

| Owner | Primary ownership | Handoff |
|---|---|---|
| A — Backend/Medusa | BE seed, region/catalog/inventory/shipping/search/provider | Công bố data/API contract cho B và environment evidence cho C; không sửa DB thật nếu chưa có scope rõ |
| B — Flutter | FE config, models/services, catalog/detail/cart/auth/address/checkout/orders | Bám contract trong INT tickets; owner screens/service/state |
| C — Integration/QA | INT/TEST, docs/API checks, E2E/Admin evidence, demo docs | Điều phối interface; không sửa file A/B-owned nếu chưa thống nhất |

Có thể tách source planning backend và UI inventory sau INT-02. Catalog và detail UI chỉ chạy song song khi shared model/service contract ổn định. DB verification/E2E phải chờ setup phụ thuộc.

## 9. MVP checklist

- [ ] Target DB có Vietnam region/VND và publishable key liên kết Flutter channel.
- [ ] API trả 20–30 phone products thuộc bốn brands.
- [ ] Product có ảnh/brand/spec metadata và native Storage/Color options.
- [ ] Variant có SKU, VND price, Medusa inventory.
- [ ] Search và brand filter dùng dữ liệu backend.
- [ ] Detail resolve đúng Storage+Color và dùng giá/stock backend.
- [ ] Cart ID khôi phục theo policy; update/remove/totals làm việc qua Medusa.
- [ ] Customer/address VN hợp lệ gắn vào đúng cart.
- [ ] Standard/Express và phí do backend cung cấp.
- [ ] Payment provider/session đúng config; UI không nói đã thu tiền nếu provider chưa xác nhận.
- [ ] Complete cart trả order; success dùng chính order đó.
- [ ] Cùng order xem được trong Medusa Admin và Flutter history/detail.
- [ ] Network/auth/stock/shipping/payment/completion failures có cách xử lý.
- [ ] Demo lặp lại được mà không chạy seed trên DB chưa xác minh.

## 10. Exact development order

1. INT-01 — audit, done.
2. INT-02 — chốt brand/spec/variant/shipping/seed safety contract.
3. BE-01 — nối seed entrypoint và rerun-safe setup.
4. BE-02 — Vietnam/VND, channel linkage, warehouse và shipping.
5. BE-03 — phone catalog, native variants/prices/inventory.
6. BE-04 — brand/VND search index và freshness.
7. INT-03 — verify Phase 1 trong disposable DB; dừng nếu chưa có safe target.
8. FE-01 — target-specific API/key/region config.
9. FE-02 và FE-03 — catalog và detail song song sau khi FE-01 contract ổn.
10. INT-04 — tích hợp product-to-cart.
11. FE-04 — persistent cart và line mutations (**source done; runtime acceptance vẫn chờ INT-04**).
12. FE-05 — authentication source/tests done; live Medusa/device verification pending.
13. FE-05B — customer/address VN, profile and checkout form.
14. FE-06 — shipping backend-provided.
15. BE-05 — payment provider semantics.
16. FE-07 — session/review/complete cart.
17. INT-05 — order response và Admin verification.
18. FE-08 — success/history/detail.
19. FE-09 — quality/failure matrix after core commerce.
20. MVP-01 — optional only after core flow.
21. TEST-01, TEST-02, TEST-03 — plan/backend/Flutter checks.
22. TEST-04 — end-to-end order trên safe environment.
23. TEST-05 — demo hardening and cleanup.

Implementation đã có source đến Phase 8: auth, address, shipping, COD checkout và order screens. Automated tests chưa chạy; các live gates từ Phase 4 trở đi vẫn cần safe Medusa target/customer và order test.

## 11. Risk register

| Risk | Likelihood/impact | Mitigation/evidence | Owner |
|---|---|---|---|
| Medusa route/provider khác theo version | Medium/High | Backend khóa 2.21.1; xác minh docs và installed source trước API task | A+C |
| DB thật khác seed source | Unknown/High | Không seed/reset DB chưa xác minh; test ở DB disposable | A |
| Seed rerun an toàn chưa được xác minh trên DB | Medium/High | Source đã có skip/idempotent checks; chỉ chạy hai lần trên DB demo riêng để xác minh runtime | A |
| Backend seed runtime chưa được xác minh | Medium/High | Root `backend:seed` và script backend đã được nối trong source; xác minh khi OPS-01 có DB demo | A |
| Region/currency/product price runtime mismatch | Medium/High | Source hiện cấu hình Vietnam/VND và Flutter đọc region VND; API/key/channel/giá thật chưa kiểm tra | A+B |
| Search index thiếu/stale brand hoặc VND | Medium/High | Source index đã có brand/VND; freshness sau cập nhật Admin và DB index vẫn cần runtime check | A |
| Stock/price đổi giữa detail và checkout | Medium/High | Medusa cart/complete là authority; xử lý reject | A+B |
| COD/manual state gây hiểu nhầm đã thu tiền | Medium/High | Verify provider/session/order status; tách “order created” và “payment captured” | A+C |
| Emulator/browser/device khác host | High/Medium | Base URL configurable theo target; test intended device/CORS | B |
| Publishable key chưa có trong môi trường chạy | High/High | Flutter nhận key qua `--dart-define`; lần mở app 2026-10-08 thiếu key nên catalog không tải | B+A |
| Flutter build/run trên Windows | Medium/Medium | APK debug build được bằng workaround Gradle; `flutter run` từng lỗi Kotlin incremental cache do project/cache khác ổ; cần xác minh lại hot reload | B |
| Optional Next storefront mismatch VND | Medium/Low với Flutter MVP | Reference-only; tạo follow-up nếu dùng Next với VN | C |
| Backend tests thiếu, integration cần PostgreSQL | High/High | Thiết lập isolated test DB; không suy diễn runtime từ source/lint | A+C |

## 12. Definition of Done

### Shared gate

- Checkout/version/API contract được xác minh; không dùng Medusa v1.
- Entity native Medusa tiếp tục là source of truth.
- Ticket có owner, dependencies, files, acceptance, verification result và blocker.
- Không đưa .env values/key vào tài liệu hoặc commit.
- Không seed/migrate/drop trên DB user chưa xác minh.
- UI phản ánh backend failure; không tạo success giả.
- Kết quả build/test/API ghi đúng trạng thái; thiếu runtime evidence là NOT YET COMPLETE.
- MVP chỉ PASS khi complete cart trả order và order đó xuất hiện trong Admin.

### Phase gate

- Phase 1 cần API evidence VN/VND, phone catalog/variants/inventory/channel/shipping và seed rerun-safe trên DB an toàn.
- Phase 2 source catalog đã xong; phase chỉ PASS khi INT-03/INT-04 xác nhận target region, brand search, server price/stock và variant response.
- Cart cần server price/stock, cart persistence và server totals.
- Phase 4 source/test gate đã pass; full PASS cần register/login/logout và token restoration qua Medusa/device thật.
- Phase 5 cần address VN hợp lệ được tải/lưu và gắn vào cart/checkout.
- Checkout/order cần address/shipping/provider state, returned order, Admin visibility và history.
- Test/demo chỉ PASS khi named checks qua trên environment dùng để demo.

## 13. First 10 P0 tasks

Phase 0–8 source đã triển khai. Local automated checks đã pass; ưu tiên còn lại là database demo an toàn, provider/session/complete runtime và Admin order evidence. Run/demo checklist có trong [`DEMO_GUIDE.md`](DEMO_GUIDE.md); full live flow chưa được xác minh.

| # | ID | Dependencies | Owner | First action | Status |
|---:|---|---|---|---|---|
| 1 | DEC-01 | — | B | Chốt phone normalization và chính sách input địa phương VN | **Done: +84 normalization; localities nhập text** |
| 2 | OPS-01 | Safe DB config | A | Khôi phục PostgreSQL demo riêng, kiểm tra backend health | **Blocked: connection timeout 2026-10-08** |
| 3 | INT-01 | OPS-01 | A+B | Chạy seed/migration trên DB mới, xác minh region/channel/key/catalog/shipping và rerun | **Blocked: chưa có safe DB evidence** |
| 4 | FE-ADDR-01 | DEC-01 | B | Model + validator địa chỉ VN | **Source done; field validation test coverage pending** |
| 5 | FE-ADDR-02 | FE-ADDR-01 | B | Customer address list/create/update/delete API | **Attach regression test pass; API/401 runtime pending** |
| 6 | FE-ADDR-03 | FE-ADDR-02 | B | Address book và form create/edit | **Source done; widget checks pending** |
| 7 | FE-ADDR-04 | FE-ADDR-03, INT-01 | B | Gắn customer, shipping/billing address vào cart | **Source done; API check cần DB demo** |
| 8 | FE-SHIP-01/02 | FE-ADDR-04, INT-01 | B | Chọn shipping option và cập nhật server totals | **Source done; rates/totals cần DB demo** |
| 9 | BE-PAY-01 | INT-01 | A | Xác minh manual/COD provider trên region VN | **Blocked: chưa kiểm tra runtime** |
| 10 | FE-CHECKOUT-01/02 | FE-SHIP-02, BE-PAY-01 | B | Review, payment session, complete cart chỉ success khi có order | **Source done; provider/session runtime pending** |

Sau đó: FE-ORDER-01/02 → QA-01/02 (E2E trên DB an toàn, xác nhận order trong Admin) → DOC-02 walkthrough demo.

## 14. Run và demo status

- Hướng dẫn thao tác theo từng bước nằm trong [`DEMO_GUIDE.md`](DEMO_GUIDE.md).
- Source Flutter hiện có catalog, cart, auth, sổ địa chỉ, shipping selection, COD checkout, order success/history/detail.
- Lần kiểm tra UI local: thiếu publishable key nên catalog hiện hướng dẫn cấu hình; không có request checkout/DB. Không chạy seed/migration hoặc API thật.
- Kiểm tra local: `dart format` sạch, `dart analyze` sạch, 24 tests pass, Web release build pass; `flutter analyze` wrapper lỗi JSON LSP riêng trên Windows. CI workflow đã thêm nhưng chưa chạy từ GitHub.
- Bản demo Web cần Medusa backend và publishable key reachable. Native Android/iOS build/signing vẫn cần xác minh riêng trên CI có SDK/credentials phù hợp.
- Chỉ đánh dấu MVP demo hoàn tất sau khi app tạo order thật bằng COD/manual và cùng order hiện trong app lẫn Medusa Admin.

## Official references

- [Medusa product listing and search](https://docs.medusajs.com/resources/storefront-development/products)
- [Medusa Store Search API route](https://docs.medusajs.com/resources/infrastructure-modules/search/store-search)
- [Medusa Store API search request/response](https://docs.medusajs.com/api/store/search)
- [Medusa create/persist cart](https://docs.medusajs.com/resources/storefront-development/cart)
- [Medusa retrieve cart and format prices](https://docs.medusajs.com/resources/storefront-development/cart/retrieve)
- [Medusa add/update/remove cart line items](https://docs.medusajs.com/resources/storefront-development/cart/manage-items)
- [Customer address flow](https://docs.medusajs.com/resources/storefront-development/checkout/address)
- [Manage customer addresses](https://docs.medusajs.com/api/store/customers/list-customers-addresses)
- [Shared Preferences package](https://pub.dev/packages/shared_preferences)
- [List Medusa regions](https://docs.medusajs.com/resources/storefront-development/regions/list)
- [Retrieve product prices](https://docs.medusajs.com/resources/storefront-development/products/price)
- [Retrieve product variant inventory](https://docs.medusajs.com/resources/storefront-development/products/inventory)
- [Select product variants](https://docs.medusajs.com/resources/storefront-development/products/variants)
- [Create and persist a Medusa cart](https://docs.medusajs.com/resources/storefront-development/cart)
- [Add/update/remove cart items](https://docs.medusajs.com/resources/storefront-development/cart/manage-items)
- [Select shipping method](https://docs.medusajs.com/resources/storefront-development/checkout/shipping)
- [Payment provider and session](https://docs.medusajs.com/resources/storefront-development/checkout/payment)
- [Complete cart and interpret returned order](https://docs.medusajs.com/resources/storefront-development/checkout/complete-cart)
- [Medusa custom CLI seed scripts](https://docs.medusajs.com/learn/fundamentals/custom-cli-scripts/seed-data)
- [Medusa product workflows](https://docs.medusajs.com/resources/commerce-modules/product/workflows)
- [Medusa product inventory in commerce flows](https://docs.medusajs.com/resources/commerce-modules/inventory/inventory-in-flows)
- [Medusa shipping options](https://docs.medusajs.com/resources/commerce-modules/fulfillment/shipping-option)

Medusa agentic skill và Medusa MCP không có trong công cụ hiện tại. Docs chính thức được tra qua Context7 và Medusa docs. Cài Medusa skill/MCP nêu trong AGENTS.md sẽ tăng chất lượng xác minh ở các phase implement.
