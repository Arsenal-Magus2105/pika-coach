import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final DynamicLibrary _nativeLibrary = Platform.isAndroid
    ? DynamicLibrary.open('libpikafish.so')
    : DynamicLibrary.process();

final int Function() nativeInit = _nativeLibrary
    .lookup<NativeFunction<Int32 Function()>>('pikafish_init')
    .asFunction();

final int Function() nativeMain = _nativeLibrary
    .lookup<NativeFunction<Int32 Function()>>('pikafish_main')
    .asFunction();

final int Function(Pointer<Utf8>) nativeStdinWrite = _nativeLibrary
    .lookup<NativeFunction<IntPtr Function(Pointer<Utf8>)>>(
      'pikafish_stdin_write',
    )
    .asFunction();

final Pointer<Utf8> Function() nativeStdoutRead = _nativeLibrary
    .lookup<NativeFunction<Pointer<Utf8> Function()>>('pikafish_stdout_read')
    .asFunction();
