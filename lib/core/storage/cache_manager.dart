import 'dart:collection';

/// 一个带 LRU 淘汰策略的简单内存缓存管理器
class CacheManager<T> {
  final int maxItems;
  final Map<String, _CacheEntry<T>> _cache;
  final LinkedList<_CacheEntry<T>> _lruList;

  /// 创建一个缓存管理器，并指定最大缓存项数量
  CacheManager({this.maxItems = 100})
    : _cache = {},
      _lruList = LinkedList<_CacheEntry<T>>();

  /// 在缓存中添加或更新一个项
  void setItem(String key, T value) {
    // 如果已存在则移除旧条目
    if (_cache.containsKey(key)) {
      final entry = _cache[key]!;
      entry.unlink();
      _cache.remove(key);
    }

    // 缓存已满时淘汰最近最少使用的项
    if (_cache.length >= maxItems && _lruList.isNotEmpty) {
      final leastUsed = _lruList.last;
      _cache.remove(leastUsed.key);
      leastUsed.unlink();
    }

    // 添加新条目
    final entry = _CacheEntry<T>(key, value);
    _cache[key] = entry;
    _lruList.addFirst(entry);
  }

  /// 从缓存中检索一个项
  T? getItem(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    // 移动到 LRU 列表前端
    entry.unlink();
    _lruList.addFirst(entry);

    return entry.value;
  }

  /// 检查缓存是否包含指定键的项
  bool containsKey(String key) => _cache.containsKey(key);

  /// 从缓存中移除一个项
  void removeItem(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      entry.unlink();
    }
  }

  /// 清空缓存中的所有项
  void clear() {
    _cache.clear();
    _lruList.clear();
  }

  /// 返回缓存中的项数量
  int get length => _cache.length;

  /// 返回缓存是否为空
  bool get isEmpty => _cache.isEmpty;

  /// 返回缓存是否不为空
  bool get isNotEmpty => _cache.isNotEmpty;

  /// 返回缓存中的所有键
  Iterable<String> get keys => _cache.keys;

  /// 返回缓存中的所有值，按最近使用优先排序
  Iterable<T> get values => _lruList.map((entry) => entry.value);
}

/// 支持链表操作的内部缓存条目
base class _CacheEntry<T> extends LinkedListEntry<_CacheEntry<T>> {
  final String key;
  final T value;

  _CacheEntry(this.key, this.value);
}
