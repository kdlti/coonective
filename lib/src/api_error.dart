// A classe ApiError é usada para representar e lidar com erros da API.
import 'package:intl/intl.dart';

class ApiError {
  // Data e hora em que o erro ocorreu, no formato ISO8601.
  String createdAt;

  // Lista de mensagens de erro.
  final List<dynamic> messages;

  // Nome do módulo onde ocorreu o erro.
  // Mutation: módulo de mutação.
  // Query: módulo de consulta.
  final String module;

  // Caminho do campo ou recurso onde ocorreu o erro.
  // AclAuthorize: endpoint de autorização de acesso.
  final String path;

  // Tipo do erro, usado para classificar e identificar a natureza do erro.
  // GRAPHQL_VALIDATION_FAILED: Erro de validação GraphQL.
  final String code;

  // Variável adicional fornecida, geralmente usada para fornecer informações adicionais sobre o erro.
  final dynamic variables;

  // Construtor de chave nomeada e inicialização de campo.
  ApiError({
    required this.messages,
    required this.module,
    required this.path,
    required this.code,
    this.createdAt = '',
    this.variables,
  }) {
    DateTime dateTime = DateTime.now();

    //TODO:: Corrigir a formatação da data e hora da biblioteca intl
    String dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    createdAt = createdAt.isNotEmpty ? createdAt : dateFormat;
  }

  bool get hasError => messages.isNotEmpty;

  // Retorna uma representação de string da instância ApiError.
  @override
  String toString() {
    return 'module:$module, code:$code, path:$path, messages:$messages, variables:$variables, createdAt:$createdAt';
  }
}
