import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Consumer<ControlModel>(
      builder: (context, cModel, _) => Text(
        '${cModel.setSpeed} (${cModel.speed})',
        style: Theme.of(context).textTheme.headline5,
      ),
    );
  }
}

class HeadingIndicator extends StatelessWidget {
  const HeadingIndicator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlModel>(
      builder: (context, cModel, _) => Text(
        '${cModel.setHeading} (${cModel.heading})',
        style: Theme.of(context).textTheme.headline5,
      ),
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
            onPressed: cModel.isMaxSpeed() ? null : cModel.accelerate,
            tooltip: 'accelerate',
            child: Icon(Icons.arrow_upward),
            heroTag: null,
          ),
          FloatingActionButton(
            onPressed: cModel.isStopped() ? null : cModel.stop,
            tooltip: 'stop',
            child: Icon(Icons.stop_circle_outlined),
            heroTag: null,
          ),
          FloatingActionButton(
            onPressed: cModel.isMinSpeed() ? null : cModel.decelerate,
            tooltip: 'deccelerate',
            child: Icon(Icons.arrow_downward),
            heroTag: null,
          ),
        ],
      ),
    );
  }
}
