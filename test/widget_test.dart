import 'package:flutter_test/flutter_test.dart';
import 'package:mirror/main.dart';

void main() {
  testWidgets('renders visible placeholder content', (tester) async {
    await tester.pumpWidget(const MirrorApp());

    expect(find.text('Hello world'), findsOneWidget);
  });
}
