# UI/UX PRO MAX — Kế hoạch triển khai app bán điện thoại

## Mục tiêu

Áp dụng template **Flagship Tech Boutique** đã được duyệt cho toàn bộ Flutter app: làm sản phẩm nổi bật, giúp khách tìm và so sánh máy nhanh, tạo cảm giác tin cậy, đồng thời giữ luồng mua hàng rõ ràng từ catalog đến đơn hàng. Giữ Medusa là nguồn giá, tồn kho, giao hàng, thanh toán và đơn hàng. Không thêm đánh giá, giảm giá, bảo hành hoặc cam kết giao hàng nếu backend chưa cung cấp dữ liệu.

## Đường cơ sở đã xác nhận

- App chính là Flutter tại `apps/mobile`; `apps/storefront` chỉ là app tham khảo.
- Có 12 màn: catalog, chi tiết máy, giỏ, checkout, sổ/form địa chỉ, đăng nhập/đăng ký, tài khoản, thành công, danh sách và chi tiết đơn hàng.
- Giao diện đang lặp các màu và style trực tiếp trong màn hình; theme toàn app mới cấu hình màu seed và AppBar.
- Flutter/Dart local là 3.47.2/3.13.2; package Flutter hiện có, không cần thêm package UI/state.
- Baseline `flutter test`: 2 test lỗi vì expectation cũ không khớp UI/viewport hiện tại; 17 test qua. Baseline `flutter analyze` thoát do analysis server nhận JSON bị cắt khi chạy đồng thời với test, cần chạy lại tuần tự.
- `flutter devices` thấy Windows, Chrome và Edge; không thấy Android emulator. CI build Web release để kiểm tra/đóng gói artifact; build không inject URL/key, không triển khai public khi chưa có đích deploy được chọn.
- Code review trước đó phát hiện `attachCustomerAddressToCart` gửi `customer_id` đến endpoint cart update; cần sửa theo contract Medusa v2 và thêm mock service regression test.

## Hợp đồng thiết kế

### Ngôn ngữ hình ảnh

- Tên: **Flagship Tech Boutique** — cửa hàng công nghệ tinh gọn, hiện đại, cao cấp vừa phải.
- Nền lạnh sáng `#F5F7FA`, surface trắng; chữ chính `#111827`, phụ `#667085`, viền `#E4E7EC`; navy `#1E3A8A` dành cho hành động và điểm nhận diện; màu trạng thái theo ngữ nghĩa (success/warning/error). Giá dùng màu nhấn thống nhất, không tạo cảm giác khuyến mãi giả.
- Dùng type scale Material 3 theo cấp bậc, ưu tiên chữ mặc định của nền tảng; không kéo thêm font package.
- Spacing theo nhịp 4/8; trang mobile lề 16–20; card 12–16; nút cao tối thiểu 48; vùng chạm tối thiểu 48; bóng rất nhẹ hoặc không dùng.
- Ảnh máy dùng vùng hiển thị sạch, `BoxFit.contain`, placeholder/error state nhất quán.

### Quy tắc bố cục

- 4 tab gốc: **Khám phá · Giỏ hàng · Đơn hàng · Tài khoản**. Trang chi tiết và các bước checkout/địa chỉ/auth vẫn là route tập trung, dùng chung theme/components.
- Catalog: tìm kiếm và chọn hãng dễ thấy; lưới 2 cột trên điện thoại, tăng cột trên màn rộng; sản phẩm dùng dữ liệu thật.
- Chi tiết: ảnh lớn, hãng/tên/giá/tồn kho, tùy chọn phiên bản, thông số theo nhóm, CTA cố định phía dưới.
- Giỏ: dòng sản phẩm gọn, chỉnh số lượng/xóa, tổng server trả về và CTA checkout cố định.
- Checkout: thứ tự Địa chỉ → Giao hàng → COD → Sản phẩm/Tổng; hiện giá Medusa; khóa submit khi thiếu điều kiện hoặc đang gửi.
- Address, auth, profile, order history/detail/success dùng cùng header, form, card, trạng thái rỗng/lỗi/tải và nút.
- Mọi màn phải đọc được trên 320 px, không phụ thuộc riêng màu để truyền trạng thái, có nhãn cho icon-only action và giữ nội dung cuộn tới được khi bàn phím mở.

## Kế hoạch theo thứ tự phụ thuộc

### Phase 0 — Baseline và contract

- [x] Kiểm tra git state, app, màn hình, tests, SDK và CI hiện có; giữ nguyên các thay đổi đang có trong working tree.
- [x] Chạy độc lập `dart analyze`; xác nhận `flutter analyze` trên Windows lỗi ở JSON LSP đầu vào trước khi phân tích source.
- [x] Xác nhận payload attach customer/address theo Medusa v2.21.1 source/docs; không dùng DB hoặc secret.

### Phase 1 — Nền thiết kế dùng chung

- [x] Tạo semantic tokens và `ThemeData` tập trung cho màu, chữ, scaffold, AppBar, input, card, button, chip, dialog, navigation và snackbar.
- [x] Tạo component nhỏ dùng lại: page heading, section heading, surface card, primary action, empty/loading/error state; không tạo lớp cấu hình dư thừa.
- [x] Định nghĩa shell 4 tab, trạng thái tab và đồng bộ mã giỏ hàng; route chi tiết tiếp tục dùng Navigator hiện tại.
- Acceptance: không thêm dependency; style mới được theme điều khiển; thao tác tab không reset state; cart ID tạo trong product flow có thể mở được ở tab Giỏ hàng.
- Verify: format, analyzer; widget tests cho tab/chuyển trang/cart state.

### Phase 2 — Khám phá và chọn máy

