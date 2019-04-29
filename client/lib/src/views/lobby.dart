import 'dart:async';
import 'dart:html';

import '../models/player.dart';
import 'view.dart';

class LobbyView extends View {
  final Player me;

  LobbyView(this.me) : super(querySelector('#view-lobby'));

  @override
  Future<void> init() async {
    viewElement.querySelector('#display-name').text = me.displayName;

    await super.init();
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}
