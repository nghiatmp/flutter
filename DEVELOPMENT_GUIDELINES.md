# Quy Ước Phát Triển Workspace

File này dùng để nhắc các nguyên tắc khi mở rộng workspace. Mỗi lần thêm màn hình, component, provider, service, API hoặc flow mới, hãy đọc nhanh checklist này trước khi code.

## Mục Tiêu

- Code dễ đọc, dễ học và dễ mở rộng.
- Tránh lặp UI giống nhau ở nhiều màn hình.
- Tránh hardcode text, route, key lưu trữ, màu sắc hoặc config quan trọng.
- Cập nhật tài liệu song song với code để project không bị lệch giữa mô tả và thực tế.

## Ưu Tiên Component Dùng Chung

Trước khi tạo UI mới, kiểm tra thư mục:

```txt
app/lib/shared/widgets/
```

Nếu app đã có widget dùng chung phù hợp thì ưu tiên dùng lại, ví dụ:

- `CustomTextField`
- `CustomButton`
- `CustomDropdownField`
- `CustomDateField`
- `CustomCheckboxField`
- `CustomRadioGroupField`
- `LoadingView`
- `EmptyView`
- `CustomAppBar`

Chỉ tạo widget mới khi:

- UI đó được dùng lại ở nhiều màn.
- Một màn hình đang quá dài và cần tách nhỏ để dễ đọc.
- Widget mới đại diện cho một phần giao diện có ý nghĩa rõ ràng, ví dụ `TaskItem`, `ProfileHeader`, `SettingTile`.

Vị trí đặt widget:

- Dùng chung toàn app: đặt trong `app/lib/shared/widgets/`.
- Chỉ dùng trong một feature: đặt trong `app/lib/features/<feature_name>/widgets/`.

## Tránh Hardcode

Không nên hardcode trực tiếp ở nhiều nơi các giá trị sau:

- Route path, ví dụ `/login`, `/management`, `/settings`.
- Storage key, ví dụ `user_data`, `tasks_data`.
- Tên app, text dùng lặp lại nhiều nơi.
- Màu sắc, khoảng cách, style dùng chung.
- API endpoint.
- Giá trị config như timeout, limit, default page size.

Nơi nên đặt:

- Hằng số chung: `app/lib/core/constants/`.
- Storage key: `app/lib/core/constants/storage_keys.dart`.
- Tên app hoặc config cấp app: `app/lib/core/constants/app_constants.dart`.
- API endpoint: `app/lib/core/network/api_endpoints.dart`.
- Theme, màu, style chung: `app/lib/app/theme.dart`.
- Route chung: ưu tiên gom tên/path route vào một nơi nếu số lượng màn hình tăng nhiều.

Nếu một giá trị chỉ dùng đúng một lần trong một màn hình và không mang tính cấu hình, có thể để trực tiếp tại màn hình đó.

## Khi Thêm Màn Hình Mới

Checklist:

- Đặt màn hình đúng feature trong `app/lib/features/<feature_name>/screens/`.
- Nếu là màn dùng chung hoặc shell chính của app, cân nhắc đặt trong feature phù hợp hoặc `app/lib/app/`.
- Thêm route vào router.
- Kiểm tra màn đó có cần AppBar title, nút back, loading state, empty state hoặc error state không.
- Nếu màn có form, dùng các widget form dùng chung trước khi tạo mới.
- Nếu màn có logic phức tạp, đưa logic sang provider/service thay vì để toàn bộ trong widget.

Sau khi code xong:

- Cập nhật `app/PROJECT_STRUCTURE.md` nếu có thêm thư mục, file, feature, screen, widget hoặc route mới trong Flutter app.
- Cập nhật `app/TECH_FLOW.md` nếu có thêm luồng điều hướng, luồng dữ liệu, provider, service, local storage hoặc API mới trong Flutter app.

## Khi Thêm Bottom Navigation Hoặc Shell

Nếu app có nhiều tab chính như Home, Tasks, Posts, Account:

- Tạo một màn shell chịu trách nhiệm giữ bottom navigation.
- Mỗi tab nên là một màn riêng.
- Màn đi sâu như detail, edit, settings con nên có title rõ ràng và nút back.
- Cân nhắc ẩn bottom navigation ở các màn đi sâu nếu cần cảm giác tập trung.

Khi thêm bottom navigation, nhớ cập nhật:

- `app/PROJECT_STRUCTURE.md`: danh sách screen, route và vai trò shell.
- `app/TECH_FLOW.md`: flow chuyển tab và flow đi sâu vào detail/edit/settings.

## Khi Thêm Provider, Service Hoặc Repository

Nguyên tắc tách trách nhiệm:

- Screen/widget: hiển thị UI và nhận thao tác người dùng.
- Provider/notifier: giữ state và điều phối logic.
- Service/repository: xử lý lưu trữ, API hoặc nghiệp vụ cụ thể.
- Model: mô tả dữ liệu.

Sau khi thêm logic mới, cập nhật `app/TECH_FLOW.md` hoặc `backend/TECH_FLOW.md` đúng theo project bị thay đổi để mô tả:

- Dữ liệu đi từ đâu tới đâu.
- Provider nào giữ state.
- Service/repository nào xử lý nghiệp vụ.
- Dữ liệu có lưu local storage hoặc gọi API không.

## Khi Thêm Model Hoặc Dữ Liệu Local

Checklist:

- Tạo model Flutter trong `app/lib/features/<feature_name>/models/`.
- Nếu lưu local storage, thêm key vào `StorageKeys`.
- Không viết key dạng string trực tiếp trong nhiều file.
- Có hàm parse/serialize rõ ràng nếu lưu JSON.

Cập nhật tài liệu:

- `app/PROJECT_STRUCTURE.md`: thêm model/storage key mới.
- `app/TECH_FLOW.md`: mô tả luồng lưu, đọc, cập nhật dữ liệu.

## Khi Thêm API Backend

Checklist:

- Đặt controller/service/module đúng domain trong `backend/src/<domain_name>/`.
- Type dùng chung của domain đặt trong file `*.types.ts`.
- Logic nghiệp vụ nằm trong service, controller chỉ nhận request và trả response.
- API cần đăng nhập phải dùng `AuthGuard`.
- Dữ liệu dùng chung hoặc lưu trữ phải đi qua `DatabaseService`, không đọc/ghi file trực tiếp ở controller.

Cập nhật tài liệu:

- `backend/PROJECT_STRUCTURE.md` nếu có thêm module, file hoặc domain mới.
- `backend/TECH_FLOW.md` nếu có thêm endpoint, auth flow, data flow hoặc cách lưu dữ liệu mới.

## Khi Code Xong Một Phần

Trước khi xem là hoàn thành:

- Chạy format.
- Chạy analyze.
- Kiểm tra lại có hardcode không cần thiết không.
- Kiểm tra có component nào nên tách ra dùng chung không.
- Cập nhật đúng file `PROJECT_STRUCTURE.md` của `app/` hoặc `backend/` nếu cấu trúc project thay đổi.
- Cập nhật đúng file `TECH_FLOW.md` của `app/` hoặc `backend/` nếu luồng kỹ thuật thay đổi.

## Quy Tắc Ngắn Gọn

```txt
UI lặp lại        -> tách component
Giá trị dùng lại  -> đưa vào constants/config
Luồng mới         -> cập nhật TECH_FLOW.md đúng project
File/thư mục mới  -> cập nhật PROJECT_STRUCTURE.md đúng project
Logic phức tạp    -> đưa vào provider/service/repository
```
