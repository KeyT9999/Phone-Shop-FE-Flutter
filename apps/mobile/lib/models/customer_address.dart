class CustomerAddress {
  const CustomerAddress({
    this.id,
    this.addressName = '',
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.addressLine,
    this.postalCode = '',
    this.isDefaultShipping = false,
    this.isDefaultBilling = false,
  });

  final String? id;
  final String addressName;
  final String firstName;
  final String lastName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String addressLine;
  final String postalCode;
  final bool isDefaultShipping;
  final bool isDefaultBilling;

  String get fullName => [
    firstName,
    lastName,
  ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');

  String get localityLine => [
    ward,
    district,
  ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(', ');

  String get formattedAddress => [
    addressLine,
    localityLine,
    province,
  ].where((value) => value.trim().isNotEmpty).join(', ');

  Map<String, String> validate() {
    final errors = <String, String>{};
    if (firstName.trim().isEmpty) errors['firstName'] = 'Nhập tên người nhận.';
    if (lastName.trim().isEmpty) errors['lastName'] = 'Nhập họ người nhận.';
    if (firstName.trim().length > 100) {
      errors['firstName'] = 'Tên người nhận tối đa 100 ký tự.';
    }
    if (lastName.trim().length > 100) {
      errors['lastName'] = 'Họ người nhận tối đa 100 ký tự.';
    }
    if (!isValidVietnamPhone(phone)) {
      errors['phone'] = 'Nhập số điện thoại Việt Nam hợp lệ.';
    }
    if (province.trim().isEmpty) errors['province'] = 'Nhập tỉnh/thành phố.';
    if (district.trim().isEmpty) errors['district'] = 'Nhập quận/huyện.';
    if (ward.trim().isEmpty) errors['ward'] = 'Nhập phường/xã.';
    if (addressLine.trim().isEmpty) {
      errors['addressLine'] = 'Nhập số nhà và tên đường.';
    }
    if (addressLine.trim().length > 255) {
      errors['addressLine'] = 'Địa chỉ chi tiết tối đa 255 ký tự.';
    }
    for (final field in ['province', 'district', 'ward']) {
      final value = switch (field) {
        'province' => province,
        'district' => district,
        _ => ward,
      };
      if (value.trim().length > 100) {
        errors[field] = 'Thông tin địa phương tối đa 100 ký tự.';
      }
    }
    if (phone.trim().length > 20) {
      errors['phone'] = 'Số điện thoại tối đa 20 ký tự.';
    }
    final postal = postalCode.trim();
    if (postal.isNotEmpty && !RegExp(r'^\d{5,6}$').hasMatch(postal)) {
      errors['postalCode'] = 'Mã bưu chính gồm 5 hoặc 6 chữ số.';
    }
    return errors;
  }

  bool get isValid => validate().isEmpty;

  String get normalizedPhone {
    final compact = phone.replaceAll(RegExp(r'[\s().-]'), '');
    if (compact.startsWith('+84')) return compact;
    if (compact.startsWith('84')) return '+$compact';
    if (compact.startsWith('0')) return '+84${compact.substring(1)}';
    return compact;
  }

  Map<String, dynamic> toMedusaJson() {
    final normalizedProvince = province.trim();
    final normalizedDistrict = district.trim();
    final normalizedWard = ward.trim();
    return {
      if (addressName.trim().isNotEmpty) 'address_name': addressName.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'phone': normalizedPhone,
      'address_1': addressLine.trim(),
      'address_2': [
        normalizedWard,
        normalizedDistrict,
      ].where((value) => value.isNotEmpty).join(', '),
      'city': normalizedProvince,
      'province': normalizedProvince,
      'postal_code': postalCode.trim(),
      'country_code': 'vn',
      'is_default_shipping': isDefaultShipping,
      'is_default_billing': isDefaultBilling,
      'metadata': {
        'vn_province': normalizedProvince,
        'vn_district': normalizedDistrict,
        'vn_ward': normalizedWard,
      },
    };
  }

  Map<String, dynamic> toCartAddressJson() {
    final json = toMedusaJson();
    json.remove('address_name');
    json.remove('is_default_shipping');
    json.remove('is_default_billing');
    return json;
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};
    final address2 = json['address_2']?.toString() ?? '';
    final fallbackParts = address2
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return CustomerAddress(
      id: json['id']?.toString(),
      addressName: json['address_name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      province: _string(
        metadata['vn_province'],
        json['city'] ?? json['province'],
      ),
      district: _string(
        metadata['vn_district'],
        fallbackParts.length > 1 ? fallbackParts[1] : '',
      ),
      ward: _string(metadata['vn_ward'], fallbackParts.firstOrNull ?? ''),
      addressLine: json['address_1']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      isDefaultShipping: json['is_default_shipping'] == true,
      isDefaultBilling: json['is_default_billing'] == true,
    );
  }

  static String _string(Object? preferred, Object? fallback) {
    final value = preferred?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return fallback?.toString() ?? '';
  }

  static bool isValidVietnamPhone(String value) {
    final compact = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
    return RegExp(r'^(?:0\d{9}|\+84\d{9}|84\d{9})$').hasMatch(compact);
  }
}
