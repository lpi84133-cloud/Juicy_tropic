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
    return GroveVerdict(
      allowed: map['ok'] as bool? ?? false,
      link: map['url'] as String?,
      note: map['message'] as String?,
      ttl: map['expires'] as int?,
    );
  }

  factory GroveVerdict.denied(String note) =>
      GroveVerdict(allowed: false, note: note);

  factory GroveVerdict.dropped(String note) =>
      GroveVerdict(allowed: false, note: note, transport: true);

  bool get hasLink => link != null && link!.isNotEmpty;
}
