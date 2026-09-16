import 'package:pika_coach/engine/nnue_installer.dart';

class FakeNetworkInstaller implements NetworkInstaller {
  const FakeNetworkInstaller([this.path = '/tmp/pikafish.nnue']);

  final String path;

  @override
  Future<String> install() async => path;
}
