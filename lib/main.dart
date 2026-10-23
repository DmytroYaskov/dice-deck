import 'dart:math';

import 'package:flutter/material.dart';

import 'deck.dart';

void main() {
  runApp(const DiceDeckApp());
}

class DiceDeckApp extends StatelessWidget {
  const DiceDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Deck',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const DeckScreen(),
    );
  }
}

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen>
    with SingleTickerProviderStateMixin {
  final _deck = Deck();
  DiceCard? _current;
  // Stays on the table while the next card travels over from the pile.
  DiceCard? _previous;
  // Newest first. A null entry marks a reshuffle.
  final List<DiceCard?> _history = [];

  // One draw: the card flips over while it slides from the pile to the center.
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _markReshuffle() {
    if (_history.isNotEmpty && _history.first != null) _history.insert(0, null);
  }

  void _draw() {
    setState(() {
      // The deck reshuffles itself when drawn empty.
      if (_deck.remaining == 0) _markReshuffle();
      _previous = _current;
      _current = _deck.draw();
      _history.insert(0, _current);
    });
    _anim.forward(from: 0);
  }

  void _reshuffle() {
    setState(() {
      _deck.reshuffle();
      _markReshuffle();
      _current = null;
      _previous = null;
    });
    _anim.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _deck.remaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice Deck'),
        actions: [
          IconButton(
            onPressed: _reshuffle,
            tooltip: 'Reshuffle',
            icon: const Icon(Icons.shuffle),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: _history.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final card = _history[i];
              return card == null
                  ? const ReshuffleMarker()
                  : HistoryEntry(card: card);
            },
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LayoutBuilder(builder: (context, c) => _table(c.maxWidth)),
              const SizedBox(height: 24),
              Text(
                '$remaining / ${Deck.size} left',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (remaining == 0)
                const Text('Deck will reshuffle on next draw'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _draw,
                icon: const Icon(Icons.style),
                label: const Text('Draw'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Draw pile on the left, face-up card in the center. Both shrink together
  // when the width can't fit a full-size card beside a half-size pile.
  Widget _table(double width) {
    final scale = ((width - 64) / (_cardSize.width * 2)).clamp(0.3, 1.0);
    final cardSize = _cardSize * scale;
    final pileSize = cardSize * 0.5;
    final height = cardSize.height;
    final centerRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cardSize.width,
      height: cardSize.height,
    );
    final pileRect = Rect.fromLTWH(
      16,
      (height - pileSize.height) / 2,
      pileSize.width,
      pileSize.height,
    );

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final moving = _anim.value < 1;
          final t = Curves.easeInOut.transform(_anim.value);
          return Stack(
            children: [
              Positioned.fromRect(
                rect: pileRect,
                child: GestureDetector(
                  onTap: _draw,
                  child: FittedBox(child: DrawPile(remaining: _deck.remaining)),
                ),
              ),
              Positioned.fromRect(
                rect: centerRect,
                child: GestureDetector(
                  onTap: _draw,
                  child: FittedBox(
                    child: _faceOrEmpty(moving ? _previous : _current),
                  ),
                ),
              ),
              if (moving)
                Positioned.fromRect(
                  rect: Rect.lerp(pileRect, centerRect, t)!,
                  child: FittedBox(child: _flip(t)),
                ),
            ],
          );
        },
      ),
    );
  }

  // f runs 0→1: the back turns edge-on, then the face turns in.
  Widget _flip(double f) {
    final showFace = f >= 0.5;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(showFace ? (f - 1) * pi : f * pi),
      child: showFace ? _faceOrEmpty(_current) : const CardBack(),
    );
  }

  static Widget _faceOrEmpty(DiceCard? card) => card == null
      ? const EmptySlot(label: 'Tap the deck to draw')
      : CardFace(card: card);
}

const _cardSize = Size(220, 320);

class CardBack extends StatelessWidget {
  const CardBack({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary,
      elevation: 6,
      child: SizedBox.fromSize(
        size: _cardSize,
        child: Center(
          child: label == null
              ? Icon(Icons.casino, size: 96, color: scheme.onPrimary)
              : Text(
                  label!,
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(color: scheme.onPrimary),
                ),
        ),
      ),
    );
  }
}

/// An outlined placeholder the size of a card.
class EmptySlot extends StatelessWidget {
  const EmptySlot({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(4),
      width: _cardSize.width,
      height: _cardSize.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

/// The face-down stack, with the remaining count on top.
class DrawPile extends StatelessWidget {
  const DrawPile({super.key, required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    if (remaining == 0) return const EmptySlot(label: 'Empty');
    final layers = min(remaining, 3);
    return SizedBox(
      width: _cardSize.width + 8 * (layers - 1) + 8,
      height: _cardSize.height + 8 * (layers - 1) + 8,
      child: Stack(
        children: [
          for (var i = 0; i < layers; i++)
            Positioned(
              left: 8.0 * i,
              top: 8.0 * i,
              child: CardBack(label: i == layers - 1 ? '$remaining' : null),
            ),
        ],
      ),
    );
  }
}

class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card});

  final DiceCard card;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: SizedBox.fromSize(
        size: _cardSize,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DieFace(value: card.a),
                const SizedBox(width: 16),
                DieFace(value: card.b),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '${card.sum}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryEntry extends StatelessWidget {
  const HistoryEntry({super.key, required this.card});

  final DiceCard card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${card.sum}', style: textTheme.titleLarge),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DieFace(value: card.a, size: 22),
                const SizedBox(width: 4),
                DieFace(value: card.b, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReshuffleMarker extends StatelessWidget {
  const ReshuffleMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: 'Reshuffled',
      child: Row(
        children: [
          VerticalDivider(color: color, thickness: 2, width: 8),
          Icon(Icons.shuffle, color: color, size: 20),
          VerticalDivider(color: color, thickness: 2, width: 8),
        ],
      ),
    );
  }
}

/// A d6 face drawn as pips on a 3×3 grid.
class DieFace extends StatelessWidget {
  const DieFace({super.key, required this.value, this.size = 80});

  final int value;
  final double size;

  // Grid cells (row * 3 + col) that hold a pip for each value.
  static const _pips = {
    1: {4},
    2: {0, 8},
    3: {0, 4, 8},
    4: {0, 2, 6, 8},
    5: {0, 2, 4, 6, 8},
    6: {0, 2, 3, 5, 6, 8},
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pips = _pips[value]!;
    final pipSize = size / 5;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size / 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border.all(
          color: scheme.outline,
          width: (size / 40).clamp(1, 2),
        ),
        borderRadius: BorderRadius.circular(size / 6),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 9; i++)
            Center(
              child: pips.contains(i)
                  ? Container(
                      width: pipSize,
                      height: pipSize,
                      decoration: BoxDecoration(
                        color: scheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
