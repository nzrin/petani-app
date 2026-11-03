import 'package:flutter/services.dart';

class AppIconService {
  const AppIconService();

  static const _channel = MethodChannel('com.nazrinapp.petani/app_icon');

  Future<String> getCurrentIcon() async {
    try {
      return await _channel.invokeMethod<String>('getCurrentIcon') ?? 'Default';
    } on MissingPluginException {
      return 'Default';
    } on PlatformException {
      return 'Default';
    }
  }

  Future<void> setIcon(String nativeName) async {
    try {
      final didChange = await _channel.invokeMethod<bool>('setIcon', {
        'iconName': nativeName,
      });
      if (didChange != true) throw const AppIconException();
    } on MissingPluginException {
      throw const AppIconException();
    } on PlatformException {
      throw const AppIconException();
    }
  }
}

class AppIconException implements Exception {
  const AppIconException();
}
