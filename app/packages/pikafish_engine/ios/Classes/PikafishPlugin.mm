#import "PikafishPlugin.h"
#import "ffi.h"

@implementation PikafishPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  if (registrar == nil) {
    // Keep the FFI symbols visible to DynamicLibrary.process().
    (void)&pikafish_init;
    (void)&pikafish_main;
    (void)&pikafish_stdin_write;
    (void)&pikafish_stdout_read;
  }
}
@end
