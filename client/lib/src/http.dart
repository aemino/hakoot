import 'dart:html';

import 'package:http/browser_client.dart';

UriWrapper baseUrl() => UriWrapper(Uri.parse(document.baseUri))..setPort(8081);
UriWrapper apiUrl() => baseUrl()..appendPath('/api');
UriWrapper wsUrl() => baseUrl()..setScheme('ws');

final client = BrowserClient();

class UriWrapper {
  Uri uri;

  UriWrapper(this.uri);

  UriWrapper clone() => UriWrapper(uri.replace());
  Uri toUri() => uri;

  void appendPath(String path) {
    uri = uri.replace(
        pathSegments: uri.pathSegments.toList()
          ..addAll(path.split('/').where((segment) => segment.isNotEmpty)));
  }

  void setScheme(String scheme) {
    uri = uri.replace(scheme: scheme);
  }

  void setPort(int port) {
    uri = uri.replace(port: port);
  }
}
