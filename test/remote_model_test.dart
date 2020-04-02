import 'package:test/test.dart';

import 'package:rorem/models/remote_model.dart';

void main() {
  group('ControlModel: setters/getters', () {
    test('default = 0', () {
      final cm = ControlModel('something');
      expect(cm.setHeading, 0);
      expect(cm.heading, 0);
      expect(cm.setSpeed, 0);
      expect(cm.speed, 0);
    });
    test('set/get back the same value', () {
      final cm = ControlModel('something');
      cm.setHeading = 1;
      expect(cm.setHeading, 1);
    });
  });

  group('speed control', () {
    test('speed increased from 0, stop sets it back to 0', () {
      final cm = ControlModel('endpoint');
      cm.accelerate();
      expect(cm.setSpeed, greaterThan(0));
      cm.stop();
      expect(cm.setSpeed, 0);
    });
    test('speed decreased to 0', () {
      final cm = ControlModel('endpoint');
      cm.accelerate();
      cm.decelerate();
      expect(cm.setSpeed, 0);
    });

    test('speed increased, then decreased twice, and is negative', () {
      final cm = ControlModel('endpoint');
      cm.accelerate();
      cm.decelerate();
      cm.decelerate();
      expect(cm.setSpeed, lessThan(0));
    });
  });

  group('ControlModel: ChangeNotifier notifies listener(s)', () {
    final cm3 = ControlModel('endpoint2');
    test('notify', () {
      cm3.addListener(() {
        expect(cm3.heading, 11);
      });
    });
    cm3.heading = 11;
  });
}
