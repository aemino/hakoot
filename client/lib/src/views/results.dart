import 'dart:async';
import 'dart:html';

import '../game_interfaces/base.dart';
import '../game_interfaces/player.dart';
import '../utils.dart';
import 'view.dart';

class ResultsView extends View {
  final PlayerGameInterface gameInterface;

  HeadingElement placeElement;

  ResultsView(this.gameInterface) : super(querySelector('#view-results'));

  @override
  Future<void> init() async {
    final playersByFunds = gameInterface.playerFunds.entries.toList()
      ..sort((a, b) => b.value - a.value);

    final myPlace =
        playersByFunds.indexWhere((entry) => entry.key == gameInterface.me.id) +
            1;

    placeElement = (viewElement.querySelector('#place') as HeadingElement)
      ..text = '$myPlace${ordinalSuffix(myPlace)} place';

    await super.init();
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}
