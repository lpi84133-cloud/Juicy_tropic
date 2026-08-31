import 'dart:typed_data';

// Opaque mixer for packed credentials. Seed and ring length are unique
// to this build — do not copy them into another title.

const String _token = 'w8#Km2nQ!vL4p';
const int _ring = 41;

Uint8List _spin() {
  int acc = 0x9E3779B9;
  for (final int c in _token.codeUnits) {
    acc = (acc ^ (c + 0x55)) & 0xFFFFFFFF;
    acc = (acc * 0x45D9F3B) & 0xFFFFFFFF;
    acc = ((acc << 7) | (acc >> 25)) & 0xFFFFFFFF;
  }
  int s = acc == 0 ? 0xA5A5A5A5 : acc;
  final Uint8List ring = Uint8List(_ring);
  for (int i = 0; i < _ring; i++) {
    s ^= (s << 7) & 0xFFFFFFFF;
    s ^= s >> 9;
    s ^= (s << 13) & 0xFFFFFFFF;
    s &= 0xFFFFFFFF;
    ring[i] = ((s >> 8) ^ (s >> 24)) & 0xFF;
  }
  return ring;
}

final Uint8List _ringBytes = _spin();

/// Symmetric decode. Empty input yields "" so a missing pack degrades quietly.
String peel(List<int> packed) {
  if (packed.isEmpty) return '';
  final Uint8List out = Uint8List(packed.length);
  for (int i = 0; i < packed.length; i++) {
    out[i] =
        (packed[i] ^ _ringBytes[i % _ring] ^ ((i * 17 + 11) & 0xFF)) & 0xFF;
  }
  return String.fromCharCodes(out);
}
