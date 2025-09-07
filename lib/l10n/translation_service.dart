import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'app_en.dart';
import 'app_vi.dart';

class TranslationService extends Translations {
  static const Locale fallbackLocale = Locale('en', 'US');
  static const Locale defaultLocale = Locale('vi', 'VN');

  static final langs = ['English', 'Tiếng Việt'];

  static final locales = [
    const Locale('en', 'US'),
    const Locale('vi', 'VN'),
  ];

  static void changeLocale(String lang) {
    final locale = _getLocaleFromLanguage(lang);
    Get.updateLocale(locale);
  }

  static Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale ?? fallbackLocale;
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'vi_VN': viVN,
      };
}
