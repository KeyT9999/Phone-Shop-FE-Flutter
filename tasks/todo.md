# TODO — Checkout demo Phone Store

Plan liên kết: [`spec.md`](spec.md), [`design.md`](design.md), [`plan.md`](plan.md), [`ui-ux-plan.md`](ui-ux-plan.md).
Status hiện tại: **UI/UX và checkout source đã triển khai; local checks pass; database/catalog đã kết nối và xác minh. Live shipping/COD/order E2E và seed rerun safety còn mở**.

## UI/UX PRO MAX — Flagship Tech Boutique

- [x] Áp dụng design system chung cho 12 màn Flutter theo plan tại [`ui-ux-plan.md`](ui-ux-plan.md).
- [x] Thêm điều hướng 4 tab cho Khám phá, Giỏ hàng, Đơn hàng, Tài khoản; giữ route tập trung cho detail/checkout/forms/auth.
- [x] Rà loading, empty, error, disabled, tap target và responsive layout; smoke check ở 320 px và desktop.
- [x] Thêm GitHub Actions Flutter cho format/analyze/test/Web release + artifact; chưa deploy public.
- [x] Sửa contract gắn customer vào cart và thêm regression test.
- Trạng thái: **UI/CI hoàn tất ở source; checkout runtime vẫn pending**. `dart analyze` sạch, 24 Flutter tests pass, Web release build pass. `flutter analyze` wrapper vẫn crash khi parse JSON LSP trên Windows; workflow gọi trực tiếp `dart analyze`. Xem kết quả và giới hạn trong [`ui-ux-plan.md`](ui-ux-plan.md).

## 0. Quyết định và môi trường

### DEC-01 — Chốt chi tiết form địa chỉ

- [x] Chốt quy tắc chuẩn hóa số điện thoại; giữ input tỉnh/thành/quận/huyện/phường/xã dạng text cho bản demo.
- Acceptance: form và payload thống nhất; `country_code` cố định `vn`; không có danh mục địa phương tự tạo không rõ nguồn.
- Verify: review spec/design; validation/mapping có trong source, test còn chờ.
- Dependencies: —
- Files: `tasks/spec.md`, `tasks/design.md`
- Status: **Done**. Login-required, COD/system provider, billing=shipping, text input locality và `+84` phone normalization đã được chốt.

### OPS-01 — Kết nối backend database dự án

- [x] Khởi động Medusa với database Supabase do chủ dự án cung cấp; giữ credential trong env local.
- [x] Xác nhận backend health/Admin và Store API hoạt động.
- Acceptance: backend start ổn định, health phản hồi, không lộ credential trong log.
- Verify: health/Admin 2xx và Store API trả region/catalog; không chạy lệnh destructive.
- Dependencies: database URL được chủ dự án cung cấp và cấu hình local.
- Files: machine-local env; không commit.
- Status: **Done** — backend kết nối và catalog đã được xác minh.
### INT-01 — Seed và xác minh commerce contract

- [x] Chạy phone catalog seed một lần trên database dự án.
- [x] Xác nhận Vietnam/VND, 20 điện thoại/4 hãng, 137 variants có inventory và tìm kiếm iPhone trả 5 mẫu.
- [ ] Xác nhận shipping options/calculation; kiểm tra seed rerun safety trước khi chạy lại.
- Acceptance: catalog điện thoại dùng được trong app; shipping option và total phải đến từ Medusa.
- Verify: Store API smoke và catalog trên app đã pass; shipping calculation/rerun chưa xác minh.
- Dependencies: OPS-01.
- Files: không dự kiến sửa source; nếu phát hiện bug, tạo ticket riêng.
- Status: **Partial** — catalog live đã chạy; shipping và rerun safety vẫn pending.
## 1. Địa chỉ khách hàng

### FE-ADDR-01 — Address model và validation

- [x] Tạo model address và validator cho người nhận, số điện thoại, địa phương, địa chỉ chi tiết, postal code optional.
- Acceptance: normalize dữ liệu, trả lỗi theo field; mapping `country_code` luôn `vn`; không hardcode danh sách địa phương chưa được chọn nguồn.
- Verify: unit cases cho hợp lệ, rỗng, phone, whitespace, postal code và mapping.
- Dependencies: DEC-01.
- Files: `apps/mobile/lib/models/customer_address.dart`.
- Status: **Source implemented**; Flutter suite pass, nhưng chưa có test tập trung riêng cho validator của model.

