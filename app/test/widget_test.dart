import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pika_coach/analysis/coach_controller.dart';
import 'package:pika_coach/engine/pikafish_service.dart';
import 'package:pika_coach/main.dart';

import 'support/fake_engine_transport.dart';
import 'support/fake_network_installer.dart';

void main() {
  testWidgets('shows Pikafish candidates after analysis', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CoachController(
      engine: PikafishService(FakeEngineTransport()),
      networkInstaller: const FakeNetworkInstaller(),
      moveTimeMs: 100,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(PikaCoachApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('PIKA COACH'), findsOneWidget);
    expect(find.text('Pikafish sẵn sàng'), findsOneWidget);

    await tester.tap(find.text('Gợi ý & phân tích'));
    await tester.pumpAndSettle();

    expect(find.text('Pháo 2 bình 5'), findsOneWidget);
    expect(find.text('+1.53'), findsOneWidget);
    expect(find.text('Depth 18'), findsOneWidget);
  });
}
