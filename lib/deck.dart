import 'dart:math';

/// One card: the faces of two d6 dice.
class DiceCard {
  const DiceCard(this.a, this.b);

  final int a;
  final int b;

  int get sum => a + b;
}

/// A deck of all 36 (d1, d2) combinations, so sums follow the exact 2d6
/// distribution. Reshuffles automatically when drawn empty.
class Deck {
  Deck({Random? random}) : _random = random ?? Random() {
    reshuffle();
  }

  static const size = 36;

  final Random _random;
  final List<DiceCard> _cards = [];

  int get remaining => _cards.length;

  void reshuffle() {
    _cards
      ..clear()
      ..addAll([
        for (var a = 1; a <= 6; a++)
          for (var b = 1; b <= 6; b++) DiceCard(a, b),
      ])
      ..shuffle(_random);
  }

  DiceCard draw() {
    if (_cards.isEmpty) reshuffle();
    return _cards.removeLast();
  }
}
