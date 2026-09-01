/// Wire `{ ok, url, expires, message }` from the remote gate.
class GroveVerdict {
  const GroveVerdict({
    required this.allowed,
    this.link,
    this.note,
    this.ttl,
    this.transport = false,
  });

  final bool allowed;
  final String? link;
  final String? note;
  final int? ttl;

  /// True when the socket/DNS/timeout failed — lane must stay pending.
  final bool transport;

  factory GroveVerdict.fromMap(Map<String, dynamic> map) {
    final Object? rawOk = map['ok'];
    final bool allowed = rawOk == true ||
        rawOk == 1 ||
        rawOk == '1' ||
        rawOk == 'true';
    final Object? rawUrl = map['url'] ?? map['link'] ?? map['href'];
    final String? link = rawUrl is String
        ? rawUrl.trim()
        : rawUrl?.toString().trim();
    final Object? rawTtl = map['expires'] ?? map['ttl'];
    int? ttl;
    if (rawTtl is int) {
      ttl = rawTtl;
    } else if (rawTtl is num) {
      ttl = rawTtl.toInt();
    } else if (rawTtl is String) {
      ttl = int.tryParse(rawTtl);
    }
    return GroveVerdict(
      allowed: allowed,
      link: (link == null || link.isEmpty) ? null : link,
      note: map['message']?.toString(),
      ttl: ttl,
    );
  }

  factory GroveVerdict.denied(String note) =>
      GroveVerdict(allowed: false, note: note);

  factory GroveVerdict.dropped(String note) =>
      GroveVerdict(allowed: false, note: note, transport: true);

  bool get hasLink => link != null && link!.isNotEmpty;
}
