import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/remote_model.dart';

class SpeedIndicatorText extends StatelessWidget {
  const SpeedIndicatorText({
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

class HeadingIndicatorText extends StatelessWidget {
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
  const FloatingSpeedControls({
    Key key,
  }) : super(key: key);

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
            tooltip: 'stop',
            child: Icon(Icons.arrow_downward),
            heroTag: null,
          ),
        ],
      ),
    );
  }
}
