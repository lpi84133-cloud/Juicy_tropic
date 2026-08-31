import '../rind/peel_mixer.dart';

const List<int> _configEndpoint = <int>[
  132, 194, 156, 85, 129, 120, 117, 53, 105, 100, 130, 251, 209, 152, 11, 75,
  9, 66, 176, 159, 125, 69, 178, 200, 88, 189, 144, 64, 148, 227, 137, 86,
  28, 6, 64, 67, 152, 98
];

const List<int> _gcdBase = <int>[
  132, 194, 156, 85, 129, 120, 117, 53, 100, 114, 143, 235, 204, 135, 87, 88,
  22, 66, 170, 154, 63, 83, 185, 214, 31, 176, 154, 2, 216, 229, 137, 67, 1,
  0, 2, 95, 175, 118, 198, 72, 217, 12, 9, 23, 194, 133, 20
];

const List<int> _chromeVersion = <int>[
  221, 130, 209, 11, 194, 108, 109, 34, 59, 37, 197, 170, 152, 223
];

const List<int> _webkitVersion = <int>[217, 133, 223, 11, 193, 116];

const List<int> _attributionKey = <int>[
  190, 196, 156, 107, 192, 122, 8, 41, 121, 117, 168, 237, 233, 158, 0, 122,
  34, 127, 190, 153, 106, 67
];

const List<int> _messagingProject = <int>[
  218, 128, 219, 22, 202, 116, 105, 43, 52, 33, 223, 169
];

String unlockConfigEndpoint() => peel(_configEndpoint);
String unlockAttributionKey() => peel(_attributionKey);
String unlockMessagingProject() => peel(_messagingProject);
String unlockChromeVersion() => peel(_chromeVersion);
String unlockWebkitVersion() => peel(_webkitVersion);

String unlockGcdUrl(String appId, String deviceId) {
  final String base = peel(_gcdBase);
  if (base.isEmpty) return '';
  return '$base$appId?device_id=$deviceId';
}
