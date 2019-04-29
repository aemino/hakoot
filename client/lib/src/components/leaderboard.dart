import 'dart:html';

import '../models/player.dart';

class LeaderboardComponent {
  final List<Player> players;

  LeaderboardComponent(this.players);

  TableElement make() => TableElement()
    ..children = ([
      TableRowElement()..children = [
        Element.th()..text = '#',
        Element.th()..text = 'name',
        Element.th()..text = 'funds'
      ]
    ]..addAll(List.generate(
        players.length,
        (place) => TableRowElement()
          ..children = [
            Element.td()..text = '${place + 1}',
            Element.td()..text = players[place].displayName,
            Element.td()..text = players[place].funds.toString()
          ])));
}
