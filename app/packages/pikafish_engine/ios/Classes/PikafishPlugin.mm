#import "PikafishPlugin.h"
#import "ffi.h"

@implementation PikafishPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  if (registrar == nil) {
    // Keep the FFI symbols visible to DynamicLibrary.process().
    pikafish_init();
    pikafish_main();
    pikafish_stdin_write(nullptr);
    pikafish_stdout_read();
  }
}
@end
