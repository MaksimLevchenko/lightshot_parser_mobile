import 'package:flutter/widgets.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class HomePageTexts {
  static bool _isRu(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ru';

  static bool _isUk(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'uk';

  static String subtitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Запускайте загрузку и открывайте последние сохранённые изображения.';
    }
    if (_isUk(context)) {
      return 'Запускайте завантаження та відкривайте останні збережені зображення.';
    }
    return 'Start downloads and open your latest saved images.';
  }

  static String targetCountLabel(BuildContext context) {
    return S.of(context).numberOfImagesToDownload;
  }

  static String proxyStatusLabel(BuildContext context) {
    return S.of(context).useProxy;
  }

  static String proxyEnabled(BuildContext context) {
    return S.of(context).useProxy;
  }

  static String proxyDisabled(BuildContext context) {
    return '';
  }

  static String quickActionsTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Действия';
    }
    if (_isUk(context)) {
      return 'Дії';
    }
    return 'Actions';
  }

  static String quickActionsBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Запустите загрузку, откройте настройки или перейдите в галерею.';
    }
    if (_isUk(context)) {
      return 'Запустіть завантаження, відкрийте налаштування або перейдіть до галереї.';
    }
    return 'Start a download, open settings, or go to the gallery.';
  }

  static String downloadStatusTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Ход загрузки';
    }
    if (_isUk(context)) {
      return 'Хід завантаження';
    }
    return 'Download progress';
  }

  static String statusReady(BuildContext context) {
    if (_isRu(context)) {
      return 'Готово';
    }
    if (_isUk(context)) {
      return 'Готово';
    }
    return 'Ready';
  }

  static String statusDownloading(BuildContext context) {
    return S.of(context).downloadingImages;
  }

  static String statusCompleted(BuildContext context) {
    return S.of(context).downloadingComplete;
  }

  static String statusCancelled(BuildContext context) {
    if (_isRu(context)) {
      return 'Загрузка остановлена';
    }
    if (_isUk(context)) {
      return 'Завантаження зупинено';
    }
    return 'Download stopped';
  }

  static String statusFailed(BuildContext context) {
    if (_isRu(context)) {
      return 'Ошибка загрузки';
    }
    if (_isUk(context)) {
      return 'Помилка завантаження';
    }
    return 'Download error';
  }

  static String currentSetupTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Параметры загрузки';
    }
    if (_isUk(context)) {
      return 'Параметри завантаження';
    }
    return 'Download settings';
  }

  static String startPointLabel(BuildContext context) {
    return S.of(context).startingAddress;
  }

  static String randomStart(BuildContext context) => '';

  static String recentGalleryTitle(BuildContext context) {
    if (_isRu(context)) {
      return 'Галерея';
    }
    if (_isUk(context)) {
      return 'Галерея';
    }
    return 'Gallery';
  }

  static String recentGalleryBody(BuildContext context) {
    if (_isRu(context)) {
      return 'Последние изображения, сохранённые на этом устройстве.';
    }
    if (_isUk(context)) {
      return 'Останні зображення, збережені на цьому пристрої.';
    }
    return 'Recently saved images on this device.';
  }

  static String emptyGalleryTitle(BuildContext context) {
    return S.of(context).noPhotos;
  }

  static String emptyGalleryBody(BuildContext context) {
    if (_isRu(context)) {
      return 'После первой успешной загрузки изображения появятся в этой галерее.';
    }
    if (_isUk(context)) {
      return 'Після першого успішного завантаження зображення з’являться в цій галереї.';
    }
    return 'Images will appear in this gallery after the first successful download.';
  }

  static String configureDownload(BuildContext context) {
    return S.of(context).settings;
  }

  static String openImage(BuildContext context) {
    return S.of(context).photoViewer;
  }

  static String loadingGallery(BuildContext context) {
    if (_isRu(context)) {
      return 'Загружаем галерею';
    }
    if (_isUk(context)) {
      return 'Завантажуємо галерею';
    }
    return 'Loading gallery';
  }

  static String openGalleryHint(BuildContext context) {
    return S.of(context).galleryAppBar;
  }
}
