import '../api_storage.dart';

class ApiClient {
  static Future<ApiStorage?> get storage async {
    return await ApiStorage.init(name: 'coonective');
  }

  static Future<String?> get getAccessToken async {
    ApiStorage? apiStorage = await storage;
    return apiStorage!.read('accessToken');
  }

  static void accessToken(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('accessToken', value);
  }

  static Future<String?> get getAuthToken async {
    ApiStorage? apiStorage = await storage;
    return apiStorage!.read('authToken');
  }

  static void authToken(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('authToken', value);
  }
}
