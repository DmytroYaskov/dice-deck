import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dice_deck/deck.dart';

const _expected = {
  2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6, 8: 5, 9: 4, 10: 3, 11: 2, 12: 1, //
};

void main() {
  test('fresh deck has 36 cards', () {
    expect(Deck().remaining, 36);
  });

  test('a full pass matches the 2d6 distribution', () {
    final deck = Deck(random: Random(1));
    final counts = <int, int>{};
    for (var i = 0; i < Deck.size; i++) {
      final sum = deck.draw().sum;
      counts[sum] = (counts[sum] ?? 0) + 1;
    }
    expect(counts, _expected);
    expect(deck.remaining, 0);
  });

  test('drawing from an empty deck reshuffles', () {
    final deck = Deck();
    for (var i = 0; i < Deck.size; i++) {
      deck.draw();
    }
    deck.draw();
    expect(deck.remaining, 35);
  });
}
