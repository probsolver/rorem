import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:rorem/models/bt_model.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BTModel>(
          create: (context) => BTModel(),
        ),
        ChangeNotifierProvider<ControlModel>(
          create: (context) => ControlModel(''),
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
                builder: (context) => ControlPage(title: 'RoRem'));
          }

          final uri = Uri.parse(settings.name);
          if (uri.pathSegments.length == 1 &&
              uri.pathSegments.elementAt(0) == 'bt') {
            return MaterialPageRoute(
              builder: (context) => BTPage(title: 'Bluetooth devices'),
              maintainState: true,
              //fullscreenDialog: true,
            );
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
      ),
    );
  }
}
