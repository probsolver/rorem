import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'models/remote_model.dart';
import 'controls/remote.dart';
import 'controls/bt.dart';

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
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
              builder: (context) => ControlPage(title: 'Control'));
        }

        final uri = Uri.parse(settings.name);
        if (uri.pathSegments.length == 1 &&
            uri.pathSegments.elementAt(0) == 'bt') {
          return MaterialPageRoute(builder: (context) => BTPage());
        }

        //return MaterialPageRoute(builder: (context) => UnknownPage());
        return MaterialPageRoute(builder: (context) => BTPage());
      },
      title: 'RoRem robotic remote',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ControlPage(title: 'Control'),
      debugShowCheckedModeBanner: false,
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
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.bluetooth),
              onPressed: () => Navigator.pushNamed(context, '/bt'),
              color: Colors.blue[100], // redAccent[400], greenAccent[400]
            ),
          ],
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
