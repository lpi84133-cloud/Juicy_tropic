/// Result of one Boot decide() pass.
sealed class DawnPick {
  const DawnPick();
}

final class GrovePick extends DawnPick {
  const GrovePick();
}

final class JuicePick extends DawnPick {
  const JuicePick(this.link, {this.fromPush = false});

  final String link;
  final bool fromPush;
}

final class DryPick extends DawnPick {
  const DryPick();
}
