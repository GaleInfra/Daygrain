import 'dart:collection';

/// create: 2023/5/17
/// desc: LRU算法的map
class LRUMap<K, V> {
  /// 限制数量
  final int capacity;

  /// 新保存
  final Function(K key, V value) onNewSave;

  final Map<K, V> data = LinkedHashMap<K, V>(
    equals: (p0, p1) {
      return p0 == p1;
    },
  );

  LRUMap({
    required this.capacity,
    required this.onNewSave,
  });

  void put(K key, V value) {
    if (data.containsKey(key)) {
      // 如果key已存在，则更新value并将其移到最前面
      data[key] = value;
      data.remove(key);
      data[key] = value;
    } else {
      // 如果key不存在，则添加新的entry到最前面
      data[key] = value;
      onNewSave.call(key, value);
      if (data.length > capacity) {
        // 如果超出容量限制，则删除最老的entry
        data.remove(data.keys.first);
      }
    }
  }

  V? get(K key) {
    if (data.containsKey(key)) {
      // 如果key存在，则将其移到最前面并返回对应的value
      final value = data.remove(key);
      data[key] = value as V;
      return value;
    }
    // 如果key不存在，则返回null
    return null;
  }

  void fromJson(Map<String, dynamic> json) {
    json.forEach((key, value) {
      put(key as K, value as V);
    });
  }

  @override
  String toString() => data.toString();
}
