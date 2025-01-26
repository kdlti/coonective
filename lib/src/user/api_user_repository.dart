import 'dart:convert'; // Para converter objetos em JSON e vice-versa.
import 'package:coonective/package.dart'; // Ajuste de acordo com a localização real de seus imports

class ApiUserRepository {
  final String userId;
  ApiStorage? _apiStorage;

  ApiUserRepository(this.userId);

  /// Método para inicializar o armazenamento.
  /// Deve ser chamado antes de tentar ler ou gravar qualquer informação.
  Future<void> initStorage() async {
    // Agora o nome do armazenamento é baseado no userId.
    _apiStorage = await ApiStorage.init(name: userId);
  }

  /// Método para salvar as informações de um usuário no armazenamento.
  ///
  /// O objeto `userInfo` será convertido para JSON e armazenado de forma criptografada.
  Future<void> saveUserInfo(ApiUser userInfo) async {
    if (_apiStorage == null) {
      throw Exception("Armazenamento não inicializado. Chame initStorage() primeiro.");
    }

    // Converte o objeto UserInfo em JSON.
    final jsonString = json.encode(userInfo.toJson());

    // Grava no armazenamento, usando a chave "user_info"
    await _apiStorage!.add("user_info", jsonString);
  }

  /// Método para recuperar as informações do usuário armazenadas.
  /// Retorna null se não houver informações salvas.
  Future<ApiUser?> loadUserInfo() async {
    if (_apiStorage == null) {
      throw Exception("Armazenamento não inicializado. Chame initStorage() primeiro.");
    }

    // Lê o valor associado à chave "user_info".
    final jsonString = await _apiStorage!.read("user_info");

    if (jsonString != null && jsonString.isNotEmpty) {
      // Converte a string JSON de volta para o objeto UserInfo.
      final Map<String, dynamic> data = json.decode(jsonString);
      return ApiUser.fromJson(data);
    }

    return null; // Caso não haja dados armazenados.
  }

  /// Método para remover as informações do usuário do armazenamento.
  Future<void> removeUserInfo() async {
    if (_apiStorage == null) {
      throw Exception("Armazenamento não inicializado. Chame initStorage() primeiro.");
    }

    await _apiStorage!.remove("user_info");
  }

  /// Método para descartar o armazenamento.
  void dispose() {
    _apiStorage?.dispose();
  }
}
