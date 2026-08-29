import 'package:flutter_test/flutter_test.dart';
import 'package:juicytropicgame/app.dart';

void main() {
  testWidgets('Juicy Tropic boots into the loading screen', (tester) async {
    await tester.pumpWidget(const JuicyApp());
    expect(find.textContaining('%'), findsOneWidget);
  });
}
