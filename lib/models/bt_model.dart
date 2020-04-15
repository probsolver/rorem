import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:rorem/models/data_handler.dart';

const SDP_SERIAL_UUID = '00001101-0000-1000-8000-00805f9b34fb';

class BTDevice {
  final BluetoothDevice device;

  String get name => device.name;
  String get address => device.address;
  bool get bonded => device.isBonded;
  bool get connected => device.isConnected;

  const BTDevice(this.device);
}

class BTDisco {
  StreamSubscription<BluetoothDiscoveryResult> _discoStream;
  List<BluetoothDevice> _deviceList = [];
  List<BluetoothDevice> get deviceList => _deviceList;
  final Function onDiscovered;

  bool _done = false;
  bool get done => _done;

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
    if (_running) {
      _running = false;
      _discoStream?.cancel();
    }
    _done = false;
  }

  void _run() {
    _done = false;
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
      _done = true;
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

  List<BluetoothDevice> _paired = [];
  List<BTDevice> get paired => _paired.map((d) => BTDevice(d)).toList();

  List<BTDevice> get connected => paired.where((d) => d.connected).toList();

  List<BluetoothDevice> _discovered = [];
  List<BTDevice> get discovered => _discovered.map((d) => BTDevice(d)).toList();

  String _address;
  String get address => _address ?? '-';

  BluetoothConnection _connection;

  String _name;
  String get name => _name ?? '-';

  BTDisco _disco;

  DataHandler _dataHandler;
  DataHandler get dataHandler => _dataHandler;

  BluetoothState _state = BluetoothState.UNKNOWN;

  BTState get state {
    if (!_available) {
      return BTState.ERROR;
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
      if (_connection != null && _connection.isConnected) {
        return BTState.CONNECTED;
      }
      return BTState.CONNECTING;
    } else {
      // BluetoothState.ERROR or UNKNOWN
      return BTState.ERROR;
    }
  }

  BTModel() {
    //_dataHandler = DataHandler();

    FlutterBluetoothSerial.instance.isAvailable.then((value) {
      _available = value;
      if (!value) {
        _state = BluetoothState.ERROR;
      }
      notifyListeners();
    });
    FlutterBluetoothSerial.instance.onStateChanged().listen((btState) {
      if (btState == BluetoothState.ERROR ||
          btState == BluetoothState.STATE_BLE_TURNING_OFF ||
          btState == BluetoothState.STATE_TURNING_OFF ||
          btState == BluetoothState.STATE_OFF ||
          btState == BluetoothState.UNKNOWN) {
        _disco?.stop();
        _connection?.close();
        _connection = null;
      }
      if (_state != btState) {
        _state = btState;
        notifyListeners();
      }
    });
    _disco = BTDisco(onDiscovered: (List<BluetoothDevice> devs) {
      for (var d in devs) {
        if (_paired.firstWhere((p) => p.address == d.address,
                orElse: () => null) ??
            false) {
          updatePairedDevices();
        }
      }
    });
  }

  @override
  void dispose() {
    _disco?.stop();
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
    if (_connection?.isConnected ?? false) {
      return;
    }
    _connect(address);
  }

  void disconnect(address) {
    if (_connection?.isConnected ?? false) {
      if (_paired.any((dev) => dev.address == address)) {
        _disconnect();
      }
    }
    return;
  }

  void _connect(String address) {
    var devs = _paired;
    var device =
        devs.firstWhere((dev) => dev.address == address, orElse: () => null);

    if (!(device?.isConnected ?? false)) {
      BluetoothConnection.toAddress(address).then((btConn) {
        _connection = btConn;
        print('BT connected');
        _connection.output.add(ascii.encode('hi there'));

        _dataHandler.register(1);
        _dataHandler.register(2);

        _connection.output.add(ascii.encode('hi again!!!'));

        _connection.input.listen((event) {
          // FIXME: implement
          print('BT data received ${event.length}');
          print('BT data: $event');
        });
        notifyListeners();
      }).then((_) {
        updatePairedDevices();
      }).catchError((e) {
        _state = BluetoothState.ERROR;
        notifyListeners();
      });
    }
  }

  void _disconnect() {
    _connection?.close()?.then((_) => updatePairedDevices());
  }

  BluetoothConnection get connection {
    if (state == BTState.CONNECTED) {
      return _connection;
    }
    return null;
  }

  Future<void> enableBluetooth() async {
    _available = await FlutterBluetoothSerial.instance.isAvailable;

    if (_available) {
      await FlutterBluetoothSerial.instance.requestEnable();
    } else {
      _state = BluetoothState.ERROR;
      _name = null;
      _address = null;
      notifyListeners();
      return;
    }

    await updatePairedDevices();

    Future.doWhile(() async {
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        notifyListeners();
        return false;
      }
      await Future.delayed(Duration(microseconds: 200));
      _state = BluetoothState.ERROR;
      notifyListeners();
      return true;
    }).then((_) {
      FlutterBluetoothSerial.instance.address.then((value) => _address = value);
    }).then((_) {
      FlutterBluetoothSerial.instance.name.then((value) => _name = value);
      notifyListeners();
    }).then((_) {
      FlutterBluetoothSerial.instance.state.then((value) => _state = value);
      notifyListeners();
    });

    notifyListeners();
    return;
  }

  Future<void> updatePairedDevices() async {
    try {
      _paired = await FlutterBluetoothSerial.instance.getBondedDevices();
    } on PlatformException {
      _state = BluetoothState.ERROR;
    }
    notifyListeners();
  }
}
