import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'models/remote_model.dart';
import 'controls/speed.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) => runApp(RoRemApp()));
}

class RoRemApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoRem robotic remote',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ControlPage(title: 'Control'),
    );
  }
}

class ControlPage extends StatelessWidget {
  ControlPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ControlModel('some endpoint'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              HeadingIndicatorText(),
              SpeedIndicatorText(),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 30, 60),
          child: FloatingSpeedControls(),
        ),
      ),
    );
  }
}
