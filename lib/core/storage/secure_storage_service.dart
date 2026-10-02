import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:init/core/error/exceptions.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService(this._secureStorage);

  // 默认构造函数
  factory SecureStorageService.create() {
    return SecureStorageService(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
    );
  }

  // 写入值
  Future<void> write({required String key, required String value}) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw CacheException(message: 'Failed to write secure data: $e');
    }
  }

  // 读取值
  Future<String?> read({required String key}) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw CacheException(message: 'Failed to read secure data: $e');
    }
  }

  // 删除值
  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw CacheException(message: 'Failed to delete secure data: $e');
    }
  }

  // 全部删除
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw CacheException(message: 'Failed to delete all secure data: $e');
    }
  }

  // 检查键是否存在
  Future<bool> containsKey({required String key}) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      throw CacheException(message: 'Failed to check secure key: $e');
    }
  }

  // 读取所有值
  Future<Map<String, String>> readAll() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      throw CacheException(message: 'Failed to read all secure data: $e');
    }
  }
}
