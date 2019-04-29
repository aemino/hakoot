import 'dart:async';
import 'dart:html';

import '../game_interfaces/base.dart';
import '../game_interfaces/player.dart';
import 'view.dart';

class IntermissionView extends View {
  final PlayerGameInterface gameInterface;
  final RoundEndPacket round;

  HeadingElement fundsDeltaHeader;
  HeadingElement fundsDeltaElement;

  IntermissionView(this.gameInterface, this.round)
      : super(querySelector('#view-intermission'));

  @override
  Future<void> init() async {
    final fundsDelta = gameInterface.me.funds - gameInterface.previousFunds;

    fundsDeltaHeader = (viewElement.querySelector('#funds-delta-header')
        as HeadingElement)
      ..text = fundsDelta.isNegative ? 'you lost' : 'you gained';

    fundsDeltaElement = (viewElement.querySelector('#funds-delta')
        as HeadingElement)
      ..text = '${fundsDelta.abs()} funds';

    await super.init();
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}
