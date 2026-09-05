import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang/main.dart';

void main() {
  testWidgets('Jizhang app builds its MaterialApp shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, '记账本');
    expect(app.debugShowCheckedModeBanner, isFalse);
  });
}
