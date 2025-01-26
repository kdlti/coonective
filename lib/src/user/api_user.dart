import 'package:coonective/src/user/api_user_repository.dart';
import 'package:jose/jose.dart';

class AccessLevelItem {
  final String? hash;
  final String? name;
  final String? module;
  final int? view;
  final int? edit;
  final int? delete;

  const AccessLevelItem({
    this.hash,
    this.name,
    this.module,
    this.view,
    this.edit,
    this.delete,
  });

  factory AccessLevelItem.fromJson(Map<String, dynamic> json) {
    return AccessLevelItem(
      hash: json['hash'] as String?,
      name: json['name'] as String?,
      module: json['module'] as String?,
      view: _parseInt(json['view']),
      edit: _parseInt(json['edit']),
      delete: _parseInt(json['delete']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'name': name,
      'module': module,
      'view': view,
      'edit': edit,
      'delete': delete,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ApiUser {
  /// Identificador único do usuário (mapeado a partir de `_id` do JSON).
  final String id;

  /// Nome completo do usuário.
  final String? name;

  /// E-mail do usuário.
  final String? email;

  /// Username do usuário.
  final String? username;

  /// Telefone do usuário (opcional).
  final String? phone;

  /// Lista de níveis de acesso do usuário.
  final List<AccessLevelItem>? accessLevel;

  /// Biografia do usuário.
  final String? bio;

  /// Data de nascimento do usuário.
  final String? dateOfBirth;

  final String? modules;

  /// Identificador de sessão do usuário.
  String sessionId;

  /// Construtor da classe `ApiUser`.
  ApiUser({
    required this.id,
    this.name,
    this.email,
    this.username,
    this.phone,
    this.accessLevel,
    this.bio,
    this.dateOfBirth,
    this.sessionId = "",
    this.modules,
  });

  /// Cria uma instância de `ApiUser` a partir de um mapa JSON.
  factory ApiUser.fromJson(Map<String, dynamic> json) {


    ApiUser apiUser = ApiUser(
      id: json['_id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      accessLevel: _parseAccessLevel(json['accessLevel']),
      bio: json['bio'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      sessionId: json['sessionId'] ?? "",
      modules: json['modules'] as String?,
    );

    String? token = json["token"];
    if (token != null && token.isNotEmpty) {
      var jwt = JsonWebToken.unverified(token);
      if (jwt.claims['cid'] != null) {
        apiUser.sessionId = jwt.claims['cid'];
        apiUser.save();
      }
    }

    return apiUser;
  }

  /// Converte a instância atual de `ApiUser` em um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'username': username,
      'phone': phone,
      'bio': bio,
      'dateOfBirth': dateOfBirth,
      'accessLevel': accessLevel?.map((e) => e.toJson()).toList(),
      'sessionId': sessionId,
      'modules': modules,
    };
  }

  /// Método auxiliar para extrair a lista de `AccessLevelItem` do JSON.
  static List<AccessLevelItem>? _parseAccessLevel(dynamic jsonValue) {
    if (jsonValue is List) {
      return jsonValue
          .map((e) => e is Map<String, dynamic> ? AccessLevelItem.fromJson(e) : null)
          .where((element) => element != null)
          .cast<AccessLevelItem>()
          .toList();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  //                          MÉTODOS DE FACHADA
  // ---------------------------------------------------------------------------

  /// Carrega as informações do usuário a partir do armazenamento usando o `UserRepository`.
  /// Retorna uma instância de `ApiUser` ou `null` se não encontrar dados.
  static Future<ApiUser?> load() async {
    final userRepository = ApiUserRepository("user_info");
    await userRepository.initStorage();
    return await userRepository.loadUserInfo();
  }

  /// Salva as informações do usuário atual no armazenamento.
  /// Requer que o usuário possua um `id` válido.
  Future<void> save() async {
    if (id.isEmpty) {
      return;
    }

    final userRepository = ApiUserRepository("user_info");
    await userRepository.initStorage();
    await userRepository.saveUserInfo(this);
  }

  /// Remove as informações do usuário atual do armazenamento.
  /// Requer que o usuário possua um `id` válido.
  Future<void> remove() async {
    final userRepository = ApiUserRepository("user_info");
    await userRepository.initStorage();
    await userRepository.removeUserInfo();
  }

  @override
  String toString() {
    return 'ApiUser{id: $id, name: $name, email: $email, username: $username, phone: $phone, bio: $bio, dateOfBirth: $dateOfBirth, '
        'accessLevel: $accessLevel, sessionId: $sessionId, modules: $modules}';
  }
}
