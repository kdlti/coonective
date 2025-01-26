/// Representa a paginação de uma API, contendo informações de limite, página
/// atual, total de páginas, etc.
class ApiPagination {
  /// Limite máximo de itens por página.
  final int limit;

  /// Índice (ou número) da próxima página.
  final int next;

  /// Página atual.
  final int page;

  /// Total de páginas disponíveis.
  final int pages;

  /// Índice (ou número) da página anterior.
  final int previous;

  /// Total de itens retornados.
  final int total;

  /// Cria uma instância de [ApiPagination].
  const ApiPagination({
    this.limit = 1000,
    this.next = 0,
    this.page = 1,
    this.pages = 1,
    this.previous = 0,
    this.total = 0,
  });

  /// Cria uma instância de [ApiPagination] a partir de um [Map<String, dynamic>].
  factory ApiPagination.fromJson(Map<String, dynamic> json) {
    return ApiPagination(
      limit: json['limit'] as int,
      next: json['next'] as int,
      page: json['page'] as int,
      pages: json['pages'] as int,
      previous: json['previous'] as int,
      total: json['total'] as int,
    );
  }

  /// Converte a instância atual de [ApiPagination] em um [Map<String, dynamic>].
  Map<String, dynamic> get values {
    return {
      'limit': limit,
      'next': next,
      'page': page,
      'pages': pages,
      'previous': previous,
      'total': total,
    };
  }

  /// Verifica se há uma próxima página.
  bool hasNext() {
    return next > 0;
  }

  /// Verifica se há uma página anterior.
  bool hasPrevious() {
    return previous > 0;
  }

  /// Retorna uma representação em [String] do objeto [ApiPagination].
  @override
  String toString() {
    return 'ApiPagination(limit: $limit, next: $next, page: $page, pages: $pages, previous: $previous, total: $total)';
  }
}
