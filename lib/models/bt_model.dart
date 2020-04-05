import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

const SVC_UUID = 'b65021ac-4d44-4c29-88b5-5bc9da5fd304';

class BTDisco {
  StreamSubscription<BluetoothDiscoveryResult> _discoStream;
  List<BluetoothDevice> _deviceList = [];
  List<BluetoothDevice> get deviceList => _deviceList;
  final Function onDiscovered;

  bool _running = false;
  bool get isRunning => _running;

  BTDisco({this.onDiscovered});

  void dispose() {
    this._stop();
  }

  start() {
    if (_running) {
      return;
    }
    _run();
  }

  void stop() {
    if (!_running) {
      return;
    }
    _stop();
  }

  void _stop() {
    _deviceList.clear();
    _running = false;
    _discoStream?.cancel();
  }

  void _run() {
    _running = true;
    _discoStream = FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((BluetoothDiscoveryResult de) {
      if (de.device.isConnected || _isAlreadyKnown(de.device)) {
        return;
      }
      _deviceList.add(de.device);
      if (onDiscovered != null) {
        onDiscovered(_deviceList);
      }
    });
    _discoStream.onDone(() {
      _running = false;
      if (onDiscovered != null) {
        onDiscovered(_deviceList);
      }
    });
    _discoStream.onError(() {
      _stop();
      // device list will be empty
      if (onDiscovered != null) {
        onDiscovered(_deviceList);
      }
    });
  }

  bool _isAlreadyKnown(BluetoothDevice dev) {
    return _deviceList.any((knownDev) => knownDev.address == dev.address);
  }
}

enum BTState {
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
  ERROR,
}

class BTModel extends ChangeNotifier {
  bool _available = false;
  BluetoothState _state = BluetoothState.UNKNOWN;
  BTState get state {
    if (!_available) {
      return BTState.DISCONNECTED;
    }
    if (_state == BluetoothState.ERROR) {
      return BTState.ERROR;
    }

    if (_state == BluetoothState.STATE_BLE_TURNING_OFF ||
        _state == BluetoothState.STATE_OFF ||
        _state == BluetoothState.STATE_TURNING_OFF) {
      return BTState.DISCONNECTED;
    }
    if (_state == BluetoothState.STATE_TURNING_ON ||
        _state == BluetoothState.STATE_BLE_TURNING_ON) {
      return BTState.CONNECTING;
    }
    if (_state == BluetoothState.STATE_ON ||
        _state == BluetoothState.STATE_BLE_ON) {
      if (_connection != null) {
        return BTState.CONNECTED;
      }
      return BTState.CONNECTING;
    } else {
      // BluetoothState.ERROR or UNKNOWN
      return BTState.ERROR;
    }
  }

  String _address;
  String get address => _address ?? '-';

  BluetoothConnection _connection;

  String _name;
  String get name => _name;

  void _setDevices(List<BluetoothDevice> _devs) {
    notifyListeners();
  }

  BTDisco _disco;

  List<BluetoothDevice> get discoveredDevices {
    return _disco?.deviceList;
  }

  BTModel() {
    FlutterBluetoothSerial.instance.isAvailable
        .then((value) => _available = value);
    if (!_available) {
      _state = BluetoothState.ERROR;
      return;
    }

    FlutterBluetoothSerial.instance.state.then((value) => _state = value);

    Future.doWhile(() async {
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(microseconds: 200));
      return true;
    }).then((_) {
      FlutterBluetoothSerial.instance.address.then((value) => _address = value);
    }).then((_) {
      FlutterBluetoothSerial.instance.name.then((value) => _name = value);
    });
    FlutterBluetoothSerial.instance.onStateChanged().listen((btState) {
      _state = btState;
      _disco?.stop();
      if (btState == BluetoothState.ERROR ||
          btState == BluetoothState.STATE_BLE_TURNING_OFF ||
          btState == BluetoothState.STATE_TURNING_OFF ||
          btState == BluetoothState.STATE_OFF ||
          btState == BluetoothState.UNKNOWN) {
        _connection.close();
        _connection.dispose();
        _connection = null;
      }
      notifyListeners();
    });

    _disco = BTDisco(onDiscovered: _setDevices);
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _disco?.dispose();
    _disco = null;
    _connection.dispose();
    super.dispose();
  }

  void discover() {
    if (_disco.isRunning) {
      return;
    }
    _disco.start();
  }

  void connect(String address) {
    if (state != BTState.CONNECTING) {
      return;
    }
    if (_connection != null) {
      return;
    }
    _connect(address);
  }

  void _connect(String address) {
    var devs = discoveredDevices;
    var d =
        devs.firstWhere((dev) => dev.address == address, orElse: () => null);
    if (d != null) {
      if (!d.isConnected) {
        BluetoothConnection.toAddress(address).then((btConn) {
          _connection = btConn;
          _address = address;
          notifyListeners();
        }).catchError(() => this.notifyListeners());
      }
    }
  }

  BluetoothConnection get connection {
    if (state == BTState.CONNECTED) {
      return _connection;
    }
    return null;
  }
}
