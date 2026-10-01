class Customer {
  const Customer({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  String get fullName {
    final name = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    return name.isEmpty ? email : name;
  }

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    firstName: json['first_name']?.toString(),
    lastName: json['last_name']?.toString(),
    phone: json['phone']?.toString(),
  );
}