- [x] Thiết kế lại catalog: header thương hiệu, tìm kiếm, filter hãng, trạng thái mạng/empty/loading và responsive product tile.
- [x] Thiết kế lại chi tiết: ảnh, giá/tồn kho thật, chọn option/variant, số lượng, specs và CTA.
- Acceptance: tìm kiếm/chọn hãng/add-to-cart giữ nguyên contract; không giả badge, rating, sale hay sản phẩm nổi bật.
- Verify: widget tests cho danh sách rỗng/lỗi, variant unavailable và thêm giỏ; Flutter Web build.

### Phase 3 — Giỏ, địa chỉ và checkout

- [x] Chuẩn hóa cart item, quantity/remove, summary và CTA.
- [x] Chuẩn hóa address book/form Việt Nam, validate field, empty/error state và thao tác chọn địa chỉ.
- [x] Chuẩn hóa checkout theo các bước; refresh shipping/tổng từ Medusa; COD chỉ hiện khi provider có thật.
- [x] Sửa customer attach endpoint và thêm service payload regression test.
- Acceptance: lỗi không làm mất form/cart; submit chỉ thành công khi Medusa trả order; không hiển thị thanh toán đã thu tiền khi chưa có xác nhận.
- Verify: widget/service tests; build/analyze; live E2E chỉ khi đã có DB demo và provider an toàn.

### Phase 4 — Tài khoản và hậu mua hàng

- [x] Chuẩn hóa profile và entry points tới địa chỉ/đơn hàng/đăng xuất.
- [x] Chuẩn hóa login/register và lỗi/validation/loading.
- [x] Chuẩn hóa order success/history/detail: trạng thái, mã, dòng sản phẩm, địa chỉ và tổng tiền.
- Acceptance: giữ auth behavior; màn hình đơn hàng dùng dữ liệu Medusa và text trạng thái chính xác.
- Verify: widget tests cho auth/errors, empty history, success/detail states.

### Phase 5 — CI, chất lượng và review

- [x] Thêm GitHub Actions cho Flutter: Flutter 3.47.2, `pub get`, format, `dart analyze`, `flutter test`, `flutter build web --release`; upload web artifact.
- [x] Chưa tạo deploy public/App Store release vì chưa có đích hosting, signing và credentials được chọn.
- [x] Chạy CI-equivalent commands tuần tự, sửa regressions, kiểm tra release build và giao diện Chrome ở 320 px/desktop.
- [x] Review diff theo correctness, UX/accessibility, security, maintainability và performance; sửa lỗi tìm thấy.
- Acceptance: pipeline xanh với source hiện tại; docs phản ánh giới hạn môi trường; không lộ credentials; không thêm generated output vào git.

## Nguyên tắc giữ code ngắn, sạch và nhanh

- Theme/component chia sẻ thay vì sao chép widget tree; component chỉ nhận dữ liệu/children cần thiết.
- Không thêm state management hoặc UI packages nếu Flutter core và state hiện tại đáp ứng.
- Không giữ widget làm việc nặng khi build; không tính lại format/model trong từng item; dùng builder/lazy list/grid cho catalog.
- Dùng ảnh thumbnail đã có, kích thước hiển thị giới hạn hợp lý và placeholder; không thêm asset nặng hoặc animation liên tục.
- Không refactor service/domain ngoài lỗi đã xác nhận; giữ logic nghiệp vụ trong service/backend hiện hữu.
- Chỉ tối ưu dựa trên đường code và kết quả kiểm tra; không thêm abstraction “phòng xa”.

## Rủi ro và giới hạn

| Rủi ro | Cách xử lý |
|---|---|
| Baseline có test lỗi trước thay đổi | Cập nhật expectation theo UI hiện tại, chờ cuộn hoàn tất trong test viewport; toàn bộ test hiện qua. |
| Không có Android emulator và backend demo an toàn | Dùng Flutter tests/analyze/Web build; ghi rõ E2E Medusa chưa được chứng minh. |
| CI build không đồng nghĩa triển khai ứng dụng | Upload artifact web; chờ lựa chọn hosting/signing trước deploy. |
| Dữ liệu catalog có thể thiếu ảnh/spec/giá | Component hiển thị placeholder và copy theo dữ liệu thật, không lấp bằng nội dung giả. |

## Definition of Done

- Cả 12 màn tuân thủ cùng theme, spacing, type scale, components và trạng thái tương tác.
- Bốn tab gốc hoạt động; catalog/detail/cart/checkout/account/orders không mất behavior hiện có.
- Địa chỉ attach đúng với Medusa; checkout không giả tạo đơn.
- `dart format`, `dart analyze`, `flutter test`, `flutter build web --release` thành công; lỗi wrapper `flutter analyze` trên Windows được ghi rõ.
- CI workflow xây và giữ artifact; không có deploy ngoài ý muốn.
- Code review cuối không còn finding Critical/High; finding còn lại được nêu trong kết quả.

## Trạng thái thực thi

- **Hoàn tất source/UI:** phases 0–5; theme dùng chung, 12 màn, shell 4 tab, regression tests và workflow CI đã được thêm.
- **Kiểm tra local:** `dart format` sạch, `dart analyze` sạch, Flutter tests và Web release build qua; smoke check ở 320 px và desktop.
- **Giới hạn còn lại:** `flutter analyze` wrapper lỗi parse JSON LSP trên Windows; `dart analyze` là lệnh analyzer trong CI. Backend/key/COD provider chưa hoạt động ở môi trường này nên checkout E2E chưa thể xác minh; GitHub workflow chưa chạy từ xa.
- **Review fix:** sau khi thêm sản phẩm, shell tăng cart revision để cart tab tải lại response mới, tránh hiển thị cart cũ/trống.
