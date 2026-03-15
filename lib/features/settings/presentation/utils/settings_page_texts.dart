import 'package:flutter/widgets.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';

class SettingsPageTexts {
  static bool _isRu(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ru';

  static bool _isUk(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'uk';

  static String pageSubtitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Управляйте источником, адресами и подключением в одном месте.';
    }
    if (_isUk(context)) {
      return 'Керуйте джерелом, адресами та підключенням в одному місці.';
    }
    return 'Manage sources, addresses, and connection settings in one place.';
  }

  static String autosaveIdle(BuildContext context) {
    if (_isRu(context)) {
      return 'Автосохранение включено';
    }
    if (_isUk(context)) {
      return 'Автозбереження увімкнено';
    }
    return 'Autosave is on';
  }

  static String autosaveSaving(BuildContext context) {
    if (_isRu(context)) {
      return 'Сохраняем';
    }
    if (_isUk(context)) {
      return 'Зберігаємо';
    }
    return 'Saving';
  }

  static String autosaveSaved(BuildContext context) {
    if (_isRu(context)) {
      return 'Сохранено';
    }
    if (_isUk(context)) {
      return 'Збережено';
    }
    return 'Saved';
  }

  static String autosaveError(BuildContext context) {
    if (_isRu(context)) {
      return 'Не удалось сохранить';
    }
    if (_isUk(context)) {
      return 'Не вдалося зберегти';
    }
    return 'Could not save';
  }

  static String generalTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Общие настройки';
    }
    if (_isUk(context)) {
      return 'Загальні налаштування';
    }
    return 'General settings';
  }

  static String generalBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Выберите источник и количество изображений для загрузки.';
    }
    if (_isUk(context)) {
      return 'Виберіть джерело та кількість зображень для завантаження.';
    }
    return 'Choose the source and number of images to download.';
  }

  static String sourceTitle(BuildContext context, DownloadSource source) {
    if (_isRu(context)) {
      return source == DownloadSource.lightshot
          ? 'Параметры Lightshot'
          : 'Параметры Imgur';
    }
    if (_isUk(context)) {
      return source == DownloadSource.lightshot
          ? 'Параметри Lightshot'
          : 'Параметри Imgur';
    }
    return source == DownloadSource.lightshot
        ? 'Lightshot settings'
        : 'Imgur settings';
  }

  static String sourceBody(BuildContext context, DownloadSource source) {
    if (_isRu(context)) {
      return source == DownloadSource.lightshot
          ? 'Настройте формат адресов и стартовую точку для поиска.'
          : 'Настройте длину ID и стартовую точку для поиска.';
    }
    if (_isUk(context)) {
      return source == DownloadSource.lightshot
          ? 'Налаштуйте формат адрес і стартову точку для пошуку.'
          : 'Налаштуйте довжину ID і стартову точку для пошуку.';
    }
    return source == DownloadSource.lightshot
        ? 'Configure address format and a starting point for search.'
        : 'Configure ID length and a starting point for search.';
  }

  static String proxyTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Прокси';
    }
    if (_isUk(context)) {
      return 'Проксі';
    }
    return 'Proxy';
  }

  static String proxyBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Используйте прокси и авторизацию только если это действительно нужно.';
    }
    if (_isUk(context)) {
      return 'Використовуйте проксі та авторизацію лише за потреби.';
    }
    return 'Use proxy and authentication only when they are actually needed.';
  }

  static String maintenanceTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Обслуживание';
    }
    if (_isUk(context)) {
      return 'Обслуговування';
    }
    return 'Maintenance';
  }

  static String maintenanceBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Сервисные действия для локальной базы и сохранённых изображений.';
    }
    if (_isUk(context)) {
      return 'Сервісні дії для локальної бази та збережених зображень.';
    }
    return 'Service actions for the local index and saved images.';
  }

  static String randomHint(BuildContext context) {
    if (_isRu(context)) {
      return 'Стартовая точка не требуется, если выбран случайный поиск.';
    }
    if (_isUk(context)) {
      return 'Стартова точка не потрібна, якщо вибрано випадковий пошук.';
    }
    return 'A starting point is not needed when random search is enabled.';
  }

  static String confirmRebuildTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Пересоздать базу?';
    }
    if (_isUk(context)) {
      return 'Перебудувати базу?';
    }
    return 'Rebuild database?';
  }

  static String confirmRebuildBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Приложение заново создаст индекс изображений, сохранённых на устройстве.';
    }
    if (_isUk(context)) {
      return 'Застосунок заново створить індекс зображень, збережених на пристрої.';
    }
    return 'The app will rebuild the index of images already saved on the device.';
  }

  static String confirmClearTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Удалить все изображения?';
    }
    if (_isUk(context)) {
      return 'Видалити всі зображення?';
    }
    return 'Delete all images?';
  }

  static String confirmClearBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Все сохранённые изображения и локальный индекс будут удалены.';
    }
    if (_isUk(context)) {
      return 'Усі збережені зображення та локальний індекс буде видалено.';
    }
    return 'All saved images and the local index will be removed.';
  }
}
