import 'package:pikafish_engine/pikafish.dart' as native;

import 'engine_transport.dart';

class PikafishNativeTransport implements EngineTransport {
  native.Pikafish? _engine;

  @override
  Stream<String> get stdout {
    final engine = _engine;
    if (engine == null) throw StateError('Pikafish has not started');
    return engine.stdout;
  }

  @override
  Future<void> start() async {
    if (_engine != null) return;
    _engine = await native.pikafishAsync();
  }

  @override
  void send(String command) {
    final engine = _engine;
    if (engine == null) throw StateError('Pikafish has not started');
    engine.stdin = command;
  }

  @override
  Future<void> dispose() async {
    _engine?.dispose();
    _engine = null;
  }
}
