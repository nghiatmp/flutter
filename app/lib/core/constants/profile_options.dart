/// Danh sách lựa chọn dùng chung cho form đăng ký và form cập nhật hồ sơ,
/// tránh mỗi màn tự khai một danh sách riêng rồi lệch nhau.
class ProfileOptions {
  const ProfileOptions._();

  static const genders = ['Nam', 'Nữ', 'Khác'];
  static const hobbies = ['Đọc sách', 'Thể thao', 'Âm nhạc', 'Du lịch'];
  static const cities = ['Hà Nội', 'Đà Nẵng', 'TP. Hồ Chí Minh', 'Cần Thơ'];
}
