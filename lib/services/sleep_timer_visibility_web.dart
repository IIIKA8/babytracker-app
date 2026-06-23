import 'dart:html' as html;

void registerSleepVisibilityCallback(void Function() onVisible) {
  html.document.onVisibilityChange.listen((_) {
    if (html.document.visibilityState == 'visible') {
      onVisible();
    }
  });
}
