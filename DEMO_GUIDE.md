# Hướng dẫn chạy và chuẩn bị demo Phone Store

Tài liệu này ghi cách chạy local và chuẩn bị demo Flutter + Medusa. Source có form/sổ địa chỉ Việt Nam, chọn shipping, COD checkout và màn hình đơn hàng. Catalog đã được seed và xác minh trên Supabase do chủ dự án cung cấp; luồng đặt đơn end-to-end vẫn chưa được live verify.

## Trạng thái lần chạy gần nhất

Ngày 2026-10-10:

- Backend kết nối được database cấu hình cho dự án; health/Admin phản hồi và Store API trả catalog.
- Seed hoàn tất: region Vietnam/VND, 20 điện thoại trong 4 thương hiệu, 137 variants có inventory; API còn thấy 4 sản phẩm cũ ngoài catalog điện thoại.
- App tải 20 điện thoại; lọc Apple còn 5 mẫu; tìm “iPhone” trả 5 kết quả.
- Flutter suite: 24 tests pass; dart format sạch, dart analyze sạch; Flutter Web release build pass.
- Chưa xác minh live shipping calculation, COD provider/session, complete cart, hay khả năng xem order trong Admin/history. Seed chạy một lần; an toàn khi chạy lại chưa xác minh.
- GitHub Actions mobile workflow đã được thêm; workflow sẽ chạy khi push/PR hoặc dispatch và chưa có kết quả từ GitHub.

Các ghi chú bên dưới về timeout DB, thiếu key và APK build thuộc những lần thử trước; catalog/API hiện đã hoạt động. Không commit file cache hoặc key.
## Yêu cầu

- Windows PowerShell hoặc terminal tương đương.
- Node.js theo `package.json` (20.19+ hoặc 22.12+), pnpm 10.11.1.
- PostgreSQL 15+ database **dành riêng cho demo**, Flutter SDK phù hợp `apps/mobile/pubspec.yaml`, Android Emulator.
- Publishable API key được tạo trong Medusa Admin và gắn sales channel có catalog demo.

## Chuẩn bị backend local

1. Cài dependencies tại repo root nếu chưa có:

   ```powershell
   pnpm install
   ```

2. Tạo cấu hình local từ template và sửa trong máy. Không commit `.env` và không dán credential vào log/tài liệu:

   ```powershell
   Copy-Item apps/backend/.env.template apps/backend/.env
   ```

3. Trước khi chạy lệnh DB, kiểm tra riêng `DATABASE_URL` local đang trỏ tới database mới, disposable, không chứa dữ liệu người dùng. Tạo database nếu chưa tồn tại. Không chạy seed hoặc migration khi target chưa xác minh.

4. Khi target đã xác minh, chạy migration trong backend:

   ```powershell
   Set-Location apps/backend
   pnpm exec medusa db:migrate
   Set-Location ../..
   ```

5. Khởi động backend từ root:

   ```powershell
   pnpm run backend:dev
   ```

   Để backend chạy trong terminal này. Xác nhận startup hoàn tất và Admin mở tại `http://localhost:9000/app`. Nếu kết nối PostgreSQL timeout, dừng tại đây và sửa cấu hình kết nối trước khi chạy seed.

6. Mở terminal thứ hai tại repo root. Chỉ trên database demo riêng đã xác minh, chạy phone catalog seed:

   ```powershell
   pnpm run backend:seed
   ```

   Kiểm tra trong Admin: region Vietnam/VND, sales channel, publishable key, phone products/variants/inventory, và shipping options. Kiểm tra seed rerun safety trước khi dùng lại cùng database.

7. Tạo/lấy publishable key trong Admin, mục Settings → Publishable API keys; bảo đảm key có sales channel của catalog demo. Chỉ truyền key vào process Flutter, không đưa vào Git.

## Chạy app Flutter

Chạy lệnh từ `apps/mobile`. Android Emulator truy cập máy host qua `10.0.2.2`; trên thiết bị thật, dùng IP LAN có thể truy cập từ điện thoại và cấu hình backend cho kết nối đó.

```powershell
Set-Location apps/mobile
flutter devices
flutter run -d emulator-5554 --dart-define=MEDUSA_BASE_URL=http://10.0.2.2:9000 --dart-define=MEDUSA_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Thay `YOUR_PUBLISHABLE_KEY` bằng key lấy từ Admin. Các mặc định URL khác: Web/desktop/iOS Simulator dùng `http://localhost:9000`. Nếu chọn thiết bị khác, dùng device ID từ `flutter devices`.

## Luồng demo sau khi backend sẵn sàng

1. Tạo sẵn một customer demo và xác minh login trên backend local.
2. Chọn một điện thoại có variant và tồn kho; thêm vào cart, xác minh subtotal từ Medusa.
3. Tạo/chọn địa chỉ VN gồm người nhận, số điện thoại, tỉnh/thành, phường/xã và địa chỉ chi tiết.
4. Chọn shipping option do Medusa trả về; xác minh shipping và total sau khi cart được tải lại.
5. Kiểm tra màn review dùng giá, phí ship và total mới nhất từ server.
6. Chọn “Thanh toán khi nhận hàng (COD)”. App chỉ cho đi tiếp nếu endpoint payment providers trả về system provider cho region; copy không nói đã thanh toán.
7. Đặt đơn một lần; chỉ hiện confirmation khi complete cart trả `type=order`.
8. Xác nhận cùng order xuất hiện trong Medusa Admin, màn lịch sử và chi tiết đơn hàng. Màn detail dùng snapshot từ list đã xác thực hoặc response complete; app không gọi route detail-by-ID mặc định không có customer auth trong Medusa 2.21.1.

## Gate trước buổi demo

- Backend chạy ổn định, database là target demo đã xác nhận; không có timeout.
- Key dùng trên thiết bị đúng sales channel; catalog trả về region VND và sản phẩm/variant mong muốn.
- Seed và inventory được xác nhận; giá và shipping rate được gắn nhãn demo nếu chưa phải giá thực.
- System provider `pp_system` đã được trả về và kiểm chứng trên đúng Medusa 2.21.1, region và database này.
- Test order trên môi trường demo; order status/payment status và hiển thị trong Admin đã được kiểm tra.
- Không có `.env`, key, mật khẩu hoặc dữ liệu khách hàng thật trong bản trình chiếu/log.

## Phạm vi còn thiếu

Theo [`tasks/todo.md`](tasks/todo.md), source address, shipping, checkout và order đã triển khai; automated checks và live E2E còn thiếu. Xem [`tasks/design.md`](tasks/design.md) cho contract; xem [`MASTER_DEVELOPMENT_ROADMAP.md`](MASTER_DEVELOPMENT_ROADMAP.md) cho tiến độ và blockers.
