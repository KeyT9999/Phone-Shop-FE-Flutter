# DTC Phone Store — Flutter app

Flutter là ứng dụng khách hàng chính; Medusa Store API là nguồn dữ liệu sản phẩm, giá, tồn kho, giỏ hàng, phí giao hàng và đơn hàng.

Xem [hướng dẫn chạy và chuẩn bị demo](../../DEMO_GUIDE.md), [roadmap](../../MASTER_DEVELOPMENT_ROADMAP.md) và [checklist checkout](../../tasks/todo.md) để biết phần nào đã chạy được và phần nào còn thiếu.

## Chạy ứng dụng

Truyền publishable API key của Medusa bằng compile-time define. Không ghi key hoặc URL môi trường vào source control:

```powershell
flutter run --dart-define=MEDUSA_PUBLISHABLE_KEY=pk_your_key
```

`MEDUSA_BASE_URL` không bắt buộc khi dùng môi trường local:

- Android Emulator mặc định dùng `http://10.0.2.2:9000`.
- Web, Windows, macOS, Linux và iOS Simulator mặc định dùng `http://localhost:9000`.
- Với điện thoại thật hoặc backend từ máy khác, truyền URL mà thiết bị có thể truy cập:

```powershell
flutter run --dart-define=MEDUSA_BASE_URL=https://medusa.example.com --dart-define=MEDUSA_PUBLISHABLE_KEY=pk_your_key
```

Ứng dụng chọn region có currency `VND` và Việt Nam, rồi truyền `region_id` khi tải giá sản phẩm. Nếu backend chưa cấu hình region đó hoặc key không truy cập được Store API, màn hình catalog sẽ hiện lỗi và nút thử lại.

## Checkout và đơn hàng demo

- Checkout yêu cầu khách hàng đăng nhập. Sổ địa chỉ dùng Store API customer addresses; form nhận số `0` + 9 chữ số hoặc `+84` + 9 chữ số và chuẩn hóa thành `+84`.
- Tỉnh/thành, quận/huyện và phường/xã nhập bằng text. Khi chọn địa chỉ, app gửi riêng customer/email và bản sao shipping/billing address vào cart.
- Phương thức giao hàng và giá calculated lấy từ Medusa; sau khi thêm shipping method, app tải cart mới để hiển thị tổng server.
- COD chỉ khả dụng khi Medusa trả system provider (`pp_system` hoặc `pp_system_*`) cho region. Chỉ response `type=order` mới hiện xác nhận và xóa cart ID local.
- Lịch sử đơn gọi Store API với customer token. Màn detail dùng order đã nhận từ history/complete response vì Medusa 2.21.1 có route detail-by-ID mặc định không yêu cầu customer auth.

Source đã có các màn này nhưng chưa live verified: backend trước đó timeout với PostgreSQL, publishable key chưa được truyền và system provider/order flow chưa thử trên DB demo. Xem [DEMO_GUIDE.md](../../DEMO_GUIDE.md) trước khi demo.

## CI và bản build demo

Workflow [mobile-ci.yml](../../.github/workflows/mobile-ci.yml) chạy khi có thay đổi trong app mobile, trên pull request hoặc khi chạy thủ công. Pipeline dùng Flutter 3.47.2, kiểm tra format/analyze, chạy test, build Web release và lưu artifact `mobile-web-build` trong 14 ngày. Artifact CI không đóng gói URL/key; để demo backend thật, build lại với compile-time defines như lệnh ở trên.

Pipeline chưa tự deploy website công khai hoặc phát hành Android/iOS. Các đích đó cần chọn hosting/store và cấu hình thông tin ký ứng dụng cho bản native.

## Catalog

- Từ khóa và brand dùng `POST /store/search`; danh sách và chi tiết sản phẩm được đọc lại từ Store API để lấy options, giá đã tính và tồn kho theo sales channel.
- Detail lấy giá từ `calculated_price`, tồn kho từ `+variants.inventory_quantity`, và ghép lựa chọn theo ID option Medusa.
- Ảnh không có trong dữ liệu backend sẽ dùng biểu tượng điện thoại thay thế.
