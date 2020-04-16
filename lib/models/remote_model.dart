import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:flutter_compass/flutter_compass.dart';

class ControlModel with ChangeNotifier {
  final String endpoint;

  ControlModel(this.endpoint) {
    FlutterCompass.events.listen((compassHeading) {
      final h = compassHeading.heading.toInt();
      if (h != heading) {
        setHeading = h;
      }
    });
  }

  static const int maxSpeed = 100;
  static const int minSpeed = -100;

  int _speedIncrement = 20;
  int get speedIncrement => _speedIncrement;
  set speedIncrement(int value) {
    _speedIncrement = value;
    notifyListeners();
  }

  int _heading = 0;
  int get heading => _heading;
  set heading(int value) {
    _heading = value;
    notifyListeners();
  }

  int _speed = 0;
  int get speed => _speed;
  set speed(int value) {
    _speed = value;
    notifyListeners();
  }

  int _setHeading = 0;
  int get setHeading => _setHeading;
  set setHeading(int value) {
    _setHeading = value;
    notifyListeners();
  }

  int _setSpeed = 0;
  int get setSpeed => _setSpeed;
  set setSpeed(int value) {
    _setSpeed = value;
    notifyListeners();
  }

  Function setSpeedIncrement(int increment) {
    return () {
      speedIncrement = increment;
    };
  }

  void accelerate() {
    final newSpeed = _setSpeed + _speedIncrement;

    if (_setSpeed < 0 && newSpeed > 0) {
      setSpeed = 0;
    } else {
      setSpeed = min(maxSpeed, newSpeed);
    }
  }

  void decelerate() {
    final newSpeed = _setSpeed - _speedIncrement;

    if (_setSpeed > 0 && newSpeed < 0) {
      setSpeed = 0;
    } else {
      setSpeed = max(minSpeed, newSpeed);
    }
  }

  void stop() {
    setSpeed = 0;
  }

  bool isMaxSpeed() => setSpeed == maxSpeed;
  bool isMinSpeed() => setSpeed == minSpeed;
  bool isStopped() => setSpeed == 0;
}
