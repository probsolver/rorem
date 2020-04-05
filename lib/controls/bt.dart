import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bt_model.dart';

class BTPage extends StatelessWidget {
  BTPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => BTModel(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Bluetooth devices'),
          ),
          //body: ETAOIN SHRDLU,
        ));
  }
}
