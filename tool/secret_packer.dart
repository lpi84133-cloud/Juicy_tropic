// ignore_for_file: avoid_print
// Mirrors lib/rind/peel_mixer.dart. Run with: dart run tool/secret_packer.dart

const String token = 'w8#Km2nQ!vL4p';
const int ring = 41;

List<int> spin() {
  int acc = 0x9E3779B9;
  for (final int c in token.codeUnits) {
    acc = (acc ^ (c + 0x55)) & 0xFFFFFFFF;
    acc = (acc * 0x45D9F3B) & 0xFFFFFFFF;
    acc = ((acc << 7) | (acc >> 25)) & 0xFFFFFFFF;
  }
  int s = acc == 0 ? 0xA5A5A5A5 : acc;
  final List<int> bytes = List<int>.filled(ring, 0);
  for (int i = 0; i < ring; i++) {
    s ^= (s << 7) & 0xFFFFFFFF;
    s ^= s >> 9;
    s ^= (s << 13) & 0xFFFFFFFF;
    s &= 0xFFFFFFFF;
    bytes[i] = ((s >> 8) ^ (s >> 24)) & 0xFF;
  }
  return bytes;
}

final List<int> ringBytes = spin();

List<int> pack(String plain) {
  final List<int> bytes = plain.codeUnits;
  final List<int> out = List<int>.filled(bytes.length, 0);
  for (int i = 0; i < bytes.length; i++) {
    out[i] = (bytes[i] ^ ringBytes[i % ring] ^ ((i * 17 + 11) & 0xFF)) & 0xFF;
  }
  return out;
}

void emit(String label, String plain) {
  if (plain.isEmpty) {
    print('// $label — empty');
    print('const <int>[];\n');
    return;
  }
  final List<int> packed = pack(plain);
  print('// $label');
  print('const <int>[${packed.join(', ')}],\n');
}

void main() {
  const String configEndpoint = 'https://juicytrropic.online/config.php';
  const String gcdBase = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';
  const String chromeVersion = '149.0.7884.203';
  const String webkitVersion = '537.36';
  const String attributionKey = 'RrtN28R3zdCuAryCDMge9i';
  const String messagingProject = '663386317041';

  print('=== orchard packer ===\n');
  emit('configEndpoint', configEndpoint);
  emit('gcdBase', gcdBase);
  emit('chromeVersion', chromeVersion);
  emit('webkitVersion', webkitVersion);
  emit('attributionKey', attributionKey);
  emit('messagingProject', messagingProject);
}
