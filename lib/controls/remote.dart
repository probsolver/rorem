import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rorem/models/bt_model.dart';

import 'bt.dart';
import '../models/remote_model.dart';

class ControlPage extends StatelessWidget {
  ControlPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          BTStatusButton(
            onPressed: () => Navigator.pushNamed(context, '/bt'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            HeadingIndicator(),
            SpeedIndicator(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 30, 60),
        child: FloatingSpeedControls(),
      ),
    );
  }
}

class SpeedIndicator extends StatelessWidget {
  const SpeedIndicator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ControlModel, BTModel>(
      builder: (context, cModel, btModel, _) {
        btModel.speed = cModel.setSpeed;
        return Text(
          '${cModel.setSpeed} (${btModel.speed})',
          style: Theme.of(context).textTheme.headline5,
        );
      },
    );
  }
}

class HeadingIndicator extends StatelessWidget {
  const HeadingIndicator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ControlModel, BTModel>(
      builder: (context, cModel, btModel, _) {
        btModel.heading = cModel.setHeading;
        return Text(
          '${cModel.setHeading} (${btModel.heading})',
          style: Theme.of(context).textTheme.headline5,
        );
      },
    );
  }
}

class FloatingSpeedControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ControlModel>(
      builder: (context, cModel, _) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              if (!cModel.isMaxSpeed()) {
                cModel.accelerate();
                Provider.of<BTModel>(context, listen: false).speed =
                    cModel.setSpeed;
              }
            },
            tooltip: 'accelerate',
            child: Icon(Icons.arrow_upward),
            heroTag: null,
          ),
          FloatingActionButton(
            onPressed: () {
              if (!cModel.isStopped()) {
                cModel.stop();
                Provider.of<BTModel>(context, listen: false).speed =
                    cModel.setSpeed;
              }
            },
            tooltip: 'stop',
            child: Icon(Icons.stop_circle_outlined),
            heroTag: null,
          ),
          FloatingActionButton(
            onPressed: () {
              if (!cModel.isMinSpeed()) {
                cModel.decelerate();
                Provider.of<BTModel>(context, listen: false).speed =
                    cModel.setSpeed;
              }
            },
            tooltip: 'deccelerate',
            child: Icon(Icons.arrow_downward),
            heroTag: null,
          ),
        ],
      ),
    );
  }
}
