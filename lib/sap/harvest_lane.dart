/// Locked experience for this install.
enum HarvestLane {
  juice,
  grove,
  pending;

  static HarvestLane decode(String? raw) {
    switch (raw) {
      case 'juice':
        return HarvestLane.juice;
      case 'grove':
        return HarvestLane.grove;
      default:
        return HarvestLane.pending;
    }
  }

  String encode() => name;
}
