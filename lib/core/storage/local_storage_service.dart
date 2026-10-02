import 'dart:convert';

import 'package:init/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // 保存字符串数据
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  // 获取字符串数据
  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve data: $e');
    }
  }

  // 保存布尔数据
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  // 获取布尔数据
  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve data: $e');
    }
  }

  // 保存整型数据
  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs.setInt(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  // 获取整型数据
  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve data: $e');
    }
  }

  // 保存浮点数据
  Future<bool> setDouble(String key, double value) async {
    try {
      return await _prefs.setDouble(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  // 获取浮点数据
  double? getDouble(String key) {
    try {
      return _prefs.getDouble(key);
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve data: $e');
    }
  }

  // 保存字符串列表数据
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _prefs.setStringList(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  // 获取字符串列表数据
  List<String>? getStringList(String key) {
    try {
      return _prefs.getStringList(key);
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve data: $e');
    }
  }

  // 保存对象数据（转换为 JSON 字符串）
  Future<bool> setObject(String key, Object value) async {
    try {
      final String jsonString = json.encode(value);
      return await _prefs.setString(key, jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: $e');
    }
  }

  // 获取对象数据（从 JSON 字符串转换）
  dynamic getObject(String key) {
    try {
      final String? jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      return json.decode(jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve data: $e');
    }
  }

  // 检查键是否存在
  bool hasKey(String key) {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      throw CacheException(message: 'Failed to check key: $e');
    }
  }

  // 按键移除数据
  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      throw CacheException(message: 'Failed to remove data: $e');
    }
  }

  // 清空所有数据
  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear data: $e');
    }
  }
}
