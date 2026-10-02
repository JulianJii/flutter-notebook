import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profilePicture,
        phone,
        createdAt,
        updatedAt,
      ];

  // 工厂构造函数：创建一个空用户
  factory UserEntity.empty() {
    return const UserEntity(
      id: '',
      name: '',
      email: '',
    );
  }

  // copyWith 方法：以部分更新的属性创建新实例
  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicture,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 判断用户是否为空的方法
  bool get isEmpty => id.isEmpty && name.isEmpty && email.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
