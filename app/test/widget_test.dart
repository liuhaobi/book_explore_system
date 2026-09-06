import 'package:flutter_test/flutter_test.dart';
import 'package:pig_im_client/main.dart';

void main() {
  testWidgets('App should render the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Pig IM'), findsOneWidget);
  });
}
