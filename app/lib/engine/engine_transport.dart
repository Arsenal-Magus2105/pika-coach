abstract interface class EngineTransport {
  Stream<String> get stdout;
  Future<void> start();
  void send(String command);
  Future<void> dispose();
}
