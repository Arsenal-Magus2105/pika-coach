import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class NetworkInstaller {
  Future<String> install();
}

class BundledNnueInstaller implements NetworkInstaller {
  const BundledNnueInstaller();

  @override
  Future<String> install() async {
    const assetPath = 'assets/pikafish.nnue';
    final directory = await getApplicationSupportDirectory();
    final target = File('${directory.path}/pikafish.nnue');
    if (await target.exists() && await target.length() > 1000000) {
      return target.path;
    }
    try {
      final data = await rootBundle.load(assetPath);
      await target.parent.create(recursive: true);
      await target.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return target.path;
    } catch (error) {
      throw StateError(
        'Không tìm thấy NNUE. Chạy scripts/bootstrap.sh trước khi build. '
        'Chi tiết: $error',
      );
    }
  }
}
