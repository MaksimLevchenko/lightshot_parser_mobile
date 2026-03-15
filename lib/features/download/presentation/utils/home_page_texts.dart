import 'package:flutter/widgets.dart';

class HomePageTexts {
  static bool _isRu(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ru';

  static bool _isUk(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'uk';

  static String subtitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Запускайте загрузку, следите за прогрессом и открывайте последние изображения без лишних жестов.';
    }
    if (_isUk(context)) {
      return 'Запускайте завантаження, стежте за прогресом і відкривайте останні зображення без зайвих жестів.';
    }
    return 'Start downloads, track progress, and open recent images without relying on gestures.';
  }

  static String targetCountLabel(BuildContext context) {
    if (_isRu(context)) {
      return 'Цель';
    }
    if (_isUk(context)) {
      return 'Ціль';
    }
    return 'Target';
  }

  static String proxyStatusLabel(BuildContext context) {
    if (_isRu(context)) {
      return 'Прокси';
    }
    if (_isUk(context)) {
      return 'Проксі';
    }
    return 'Proxy';
  }

  static String proxyEnabled(BuildContext context) {
    if (_isRu(context)) {
      return 'Включен';
    }
    if (_isUk(context)) {
      return 'Увімкнено';
    }
    return 'Enabled';
  }

  static String proxyDisabled(BuildContext context) {
    if (_isRu(context)) {
      return 'Выключен';
    }
    if (_isUk(context)) {
      return 'Вимкнено';
    }
    return 'Disabled';
  }

  static String quickActionsTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Быстрые действия';
    }
    if (_isUk(context)) {
      return 'Швидкі дії';
    }
    return 'Quick actions';
  }

  static String quickActionsBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Главные действия собраны здесь, чтобы стартовый экран оставался удобным и на телефоне, и на Windows.';
    }
    if (_isUk(context)) {
      return 'Головні дії зібрано тут, щоб стартовий екран залишався зручним і на телефоні, і на Windows.';
    }
    return 'The main actions live here so the startup screen stays clear on both phones and Windows.';
  }

  static String downloadStatusTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Состояние загрузки';
    }
    if (_isUk(context)) {
      return 'Стан завантаження';
    }
    return 'Download status';
  }

  static String statusReady(BuildContext context) {
    if (_isRu(context)) {
      return 'Готово к запуску';
    }
    if (_isUk(context)) {
      return 'Готово до запуску';
    }
    return 'Ready to start';
  }

  static String statusDownloading(BuildContext context) {
    if (_isRu(context)) {
      return 'Идёт загрузка';
    }
    if (_isUk(context)) {
      return 'Триває завантаження';
    }
    return 'Downloading now';
  }

  static String statusCompleted(BuildContext context) {
    if (_isRu(context)) {
      return 'Загрузка завершена';
    }
    if (_isUk(context)) {
      return 'Завантаження завершено';
    }
    return 'Download completed';
  }

  static String statusCancelled(BuildContext context) {
    if (_isRu(context)) {
      return 'Загрузка остановлена';
    }
    if (_isUk(context)) {
      return 'Завантаження зупинено';
    }
    return 'Download cancelled';
  }

  static String statusFailed(BuildContext context) {
    if (_isRu(context)) {
      return 'Ошибка загрузки';
    }
    if (_isUk(context)) {
      return 'Помилка завантаження';
    }
    return 'Download failed';
  }

  static String currentSetupTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Текущая конфигурация';
    }
    if (_isUk(context)) {
      return 'Поточна конфігурація';
    }
    return 'Current setup';
  }

  static String startPointLabel(BuildContext context) {
    if (_isRu(context)) {
      return 'Старт';
    }
    if (_isUk(context)) {
      return 'Старт';
    }
    return 'Start point';
  }

  static String randomStart(BuildContext context) {
    if (_isRu(context)) {
      return 'Случайный старт';
    }
    if (_isUk(context)) {
      return 'Випадковий старт';
    }
    return 'Random start';
  }

  static String recentGalleryTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Последние изображения';
    }
    if (_isUk(context)) {
      return 'Останні зображення';
    }
    return 'Recent images';
  }

  static String recentGalleryBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Последние сохранённые изображения доступны прямо со стартового экрана.';
    }
    if (_isUk(context)) {
      return 'Останні збережені зображення доступні прямо зі стартового екрана.';
    }
    return 'Your latest saved images stay available directly from the startup screen.';
  }

  static String emptyGalleryTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Галерея пока пуста';
    }
    if (_isUk(context)) {
      return 'Галерея поки порожня';
    }
    return 'The gallery is still empty';
  }

  static String emptyGalleryBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Настройте источник и начните загрузку, чтобы здесь появились первые изображения.';
    }
    if (_isUk(context)) {
      return 'Налаштуйте джерело і почніть завантаження, щоб тут з’явилися перші зображення.';
    }
    return 'Configure your source and start a download to see your first images here.';
  }

  static String configureDownload(BuildContext context) {
    if (_isRu(context)) {
      return 'Настроить загрузку';
    }
    if (_isUk(context)) {
      return 'Налаштувати завантаження';
    }
    return 'Configure download';
  }

  static String openImage(BuildContext context) {
    if (_isRu(context)) {
      return 'Открыть';
    }
    if (_isUk(context)) {
      return 'Відкрити';
    }
    return 'Open';
  }

  static String loadingGallery(BuildContext context) {
    if (_isRu(context)) {
      return 'Подготавливаем галерею';
    }
    if (_isUk(context)) {
      return 'Підготовка галереї';
    }
    return 'Preparing gallery';
  }

  static String openGalleryHint(BuildContext context) {
    if (_isRu(context)) {
      return 'Открыть всю галерею';
    }
    if (_isUk(context)) {
      return 'Відкрити всю галерею';
    }
    return 'Open full gallery';
  }
}
