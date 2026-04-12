class AppConfig {
  static const bool useProduction = true;

  static const String productionApiBaseUrl =
      'https://granos-backend.onrender.com';

  static const String localApiBaseUrl =
      'http://192.168.5.45:4000';

  static const String apiBaseUrl =
      useProduction ? productionApiBaseUrl : localApiBaseUrl;
}