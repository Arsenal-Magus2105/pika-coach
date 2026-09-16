import 'package:flutter_test/flutter_test.dart';
import 'package:pika_coach/engine/engine_score.dart';
import 'package:pika_coach/engine/pikafish_service.dart';

import 'support/fake_engine_transport.dart';

void main() {
  test('initializes UCI and returns sorted MultiPV analysis', () async {
    final transport = FakeEngineTransport();
    final service = PikafishService(transport);
    addTearDown(service.dispose);

    await service.initialize(evalFilePath: '/tmp/pikafish.nnue');
    final result = await service.analyze(
      fen: 'start fen',
      multiPv: 3,
      moveTimeMs: 100,
    );

    expect(service.isReady, isTrue);
    expect(result.bestMove, 'h2e2');
    expect(result.lines.map((line) => line.multiPv), [1, 2, 3]);
    expect(result.bestLine?.score, const CentipawnScore(153));
    expect(transport.commands, contains('setoption name MultiPV value 3'));
    expect(transport.commands, contains('position fen start fen'));
  });
}
