import 'dart:async';

import 'package:pika_coach/engine/engine_transport.dart';

class FakeEngineTransport implements EngineTransport {
  final StreamController<String> _output = StreamController<String>.broadcast();
  final List<String> commands = [];
  bool started = false;

  List<String> analysisOutput = const [
    'info depth 18 seldepth 24 multipv 1 score cp 153 nodes 9000 nps 450000 time 20 pv h2e2 h9g7 h0g2',
    'info depth 18 seldepth 23 multipv 2 score cp 91 nodes 8500 nps 425000 time 20 pv h0g2 h9g7',
    'info depth 18 seldepth 22 multipv 3 score cp 72 nodes 8000 nps 400000 time 20 pv i0i1 h9g7',
    'bestmove h2e2 ponder h9g7',
  ];

  @override
  Stream<String> get stdout => _output.stream;

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  void send(String command) {
    commands.add(command);
    if (command == 'uci') {
      scheduleMicrotask(() => _output.add('uciok'));
    } else if (command == 'isready') {
      scheduleMicrotask(() => _output.add('readyok'));
    } else if (command.startsWith('go ')) {
      scheduleMicrotask(() {
        for (final line in analysisOutput) {
          _output.add(line);
        }
      });
    }
  }

  @override
  Future<void> dispose() => _output.close();
}
