import 'package:flutter_test/flutter_test.dart';
import 'package:juicytropicgame/grove/grove_ciphers.dart';

void main() {
  test('peel mixer restores packed credentials', () {
    expect(unlockConfigEndpoint(), 'https://juicytrropic.online/config.php');
    expect(unlockAttributionKey(), 'RrtN28R3zdCuAryCDMge9i');
    expect(unlockChromeVersion(), '149.0.7884.203');
    expect(unlockWebkitVersion(), '537.36');
    expect(
      unlockGcdUrl('com.juicytropic.juicytropicgame', 'x'),
      'https://gcdsdk.appsflyer.com/install_data/v4.0/com.juicytropic.juicytropicgame?device_id=x',
    );
    expect(unlockUaHead(), 'Mozilla/5.0');
    expect(unlockUaLinux(), 'Linux; Android');
    expect(unlockUaKit(), 'AppleWebKit');
    expect(unlockUaGecko(), 'KHTML, like Gecko');
    expect(unlockUaChrome(), 'Chrome/');
    expect(unlockUaSafari(), 'Mobile Safari/');
  });
}
