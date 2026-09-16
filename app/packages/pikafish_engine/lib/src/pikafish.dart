import 'dart:async';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'ffi.dart';
import 'pikafish_state.dart';

final _logger = Logger('Pikafish');

/// A single in-process Pikafish instance.
class Pikafish {
  Pikafish._({this.completer}) {
    _mainSubscription = _mainPort.listen(
      (message) => _cleanUp(message is int ? message : 1),
    );
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _stdoutController.add(message);
      }
    });
    compute(_spawnIsolates, [_mainPort.sendPort, _stdoutPort.sendPort]).then(
      (success) {
        if (!success) {
          _fail(StateError('Could not start Pikafish isolates'));
          return;
        }
        _state.setValue(PikafishState.ready);
        final pending = completer;
        if (pending != null && !pending.isCompleted) pending.complete(this);
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.severe('Pikafish initialization failed', error, stackTrace);
        _fail(error, stackTrace);
      },
    );
  }

  factory Pikafish() {
    if (_instance != null) {
      throw StateError('Only one Pikafish instance can be used at a time');
    }
    return _instance = Pikafish._();
  }

  static Pikafish? _instance;
  final Completer<Pikafish>? completer;
  final _state = _PikafishState();
  final _stdoutController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();
  late final StreamSubscription<dynamic> _mainSubscription;
  late final StreamSubscription<dynamic> _stdoutSubscription;
  bool _closed = false;

  ValueListenable<PikafishState> get state => _state;
  Stream<String> get stdout => _stdoutController.stream;

  set stdin(String line) {
    final current = _state.value;
    if (current != PikafishState.ready) {
      throw StateError('Pikafish is not ready ($current)');
    }
    final pointer = '$line\n'.toNativeUtf8();
    try {
      nativeStdinWrite(pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  void dispose() {
    if (_state.value == PikafishState.ready) stdin = 'quit';
  }

  void _fail(Object error, [StackTrace? stackTrace]) {
    final pending = completer;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(error, stackTrace);
    }
    _cleanUp(1);
  }

  void _cleanUp(int exitCode) {
    if (_closed) return;
    _closed = true;
    _mainSubscription.cancel();
    _stdoutSubscription.cancel();
    _mainPort.close();
    _stdoutPort.close();
    _stdoutController.close();
    _state.setValue(
      exitCode == 0 ? PikafishState.disposed : PikafishState.error,
    );
    final pending = completer;
    if (exitCode != 0 && pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Pikafish exited with code $exitCode'));
    }
    _instance = null;
  }
}

Future<Pikafish> pikafishAsync() {
  if (Pikafish._instance != null) {
    return Future.error(
      StateError('Only one Pikafish instance can be used at a time'),
    );
  }
  final completer = Completer<Pikafish>();
  Pikafish._instance = Pikafish._(completer: completer);
  return completer.future;
}

class _PikafishState extends ChangeNotifier
    implements ValueListenable<PikafishState> {
  PikafishState _value = PikafishState.starting;

  @override
  PikafishState get value => _value;

  void setValue(PikafishState value) {
    if (value == _value) return;
    _value = value;
    notifyListeners();
  }
}

void _isolateMain(SendPort mainPort) {
  final exitCode = nativeMain();
  mainPort.send(exitCode);
}

void _isolateStdout(SendPort stdoutPort) {
  var previous = '';
  while (true) {
    final pointer = nativeStdoutRead();
    if (pointer.address == 0) return;
    final lines = (previous + pointer.toDartString()).split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
    }
  }
}

Future<bool> _spawnIsolates(List<SendPort> ports) async {
  if (nativeInit() != 0) return false;
  try {
    await Isolate.spawn(_isolateStdout, ports[1]);
    await Isolate.spawn(_isolateMain, ports[0]);
    return true;
  } catch (error, stackTrace) {
    _logger.severe('Could not spawn Pikafish worker', error, stackTrace);
    return false;
  }
}
