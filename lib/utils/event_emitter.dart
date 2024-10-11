class EventEmitter<T> {
  final List<void Function(T?)> _listeners = [];

  // イベントリスナーを追加するメソッド
  void addListener(void Function(T?) listener) {
    _listeners.add(listener);
  }

  // イベントリスナーを削除するメソッド
  void removeListener(void Function(T?) listener) {
    _listeners.remove(listener);
  }

  void removeAllListeners() {
    _listeners.clear();
  }

  // イベントを発行するメソッド
  void emit([T? event]) {
    for (var listener in _listeners) {
      listener(event);
    }
  }
}