### FE-ADDR-02 — Customer address API service

- [x] Thêm service methods list/create/update/delete saved addresses bằng Medusa Store API và auth headers hiện tại.
- Acceptance: parse/error mapping rõ; address thuộc customer token hiện tại; không gửi customer ID do user tùy ý nhập.
- Verify: mock HTTP tests cho methods, headers, body và 401.
- Dependencies: FE-ADDR-01.
- Files: `apps/mobile/lib/services/medusa_service.dart`, address model.
- Status: **Source implemented**; Flutter suite pass, live CRUD địa chỉ và 401 behavior vẫn chưa được xác minh.

### FE-ADDR-03 — Address list và form

- [x] Thêm list/empty/loading/error state; thêm/sửa/xóa/chọn address.
- Acceptance: form giữ dữ liệu sau lỗi; nút save khóa khi invalid/loading; xóa có xác nhận; checkout nhận address đã chọn.
- Verify: widget tests cho form validation, list states và save failure.
- Dependencies: FE-ADDR-02.
- Files: `apps/mobile/lib/screens/address_book_screen.dart`, `address_form_screen.dart`, navigation callsites.
- Status: **Source implemented**; Flutter suite pass, chưa có widget test tập trung cho form/list địa chỉ.

### FE-ADDR-04 — Gắn customer và address vào cart

- [x] Attach cart hiện tại với customer/email khi checkout; update shipping/billing address từ address đã chọn.
- Acceptance: Medusa cart response có customer/address đúng; shipping method cũ bị refresh nếu address đổi.
- Verify: service payload test và API smoke trên DB demo.
- Dependencies: FE-ADDR-03.
- Files: `medusa_service.dart`, cart/checkout screen.
- Status: **Source và payload regression test đã pass; live cart/address check vẫn pending.

## 2. Giao hàng

### FE-SHIP-01 — Shipping option service/model

- [x] Lấy shipping options cho cart có địa chỉ; parse ID, label, description, currency, backend price.
- Acceptance: service không tự tính phí; hỗ trợ empty options và lỗi API; nếu provider trả calculated price thì dùng API calculate trước khi chọn.
- Verify: mock payload test cho flat/calculated/empty/error.
- Dependencies: FE-ADDR-04.
- Files: `medusa_service.dart`, `apps/mobile/lib/models/shipping_option.dart`.
- Status: **Source implemented**; endpoint và giá thật chưa xác minh.

### FE-SHIP-02 — Chọn shipping method và refresh totals

- [x] Hiển thị phương thức có sẵn, chọn một option và thêm vào cart.
- Acceptance: selection dựa trên response backend; cart được tải lại; subtotal/shipping/discount/total hiển thị từ response; đổi địa chỉ yêu cầu tải options mới.
- Verify: widget/service tests; API smoke trên DB demo.
- Dependencies: FE-SHIP-01.
- Files: checkout/shipping screen, `cart_screen.dart`.
- Status: **Source implemented**; cart totals cần xác nhận trên DB demo.

## 3. Payment và checkout

### BE-PAY-01 — Xác minh payment provider demo

- [ ] Query provider list theo region trên DB demo; xác minh system provider và payment-session/completion semantics.
- Acceptance: provider có thể tạo session và complete cart trên DB demo; UI copy phân biệt “đặt hàng” với “đã thu tiền”.
- Verify: API smoke thực trên safe DB; kiểm tra payment/order state trong Admin.
- Dependencies: DEC-01, INT-01.
- Files: `apps/backend/medusa-config.ts` chỉ nếu cấu hình hiện tại thật sự thiếu; tài liệu evidence.
- Status: **Blocked on live DB** — source/docs xác nhận system provider ID `pp_system`; region config, session và completion vẫn chưa được xác minh runtime.

### FE-CHECKOUT-01 — Payment collection/session và review

- [x] Tải provider; chỉ dùng system/COD provider Medusa trả về; tạo collection/session và review cart mới nhất.
- Acceptance: không hard-code unavailable provider; loading/error/retry hoạt động; total lấy từ server.
- Verify: mock service/widget tests và provider smoke.
- Dependencies: FE-SHIP-02, BE-PAY-01.
- Files: `medusa_service.dart`, `payment_provider.dart`, checkout screen.
- Status: **Source implemented**; provider/session live gate vẫn blocked trên DB demo.

