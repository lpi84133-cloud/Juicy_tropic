import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../canopy/dew_sense.dart';
import '../canopy/fruit_bell.dart';
import '../canopy/grove_cache.dart';
import '../canopy/grove_mask.dart';
import '../grove/grove_mark.dart';
import 'drought_pane.dart';

class JuicePane extends StatefulWidget {
  const JuicePane({
    super.key,
    required this.link,
    required this.cache,
    required this.bell,
    required this.dew,
    this.fromPush = false,
  });

  final String link;
  final GroveCache cache;
  final FruitBell bell;
  final DewSense dew;
  final bool fromPush;

  @override
  State<JuicePane> createState() => _JuicePaneState();
}

class _JuicePaneState extends State<JuicePane> with WidgetsBindingObserver {
  late final WebViewController _web;
  bool _spin = true;
  bool _dryShown = false;
  String? _lastFrame;
  int _loopTries = 0;
  bool _httpsRetry = false;
  bool _coldReloaded = false;
  Timer? _dryHold;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  static const MethodChannel _picker = MethodChannel('orchard/media_pick');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _immerse();
    _wire();

    widget.bell.onLink = (String link) {
      if (mounted) _openPane(link);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainOnce());

    _sub = widget.dew.changes.listen((List<ConnectivityResult> r) async {
      final bool allNone = r.isNotEmpty &&
          r.every((ConnectivityResult e) => e == ConnectivityResult.none);
      if (!allNone && await widget.dew.isReachable()) {
        _dryHold?.cancel();
        return;
      }
      _dryHold?.cancel();
      _dryHold = Timer(const Duration(milliseconds: 700), _openDry);
    });
  }

  void _immerse() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _immerse();
  }

  void _wire() {
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(groveHttp.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _spin = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _spin = false);
          _loopTries = 0;
          _patchRim();
          _liftFields();
          if (widget.fromPush && !_coldReloaded) {
            _coldReloaded = true;
            _web.reload();
          }
        },
        onWebResourceError: (WebResourceError err) {
          if (err.isForMainFrame != true) return;
          final String d = err.description.toLowerCase();
          if (_retryHttps(d)) return;
          final bool loop = d.contains('too_many_redirects') ||
              d.contains('too many redirects') ||
              err.errorCode == -1007 ||
              err.errorCode == -9;
          if (loop && _lastFrame != null && _loopTries < 3) {
            _loopTries++;
            _web.loadRequest(Uri.parse(_lastFrame!));
            return;
          }
          if (mounted) setState(() => _spin = true);
          final bool dns = d.contains('name_not_resolved') ||
              d.contains('err_name_not_resolved') ||
              d.contains('internet_disconnected') ||
              d.contains('network_changed') ||
              err.errorCode == -105 ||
              err.errorCode == -106 ||
              err.errorCode == -21;
          if (dns) {
            _openDry();
          } else {
            _probeDry();
          }
        },
        onNavigationRequest: (NavigationRequest req) {
          final Uri? uri = Uri.tryParse(req.url);
          if (uri == null) return NavigationDecision.prevent;
          const Set<String> inside = <String>{
            'http',
            'https',
            'about',
            'data',
            'blob',
          };
          if (inside.contains(uri.scheme)) {
            if (req.isMainFrame) _lastFrame = req.url;
            return NavigationDecision.navigate;
          }
          _handOff(uri);
          return NavigationDecision.prevent;
        },
      ));

    _tuneAndroid();
    if (widget.fromPush) {
      Future<void>.delayed(const Duration(milliseconds: 210), () {
        if (mounted) _openPane(widget.link);
      });
    } else {
      _openPane(widget.link);
    }
  }

  void _openPane(String raw) {
    if (!GroveMark.isWebLink(raw)) return;
    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null) return;
    _lastFrame = uri.toString();
    _web.loadRequest(uri);
  }

  Future<void> _drainOnce() async {
    final String? queued = await widget.cache.takePending();
    if (!mounted || queued == null) return;
    _openPane(queued);
  }

  void _tuneAndroid() {
    if (!Platform.isAndroid) return;
    if (_web.platform is! AndroidWebViewController) return;
    final AndroidWebViewController a =
        _web.platform as AndroidWebViewController;

    a.setMediaPlaybackRequiresUserGesture(false);
    a.setOnPlatformPermissionRequest(
      (PlatformWebViewPermissionRequest req) => req.grant(),
    );
    a.setOnShowFileSelector(_pickFiles);

    final AndroidWebViewCookieManager cookies = AndroidWebViewCookieManager(
      AndroidWebViewCookieManagerCreationParams
          .fromPlatformWebViewCookieManagerCreationParams(
        const PlatformWebViewCookieManagerCreationParams(),
      ),
    );
    cookies.setAcceptThirdPartyCookies(a, true);
  }

  Future<List<String>> _pickFiles(FileSelectorParams params) async {
    try {
      final List<Object?>? picked =
          await _picker.invokeMethod<List<Object?>>('open', <String, Object>{
        'many': params.mode == FileSelectorMode.openMultiple,
      });
      if (picked == null) return const <String>[];
      return picked.whereType<String>().toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _handOff(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  bool _retryHttps(String description) {
    final bool cleartext = description.contains('cleartext') ||
        description.contains('err_cleartext_not_permitted');
    if (!cleartext) return false;
    if (mounted) setState(() => _spin = true);
    final String raw = _lastFrame ?? widget.link;
    final Uri? uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'http' && !_httpsRetry) {
      _httpsRetry = true;
      final Uri next = uri.replace(scheme: 'https');
      _lastFrame = next.toString();
      _web.loadRequest(next);
    }
    return true;
  }

  Future<void> _probeDry() async {
    if (_dryShown) return;
    final bool online = await widget.dew.isReachable();
    if (online) {
      if (mounted) setState(() => _spin = false);
      return;
    }
    _openDry();
  }

  void _openDry() {
    if (_dryShown || !mounted) return;
    _dryShown = true;
    final String current = _lastFrame ?? widget.link;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DroughtPane(
          onRetryBuild: (_) => JuicePane(
            link: current,
            cache: widget.cache,
            bell: widget.bell,
            dew: widget.dew,
            fromPush: widget.fromPush,
          ),
        ),
      ),
    );
  }

  void _liftFields() {
    _web.runJavaScript(r'''
(function(){
  if (window.__jxKbShim) return; window.__jxKbShim = true;
  function field(el){return el&&(el.tagName==='INPUT'||el.tagName==='TEXTAREA'||el.isContentEditable);}
  function lift(){
    var el=document.activeElement; if(!field(el))return;
    var vp=window.visualViewport;
    if(vp){
      var r=el.getBoundingClientRect(); var floor=vp.offsetTop+vp.height;
      if(r.bottom>floor-20||r.top<vp.offsetTop){el.scrollIntoView({behavior:'auto',block:'nearest'});}
    } else { el.scrollIntoView({behavior:'auto',block:'nearest'}); }
  }
  document.addEventListener('focusin',function(e){ if(field(e.target)) setTimeout(lift,350); });
  if(window.visualViewport){
    var prev=window.visualViewport.height;
    window.visualViewport.addEventListener('resize',function(){
      var h=window.visualViewport.height; if(h<prev) setTimeout(lift,120); prev=h;
    });
  }
})();
''');
  }

  void _patchRim() {
    _web.runJavaScript(r'''
(function(){
  if(window.__jxRimPatch) return; window.__jxRimPatch=true;
  var ID='jx-rim-sheet';
  var CSS=':root{--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;'
    +'--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;'
    +'--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;'
    +'--safe-top:0px!important;--safe-bottom:0px!important;--safe-left:0px!important;--safe-right:0px!important;}'
    +'.gameview-mobile-header,.app-header,.js-safe-top{padding-top:0!important;margin-top:0!important;}';
  function kbOpen(){ if(!window.visualViewport)return false; return window.visualViewport.height<window.innerHeight*0.75; }
  function apply(){
    if(kbOpen())return;
    var head=document.head||document.documentElement; if(!head)return;
    var m=document.querySelector('meta[name="viewport"]');
    if(m && !/viewport-fit\s*=\s*contain/i.test(m.getAttribute('content')||'')){
      var c=(m.getAttribute('content')||'').replace(/,?\s*viewport-fit\s*=\s*\w+/ig,'').trim();
      m.setAttribute('content', c+(c?', ':'')+'viewport-fit=contain');
    }
    var s=document.getElementById(ID);
    if(!s){ s=document.createElement('style'); s.id=ID; head.appendChild(s); }
    if(s.textContent!==CSS) s.textContent=CSS;
  }
  apply();
  ['pushState','replaceState'].forEach(function(fn){
    var o=history[fn]; history[fn]=function(){var r=o.apply(this,arguments); setTimeout(apply,80); setTimeout(apply,400); return r;};
  });
  window.addEventListener('popstate',function(){setTimeout(apply,80);});
  setInterval(apply,2500);
})();
''');
  }

  Future<void> _back() async {
    if (await _web.canGoBack()) {
      await _web.goBack();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dryHold?.cancel();
    _sub?.cancel();
    widget.bell.onLink = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (!didPop) await _back();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            SafeArea(
              bottom: false,
              child: WebViewWidget(controller: _web),
            ),
            if (_spin)
              const ColoredBox(
                color: Color(0x80000000),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFC7F94F)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
