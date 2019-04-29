import 'dart:async';

class EventStream<T> extends Stream<T> with StreamController<T> {
  final StreamController<T> _controller;

  @override
  Stream<T> get stream => _controller.stream;

  EventStream() : _controller = StreamController.broadcast();

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
          {Function onError, void Function() onDone, bool cancelOnError}) =>
      stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  ControllerCancelCallback get onCancel => _controller.onCancel;

  @override
  ControllerCallback get onListen => _controller.onListen;

  @override
  ControllerCallback get onPause => _controller.onPause;

  @override
  ControllerCallback get onResume => _controller.onResume;

  @override
  void add(T event) => _controller.add(event);

  @override
  void addError(Object error, [StackTrace stackTrace]) =>
      _controller.addError(error, stackTrace);

  @override
  Future addStream(Stream<T> source, {bool cancelOnError}) =>
      _controller.addStream(source, cancelOnError: cancelOnError);

  @override
  Future close() => _controller.close();

  @override
  Future get done => _controller.done;

  @override
  bool get hasListener => _controller.hasListener;

  @override
  bool get isClosed => _controller.isClosed;

  @override
  bool get isPaused => _controller.isPaused;

  @override
  StreamSink<T> get sink => _controller.sink;

  @override
  set onCancel(Function() onCancelHandler) =>
      _controller.onCancel = onCancelHandler;

  @override
  set onListen(void Function() onListenHandler) =>
      _controller.onListen = onListenHandler;

  @override
  set onPause(void Function() onPauseHandler) =>
      _controller.onPause = onPauseHandler;

  @override
  set onResume(void Function() onResumeHandler) =>
      _controller.onResume = onResumeHandler;

  Stream<T> buffered() {
    final controller = StreamController<T>();
    stream.pipe(controller);

    return controller.stream;
  }
}
