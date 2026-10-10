# Đặc tả — Checkout địa chỉ, giao hàng và đơn hàng

**Trạng thái:** source Flutter đã triển khai; 24 tests, analyzer, Web build và catalog API đã xác minh; shipping/COD/order E2E còn pending.
**Ngày:** 2026-10-10
**Phạm vi sản phẩm:** Flutter là app khách hàng chính; Medusa v2 là nguồn dữ liệu và trạng thái thương mại.

## Mục tiêu

Hoàn thiện luồng demo có thể lặp lại:

`Catalog → Product/Variant → Cart → Địa chỉ → Giao hàng → COD/manual payment → Complete cart → Order confirmation → Order history/detail`

Chỉ xác nhận đặt hàng khi Medusa trả về `order` sau khi complete cart. Cart local, payment session, snackbar hay phản hồi giả không được coi là đơn hàng.

## Người dùng và hành vi

- Khách hàng có thể nhập, lưu, xem, sửa, xóa và chọn địa chỉ nhận hàng Việt Nam.
- Địa chỉ đã chọn được ghi vào cart Medusa; địa chỉ khách hàng và cart address là hai tài nguyên khác nhau.
- Khách hàng xem các phương thức giao hàng khả dụng cho cart đã có địa chỉ, chọn một phương thức và thấy tổng tiền do Medusa trả về.
- Khách hàng xem lại đơn, đặt hàng theo phương thức demo đã chọn, rồi xem order được Medusa trả về.
- Khách hàng đã đăng nhập có thể xem lịch sử và chi tiết các order của chính mình.
- Loading, empty, validation, auth, network, stock, shipping, payment và order errors đều có thông báo và đường thử lại phù hợp.

## Tech stack và cấu trúc hiện tại

- Medusa v2.21.1, TypeScript, PostgreSQL, pnpm@10.11.1, Turborepo.
- Flutter/Dart (`apps/mobile`), `http`, `intl`, `shared_preferences`, `flutter_secure_storage`; không thêm dependency nếu Flutter SDK hiện có đáp ứng.
- API client hiện ở `apps/mobile/lib/services/medusa_service.dart`; models ở `lib/models`; screens dùng Navigator và state cục bộ.
- Medusa native Customer, Cart, Fulfillment, Payment và Order modules là nguồn sự thật; không tạo module/bảng riêng cho address, cart hoặc order.
- Source hiện có `customer_address.dart`, `shipping_option.dart`, `payment_provider.dart`, `customer_order.dart` và các màn address/checkout/order.

## Lệnh dự kiến

```powershell
# Từ repo root: Medusa backend
pnpm run backend:dev

# Chỉ chạy seed trên database phát triển dùng riêng, đã xác minh
pnpm run backend:seed

# Từ apps/mobile: cài dependency và chạy trên Android emulator
flutter pub get
flutter run -d emulator-5554 --dart-define=MEDUSA_PUBLISHABLE_KEY=<publishable-key>

# Flutter checks (chưa chạy trong lượt implementation này)
flutter test
dart analyze lib test

# Backend unit verification (không cần chạy seed)
cd ../backend
pnpm run test:unit
```

Repo yêu cầu dùng package manager được khai báo ở root và không tạo lockfile thứ hai. Integration checks cần PostgreSQL an toàn; không chạy seed/migration/reset lên database chưa xác minh.

## Code style

- No semicolons, double quotes, 2 spaces, kebab-case filenames, camelCase members.
- Backend route theo file-based routing; nghiệp vụ backend thuộc workflow nếu thật sự cần custom behavior.
- Flutter validation/API payload mapping nằm ngoài widget khi có thể tái sử dụng.

Model hiện tại xuất payload qua `CustomerAddress.toMedusaJson()` và `toCartAddressJson()`:

```dart
final customerAddressPayload = address.toMedusaJson();
final cartAddressPayload = address.toCartAddressJson();
```

## Kiểm thử dự kiến

- Unit tests cho địa chỉ/điện thoại/địa phương và mapping DTO.
- Mock HTTP service tests cho customer-address CRUD, cart address update, shipping options/method, payment collection/session, complete cart response và customer order access.
- Widget tests cho validation, loading/empty/error/retry, shipping selection, double-submit prevention, order success chỉ khi có order.
- Disposable-DB integration/manual E2E: chọn variant có stock → cart → address → shipping → COD/manual provider → order trong Medusa Admin → history/detail.
- Ghi đúng kết quả thực chạy; mocks không được báo cáo như bằng chứng live API.

## Quyết định cho MVP demo

1. Checkout yêu cầu đăng nhập; guest checkout chưa nằm trong MVP.
2. Phương thức demo là COD/system provider. App chỉ dùng provider có ID thuộc `pp_system` trả về cho region; không tuyên bố đã thu tiền. Provider/session/complete vẫn cần xác minh trên DB demo Medusa 2.21.1.
3. Địa chỉ dùng native Customer Address; cart nhận một bản shipping/billing address từ lựa chọn đã lưu. Billing mặc định giống shipping.
4. Form địa chỉ có họ/tên người nhận, số điện thoại, tỉnh/thành, quận/huyện, phường/xã và địa chỉ chi tiết. MVP dùng text input cho địa phương. Số Việt Nam nhận `0` + 9 chữ số hoặc `+84` + 9 chữ số và lưu ở dạng `+84`.
5. Standard/Express lấy giá từ shipping options backend. Giá 30.000/50.000 VND hiện tại là demo, chưa phải giá carrier.

## Ranh giới

- **Luôn làm:** validate đầu vào; gửi giá/tồn kho từ Medusa làm nguồn đúng; xóa cart ID local chỉ sau khi order được xác nhận; không ghi PII/key vào log hoặc repo.
- **Còn cần thống nhất trước demo:** nguồn dữ liệu địa phương nếu đổi text input thành dropdown; mức phí demo sẽ trình bày.
- **Không làm trong scope:** tạo module/bảng commerce riêng; seed/migrate/drop DB người dùng; giả lập order thành công; thêm carrier/payment tích hợp thật khi chưa có thông tin tài khoản.

## Tiêu chí hoàn thành

- Người dùng đã đăng nhập lưu/chọn địa chỉ VN hợp lệ; Medusa customer address và cart address cùng phản ánh lựa chọn.
- Shipping options tải theo cart có địa chỉ; chọn phương thức cập nhật cart và server total.
- COD/manual provider được backend cung cấp và khởi tạo đúng; complete cart trả `order` mới hiển thị success.
- Order hiện trong Medusa Admin; khách đăng nhập xem được history/detail của mình.
- Có automated checks cho validation, payloads và UI states; E2E chạy trên môi trường database demo riêng.
- Hướng dẫn chạy/demo tái lập được, không dựa vào key hoặc URL máy cá nhân đã commit.

## Câu hỏi đang mở

- Quy tắc chuẩn hóa/hiển thị số điện thoại và cách lưu trong Medusa.
- Có cần chọn địa phương từ danh sách thay cho text input MVP hay không; nếu có, chọn nguồn cụ thể.
- Phí Standard/Express demo có giữ nguyên 30.000/50.000 VND hay thay bằng mức khác?
