import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:rorem/models/data_handler.dart';

void main() {
  group('DataHandler: register', () {
    test('register / duplicate register', () {
      final dh = DataHandler();
      expect(dh, isNotNull);
      expect(dh.register(1), true);
      expect(dh.register(2), true);
      expect(dh.register(2), false);
      expect(dh.registered(1), true);
      expect(dh.registered(3), false);
    });
  });

  group('DataHandler: update', () {
    test('input data parsing with not enough data', () {
      final dh = DataHandler();
      var data = Uint8List(2)..setAll(0, [1, 1]);
      dh.register(1);

      expect(dh.registered(1), true, reason: 'not registered');
      expect(dh.update(data), false, reason: 'updated when it shouldn\'t');
      expect(dh.value(1), 0, reason: 'default value was replaced');
    });
    test('input data parsing', () {
      final dh = DataHandler();
      var data = Uint8List(5)..setAll(0, [1, 0, 0, 0, 5]);
      dh.register(1);

      expect(dh.registered(1), true, reason: 'not registered');
      expect(dh.update(data), true, reason: 'not updated');
      expect(dh.value(1), 5, reason: 'got different decoded value');
    });

    test('input data parsing with leftovers', () {
      final dh = DataHandler();
      var data = Uint8List(7)..setAll(0, [1, 0, 0, 0, 5, 1, 0]);
      var date2 = Uint8List(6)..setAll(0, [0, 0, 6, 1, 0, 0]);
      dh.register(1);

      expect(dh.registered(1), true, reason: 'not registered');
      expect(dh.update(data), true, reason: 'not updated');
      expect(dh.value(1), 5, reason: 'got different decoded value');
      expect(dh.update(date2), true, reason: 'not updated #2');
      expect(dh.value(1), 6, reason: 'got different decoded value #2');
    });
  });
}
