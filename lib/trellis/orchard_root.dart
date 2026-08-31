import 'package:flutter/material.dart';

import '../core/design.dart';
import '../grove/grove_mark.dart';

class OrchardRoot extends StatelessWidget {
  const OrchardRoot({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GroveMark.displayName,
      debugShowCheckedModeBanner: false,
      theme: D.theme(),
      home: home,
    );
  }
}
