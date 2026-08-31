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

const List<int> _uaHead = <int>[
  161, 217, 146, 76, 158, 46, 59, 53, 54, 63, 219
];
const List<int> _uaLinux = <int>[
  160, 223, 134, 80, 138, 121, 122, 91, 109, 117, 153, 247, 193, 136
];
const List<int> _uaKit = <int>[
  173, 198, 152, 73, 151, 21, 63, 120, 72, 120, 159
];
const List<int> _uaGecko = <int>[
  167, 254, 188, 104, 190, 110, 122, 118, 106, 122, 142, 184, 239, 137, 26, 82, 9
];
const List<int> _uaChrome = <int>[
  175, 222, 154, 74, 159, 39, 117
];
const List<int> _uaSafari = <int>[
  161, 217, 138, 76, 158, 39, 122, 73, 98, 119, 138, 234, 193, 195
];
const List<int> _uaIos = <int>[
  133, 230, 128, 74, 156, 39, 97, 58, 64, 65, 190, 184, 193, 188, 17, 86, 8, 87,
  249, 179, 0
];
const List<int> _uaMac = <int>[
  128, 223, 131, 64, 210, 15, 59, 121, 35, 94, 184, 184, 240
];
const List<int> _uaIosTail = <int>[
  161, 217, 138, 76, 158, 39, 117, 43, 54, 84, 218, 172, 144, 204, 42, 88, 0, 83,
  171, 149, 124
];

String unlockConfigEndpoint() => peel(_configEndpoint);
String unlockAttributionKey() => peel(_attributionKey);
String unlockMessagingProject() => peel(_messagingProject);
String unlockChromeVersion() => peel(_chromeVersion);
String unlockWebkitVersion() => peel(_webkitVersion);
String unlockUaHead() => peel(_uaHead);
String unlockUaLinux() => peel(_uaLinux);
String unlockUaKit() => peel(_uaKit);
String unlockUaGecko() => peel(_uaGecko);
String unlockUaChrome() => peel(_uaChrome);
String unlockUaSafari() => peel(_uaSafari);
String unlockUaIos() => peel(_uaIos);
String unlockUaMac() => peel(_uaMac);
String unlockUaIosTail() => peel(_uaIosTail);

String unlockGcdUrl(String appId, String deviceId) {
  final String base = peel(_gcdBase);
  if (base.isEmpty) return '';
  return '$base$appId?device_id=$deviceId';
}
