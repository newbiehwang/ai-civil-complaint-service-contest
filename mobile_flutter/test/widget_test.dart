import 'package:flutter_test/flutter_test.dart';

import 'package:civil_complaint_mobile_flutter/main.dart';

void main() {
  testWidgets('renders start flow headline', (tester) async {
    await tester.pumpWidget(const CivilComplaintApp());

    expect(find.textContaining('신속한 처리'), findsOneWidget);
  });
}
