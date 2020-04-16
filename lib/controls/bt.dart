import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bt_model.dart';

class BTPage extends StatelessWidget {
  BTPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            BTStatusButton(),
          ],
        ),
        body: Consumer<BTModel>(builder: (context, btModel, _) {
          return Center(
            child: Column(
              children: [
                Text(
                  (btModel.name == null)
                      ? 'Bluetooth disabled'
                      : 'this device: ${btModel.name} (${btModel.address})',
                ),
                CountIndicator(
                  count: btModel.paired.length,
                  suffix: ' paired devices',
                ),
                Expanded(
                  flex: 5,
                  child: BTDeviceList(
                    devices: btModel.paired,
                    onDeviceSelected: (dev) => btModel.connect(dev.address),
                    decoration:
                        BoxDecoration(color: Theme.of(context).focusColor),
                  ),
                ),
                CountIndicator(
                  count: btModel.connected.length,
                  suffix: ' connected devices',
                ),
                Expanded(
                  flex: 3,
                  child: BTDeviceList(
                    devices: btModel.connected,
                    onDeviceSelected: (dev) => btModel.disconnect(),
                    decoration:
                        BoxDecoration(color: Theme.of(context).backgroundColor),
                  ),
                ),
              ],
            ),
          );
        }));
  }
}

class CountIndicator extends StatelessWidget {
  final String prefix;
  final String suffix;
  final int count;

  const CountIndicator({Key key, this.count, this.prefix, this.suffix})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
        prefix ?? '' + count.toString() + suffix ?? '',
        style: Theme.of(context).textTheme.headline6,
        textAlign: TextAlign.left,
      ),
    );
  }
}

class BTDeviceList extends StatelessWidget {
  final List<BTDevice> devices;
  final Function onDeviceSelected;
  final Decoration decoration;

  const BTDeviceList(
      {Key key, this.devices, this.onDeviceSelected, this.decoration})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: EdgeInsets.symmetric(vertical: 1),
      height: 300,
      child: ListView(
        children: devices
            .map((dev) =>
                BTDeviceCard(device: dev, onDeviceSelected: onDeviceSelected))
            .toList(),
      ),
    );
  }
}

class BTDeviceCard extends StatelessWidget {
  final BTDevice device;
  final Function onDeviceSelected;

  const BTDeviceCard({Key key, this.device, this.onDeviceSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 8),
      child: Card(
        child: TextButton(
          child: Column(
            children: [
              Text(
                '${device.name ?? '-'}',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.headline6,
              ),
              Text(
                'address: ${device.address ?? '-'}',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ],
          ),
          onPressed: () =>
              (onDeviceSelected == null) ? null : onDeviceSelected(device),
        ),
      ),
    );
  }
}

class BTStatusButton extends StatelessWidget {
  const BTStatusButton({Key key, this.onPressed}) : super(key: key);

  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<BTModel>(
      builder: (context, btModel, _) {
        Color btnColor;
        switch (btModel.state) {
          case BTState.CONNECTED:
            btnColor = Colors.blue[300];
            break;
          case BTState.ERROR:
            btnColor = Colors.red[200];
            break;
          default:
            btnColor = Colors.blue[100];
            break;
        }

        return IconButton(
          icon: Icon(Icons.bluetooth),
          onPressed: () {
            btModel.enableBluetooth();
            if (onPressed != null) {
              onPressed();
            }
          },
          color: btnColor, // redAccent[400], greenAccent[400]
        );
      },
    );
  }
}
