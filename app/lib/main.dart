import 'package:flutter/material.dart';

import 'analysis/coach_controller.dart';
import 'app_theme.dart';
import 'engine/nnue_installer.dart';
import 'engine/pikafish_native_transport.dart';
import 'engine/pikafish_service.dart';
import 'screens/coach_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PikaCoachApp());
}

class PikaCoachApp extends StatefulWidget {
  const PikaCoachApp({super.key, this.controller});

  final CoachController? controller;

  @override
  State<PikaCoachApp> createState() => _PikaCoachAppState();
}

class _PikaCoachAppState extends State<PikaCoachApp> {
  late final CoachController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        CoachController(
          engine: PikafishService(PikafishNativeTransport()),
          networkInstaller: const BundledNnueInstaller(),
        );
    _controller.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pika Coach',
      debugShowCheckedModeBanner: false,
      theme: PikaTheme.dark,
      home: CoachScreen(controller: _controller),
    );
  }
}
