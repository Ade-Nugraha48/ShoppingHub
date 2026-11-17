// ==============================================================================
// FILE: lib/models/user_model.dart
// PANDUAN: Model User untuk sistem autentikasi (Register, Login, & Profil).
// Disimpan langsung ke dalam Hive Box 'usersBox' dalam bentuk Map/JSON
// sehingga TIDAK MEMERLUKAN TypeAdapter atau build_runner saat ujian.
// ==============================================================================

class UserModel {
  // ---------------------------------------------------------------------------
  // 1. ATRIBUT MODEL USER
  // ---------------------------------------------------------------------------
  final String username;      // Key unik user di dalam Hive Box
  final String password;      // Password akun user
  final String fullName;      // Nama lengkap user untuk profil
  final String email;         // Email user (opsional)
  final String profileImage;  // [BARU] Path file lokal atau URL foto profil
  final DateTime createdAt;   // Tanggal & waktu registrasi

  // ---------------------------------------------------------------------------
  // 2. CONSTRUCTOR
  // ---------------------------------------------------------------------------
  UserModel({
    required this.username,
    required this.password,
    required this.fullName,
    this.email = '',
    this.profileImage = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // 3. FACTORY FROMJSON
  // Mengubah Map/JSON menjadi objek UserModel.
  // ---------------------------------------------------------------------------
  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return UserModel(
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FACTORY FROMMAP (UNTUK HIVE)
  // Hive mengembalikan Map<dynamic, dynamic>, method ini mengonversinya dengan aman.
  // ---------------------------------------------------------------------------
  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel.fromJson(
      Map<String, dynamic>.from(
        map.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. METHOD TOJSON / TOMAP
  // Mengubah objek UserModel menjadi Map<String, dynamic> agar siap
  // dimasukkan langsung ke Hive Box: `usersBox.put(username, user.toJson())`.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  // ---------------------------------------------------------------------------
  // 6. COPYWITH (UNTUK FITUR EDIT PROFIL / GANTI PASSWORD / FOTO PROFIL)
  // ---------------------------------------------------------------------------
  UserModel copyWith({
    String? username,
    String? password,
    String? fullName,
    String? email,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserModel(
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;

  @override
  String toString() => 'UserModel(username: $username, fullName: $fullName)';
}