### FE-CHECKOUT-02 — Complete cart và xử lý double-submit

- [x] Gọi complete cart sau xác nhận cuối; xử lý `type=order` / `type=cart` và ngăn submit lặp.
- Acceptance: chỉ `type=order` điều hướng success; `type=cart`/error giữ checkout/cart; nút submit khóa khi pending; không tạo success giả.
- Verify: tests cho order, cart/error, timeout và duplicate tap.
- Dependencies: FE-CHECKOUT-01.
- Files: `medusa_service.dart`, checkout screen.
- Status: **Source implemented**; complete cart và double-submit chưa được test.

## 4. Đơn hàng

### FE-ORDER-01 — Order model và confirmation

- [x] Parse order trả về từ complete cart; hiển thị ID/number, line items, address, shipping và total.
- Acceptance: dùng object từ response Medusa; xóa cart ID local chỉ sau order success; copy không khẳng định payment đã capture.
- Verify: unit/widget tests cho success và missing/invalid order response.
- Dependencies: FE-CHECKOUT-02.
- Files: `customer_order.dart`, order success/detail screens, cart storage callsite.
- Status: **Source implemented**; success/API/Admin visibility chưa live verified.

### FE-ORDER-02 — Order history và detail

- [x] Thêm danh sách phân trang và chi tiết order từ dữ liệu đã nhận qua customer-authenticated history/complete response.
- Acceptance: list gọi Store API với token; detail UI không gọi route ID Medusa 2.21.1 mặc định không authenticated.
- Verify: mock endpoint tests; live ownership checks trên DB demo.
- Dependencies: FE-ORDER-01, DEC-01.
- Files: `medusa_service.dart`, order history/detail screens.
- Status: **Source implemented**; 401, pagination và ownership chưa được runtime kiểm tra.

## 5. Quality, runtime và tài liệu

### QA-01 — Error/failure matrix

- [ ] Bao phủ expired auth, no address, no shipping option, address change, stock/price change, provider failure, complete error và order history access.
- Acceptance: mỗi lỗi có recovery path; cart và address không bị mất ngoài ý muốn.
- Verify: focused service/widget cases; manual checklist.
- Dependencies: FE-ADDR-04 đến FE-ORDER-02.
- Files: các screen/service có lỗi còn thiếu, tests.
- Status: Recovery paths có trong source; failure matrix chưa được test.

### QA-02 — E2E trên database demo

- [ ] Chạy full flow từ variant đến order; xác nhận order trong Admin và history/detail.
- Acceptance: demo lặp lại được với data seed demo; không dựa vào mocks; ghi environment/test result.
- Verify: manual E2E checklist trong `DEMO_GUIDE.md`.
- Dependencies: INT-01, FE-ADDR-04, FE-SHIP-02, BE-PAY-01, FE-ORDER-02.
- Files: evidence/runbook; test fixture chỉ khi cần.
- Status: Pending live E2E — cần xác minh shipping/COD/order với customer demo và Admin; catalog API hiện hoạt động.

### DOC-01 — Roadmap status và tài liệu kiến trúc

- [x] Tạo spec/design/plan/todo và đồng bộ roadmap current evidence.
- Acceptance: không còn risk row mâu thuẫn với source; implementation/live gates phân biệt rõ.
- Verify: đối chiếu các status với source/run evidence.
- Dependencies: —
- Files: `MASTER_DEVELOPMENT_ROADMAP.md`, `tasks/*.md`.
- Status: **Updated** after feature implementation; provider/runtime/build gates remain open.

### DOC-02 — Hướng dẫn run/demo

- [x] Viết prereqs, local DB, safe seed, key/channel, backend/mobile commands, emulator URL, address/shipping/COD/order demo flow and blockers.
- Acceptance: người khác làm theo được; không có credential thật trong docs.
- Verify: walkthrough trên DB demo sau khi OPS-01/INT-01 mở.
- Dependencies: INT-01; phần khung guide có thể viết sớm.
- Files: `DEMO_GUIDE.md`, `apps/mobile/README.md` nếu cần link.
- Status: **Guide đã cập nhật theo runtime mới; checkout walkthrough vẫn pending live E2E**.

## Optional sau MVP

- [ ] Promotion UI, wishlist, recently viewed, price sort/range filtering.
- [ ] Online payment provider và carrier integration khi có credentials/specs.
- [ ] Guest checkout và guest order lookup nếu được yêu cầu.
