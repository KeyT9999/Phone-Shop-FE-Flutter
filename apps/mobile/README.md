# DTC Phone Store — Flutter app

Flutter là ứng dụng khách hàng chính; Medusa Store API là nguồn dữ liệu sản phẩm, giá, tồn kho và giỏ hàng.

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

## Catalog

- Từ khóa và brand dùng `POST /store/search`; danh sách và chi tiết sản phẩm được đọc lại từ Store API để lấy options, giá đã tính và tồn kho theo sales channel.
- Detail lấy giá từ `calculated_price`, tồn kho từ `+variants.inventory_quantity`, và ghép lựa chọn theo ID option Medusa.
- Ảnh không có trong dữ liệu backend sẽ dùng biểu tượng điện thoại thay thế.
