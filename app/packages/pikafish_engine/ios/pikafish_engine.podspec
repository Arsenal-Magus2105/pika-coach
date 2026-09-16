require 'yaml'

pubspec = YAML.load_file(File.join(__dir__, '../pubspec.yaml'))

Pod::Spec.new do |s|
  s.name = pubspec['name']
  s.version = pubspec['version']
  s.summary = pubspec['description']
  s.homepage = pubspec['repository']
  s.license = { :file => '../LICENSE', :type => 'MIT' }
  s.author = 'Pika Coach contributors'
  s.source = { :git => pubspec['repository'], :tag => s.version.to_s }
  s.source_files = 'Classes/**/*', 'FlutterPikafish/*', 'Pikafish/src/**/*'
  s.public_header_files = 'Classes/**/*.h'
  # Upstream universal/ contains standalone Linux/CPU dispatch entry points.
  # The plugin invokes Stockfish::main directly using UNIVERSAL_BINARY.
  s.exclude_files = 'Pikafish/src/universal/**/*', 'Pikafish/src/incbin/UNLICENCE'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.ios.deployment_target = '13.0'
  s.library = 'c++'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'OTHER_CPLUSPLUSFLAGS[config=Debug]' => '$(inherited) -std=c++17 -DUSE_PTHREADS -DIS_64BIT -DUNIVERSAL_BINARY',
    'OTHER_LDFLAGS[config=Debug]' => '$(inherited) -std=c++17 -DUSE_PTHREADS -DIS_64BIT -DUNIVERSAL_BINARY',
    'OTHER_CPLUSPLUSFLAGS[config=Release]' => '$(inherited) -fno-exceptions -std=c++17 -DUSE_PTHREADS -DNDEBUG -O3 -DIS_64BIT -DUNIVERSAL_BINARY',
    'OTHER_LDFLAGS[config=Release]' => '$(inherited) -fno-exceptions -std=c++17 -DUSE_PTHREADS -DNDEBUG -O3 -DIS_64BIT -DUNIVERSAL_BINARY'
  }
end
