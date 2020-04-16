import 'dart:typed_data';

class ValueHandler {
  int _received = 0;
  int get received => _received;
  int _enqueued = 0;
  int get enqueued => _enqueued;
  DateTime _receivedTime = DateTime.now();
  DateTime get receivedTime => _receivedTime;
  DateTime _enqueuedTime = DateTime.now();
  DateTime get enqueuedTime => _enqueuedTime;

  bool _valueEncoded = true;
  bool get newValueAvailable => !_valueEncoded;

  ValueHandler();

  bool enqueue(int value) {
    _enqueuedTime = DateTime.now();
    if (_enqueued != value) {
      _enqueued = value;
      _valueEncoded = false;
      return true;
    }
    return false;
  }

  Uint8List encode() {
    _valueEncoded = true;
    return Uint8List(4)..buffer.asByteData().setInt32(0, _enqueued, Endian.big);
  }

  bool decode(Uint8List data) {
    if (data.length < 4) {
      return false;
    }
    var blob = ByteData.sublistView(data, 0, 4);
    var rcvd = blob.getInt32(0, Endian.big);
    _receivedTime = DateTime.now();
    if (rcvd != _received) {
      _received = rcvd;
      return true;
    }
    return false;
  }
}

class ValueUpdate {
  final int key;
  final int value;
  ValueUpdate(this.key, this.value);
}

class DataHandler {
  static const valueSz = 5;

  Uint8List _buffer = Uint8List(0);
  Map<int, ValueHandler> _values = {};
  int value(int key) {
    if (!registered(key)) {
      return 0;
    }
    return _values[key].received;
  }

  bool _newEnqueued = false;
  bool get enqueued => _newEnqueued;
  bool _dataReady = false;
  bool get dataReady => _dataReady;

  bool resetDataReady() {
    var dr = _dataReady;
    _dataReady = false;
    return dr;
  }

  final bool newOnly;

  DataHandler({this.newOnly = true});

  DateTime valueTimestamp(int key) {
    if (!registered(key)) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return _values[key].receivedTime;
  }

  bool enqueue(int key, int value) {
    if (!registered(key)) {
      return false;
    }
    var changed = _values[key].enqueue(value);
    _newEnqueued |= changed;
    return changed;
  }

  DateTime enqueuedTimestamp(int key) {
    if (!registered(key)) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return _values[key].enqueuedTime;
  }

  bool update(Uint8List received) {
    _buffer = append(_buffer, received);
    var changed = _decode();
    _dataReady |= changed;
    return changed;
  }

  bool _decode() {
    var newData = false;
    var i = 0, next = valueSz, len = _buffer.length;
    for (; next <= len; i = next, next += valueSz) {
      var key = _buffer[i];
      // skip unknown values
      if (!registered(key)) {
        continue;
      }
      var isNewVal = _values[key].decode(_buffer.sublist(i + 1, next));
      newData |= isNewVal;
    }
    _buffer = _buffer.sublist(i);
    return newData;
  }

  bool hasValuesNewerThan(DateTime t) {
    for (var v in _values.values) {
      if (v.receivedTime.isAfter(t)) {
        return true;
      }
    }
    return false;
  }

  Uint8List serialize({bool all = false}) {
    return _encode(
        _values.entries.where((v) => all || v.value.newValueAvailable));
  }

  Uint8List encodeNew() {
    if (!_newEnqueued) {
      return null;
    }
    if (newOnly) {
      _newEnqueued = false;
    }
    return serialize();
  }

  Uint8List _encode(Iterable<MapEntry<int, ValueHandler>> values) {
    var n = values.length;
    var buf = Uint8List(n * valueSz);
    var i = 0;
    for (var v in values) {
      buf[i] = v.key;
      buf.setAll(i + 1, v.value.encode());
      i += valueSz;
    }
    return buf;
  }

  bool register(int key) {
    if (registered(key)) {
      return false;
    }
    var v = ValueHandler();
    _values[key] = v;
    _newEnqueued = true;
    return true;
  }

  bool registered(int key) {
    return _values.containsKey(key);
  }

  // This is a work-around, as '+' seem to produce just a List<int>
  static Uint8List append(Uint8List b1, Uint8List b2) {
    var newBuf = Uint8List(b1.length + b2.length);
    newBuf.setAll(0, b1);
    newBuf.setAll(b1.length, b2);
    return newBuf;
  }

  static Uint8List copy(Uint8List b) {
    return Uint8List.fromList(b);
  }
}
