import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:rorem/models/data_handler.dart';

const SDP_SERIAL_UUID = '00001101-0000-1000-8000-00805f9b34fb';

const ValueKeySpeed = 1;
const ValueKeyHeading = 2;

class BTDevice {
  final BluetoothDevice device;

  String get name => device.name;
  String get address => device.address;
  bool get bonded => device.isBonded;
  bool get connected => device.isConnected;

  const BTDevice(this.device);
}

enum BTState {
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
  ERROR,
}

class BTModel with ChangeNotifier {
  bool _available = false;

  List<BluetoothDevice> _paired = [];
  List<BTDevice> get paired => _paired.map((d) => BTDevice(d)).toList();

  List<BTDevice> get connected => state == BTState.CONNECTED
      ? paired.where((d) => d.connected).toList()
      : [];

  List<BluetoothDevice> _discovered = [];
  List<BTDevice> get discovered => _discovered.map((d) => BTDevice(d)).toList();

  String _address;
  String get address => _address ?? '-';

  BluetoothConnection _connection;

  String _name;
  String get name => _name ?? '-';

  DataHandler _dataHandler = DataHandler();
  DataHandler get dataHandler => _dataHandler;

  int get speed => value(ValueKeySpeed);
  set speed(int value) => enqueue(ValueKeySpeed, value);

  int get heading => value(ValueKeyHeading);
  set heading(int value) => enqueue(ValueKeyHeading, value);

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
    _dataHandler = DataHandler();
    _dataHandler.register(ValueKeySpeed);
    _dataHandler.register(ValueKeyHeading);

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
        _connection?.close();
        _connection = null;
      }
      if (_state != btState) {
        _state = btState;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _connection.dispose();
    _connection = null;
    super.dispose();
  }

  void connect(String address) {
    if (_connection?.isConnected ?? false) {
      return;
    }
    _connect(address);
  }

  void disconnect() {
    if (_connection?.isConnected ?? false) {
      _disconnect();
    }
    return;
  }

  void _connect(String address) {
    var devs = _paired;
    var device =
        devs.firstWhere((dev) => dev.address == address, orElse: () => null);

    BluetoothConnection.toAddress(address)
        .then((btConn) {
          _connection = btConn;
          print('BT connected');

          // _connection.output
          //   .add(ascii.encode('hello there!!!!')); // multiple of 5

          _connection.input.listen((event) {
            print('BT data received: $event');
            var changed = _dataHandler.update(event);
            print('values updated: $changed');
            if (changed) {
              notifyListeners();
            }
          }, onDone: () {
            print('BT connection closed');
            disconnect();
            _state = BluetoothState.STATE_TURNING_OFF;
            notifyListeners();
          }, onError: (error) {
            print('BT connection recv error: $error');
            _state = BluetoothState.ERROR;
            notifyListeners();
          });
          notifyListeners();
        })
        .then((_) => FlutterBluetoothSerial.instance.state)
        .then((state) {
          _state = state;
          updatePairedDevices();
        })
        .catchError((e) {
          _state = BluetoothState.ERROR;
          notifyListeners();
        });
  }

  void _disconnect() {
    _connection
        ?.close()
        ?.then((_) => updatePairedDevices())
        ?.then((_) => FlutterBluetoothSerial.instance.state)
        ?.then((value) => _state = value);
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

  int value(int key) {
    return _dataHandler.value(key);
  }

  void enqueue(int key, int value) {
    if (_dataHandler.enqueue(key, value)) {
      if (_dataHandler.enqueued && _connection != null) {
        try {
          _connection.output.add(_dataHandler.encodeNew());
        } catch (e) {
          print('BT connection send error: $e');
          disconnect();
          _state = BluetoothState.ERROR;
          notifyListeners();
        }
      }
    }
  }
}
