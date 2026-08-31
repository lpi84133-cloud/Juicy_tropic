import 'package:flutter/material.dart';

import '../core/design.dart';
import '../data/progress_store.dart';
import '../grove/grove_mark.dart';
import '../widgets/ui.dart';

class OrchardRoot extends StatelessWidget {
  const OrchardRoot({super.key, required this.home});

  final Widget home;

  static final ValueNotifier<ProgressStore?> groveStore =
      ValueNotifier<ProgressStore?>(null);

  static void attachStore(ProgressStore store) {
    groveStore.value = store;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GroveMark.displayName,
      debugShowCheckedModeBanner: false,
      theme: D.theme(),
      builder: (BuildContext context, Widget? child) {
        final Widget page = child ?? const SizedBox.shrink();
        return ValueListenableBuilder<ProgressStore?>(
          valueListenable: groveStore,
          builder: (BuildContext context, ProgressStore? store, _) {
            if (store == null) return page;
            return ProgressScope(store: store, child: page);
          },
        );
      },
      home: home,
    );
  }
}
