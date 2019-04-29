import 'dart:html';

abstract class View {
  final Element viewElement;

  static Element createViewElement(Element templateViewElement) {
    final parent = templateViewElement.parent;
    final viewElement = templateViewElement.clone(true) as Element
      ..id = 'current-view'
      ..classes.remove('template');
    parent.append(viewElement);

    return viewElement;
  }

  Future<void> init() async {
    viewElement.classes.add('active');
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> dispose() async {
    viewElement.classes.remove('active');
    await Future.delayed(Duration(seconds: 1));
    viewElement.remove();
  }

  View(Element element) : viewElement = createViewElement(element);

  Future<void> transientClasses(
      Element element, List<String> classNames, Duration duration) async {
    element.classes.addAll(classNames);
    await Future.delayed(duration);
    element.classes.removeAll(classNames);
  }
}
