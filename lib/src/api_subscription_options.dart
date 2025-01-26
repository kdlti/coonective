
import 'package:coonective/package.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';

typedef Next<TResult> = TResult Function(ApiResponse data);

@immutable
class ApiSubscriptionOptions<TParsed extends Object?>{
  /// Document containing at least one [OperationDefinitionNode]
  final String query;

  /// Name of the executable definition
  ///
  /// Must be specified if [document] contains more than one [OperationDefinitionNode]
  final String? operationName;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  final Map<String, dynamic> variables;

  /// An optimistic result to eagerly add to the operation stream
  final Object? optimisticResult;

  /// Specifies the [Policies] to be used during execution.
  final Policies? policies;

  final FetchPolicy? fetchPolicy;

  final ErrorPolicy? errorPolicy;

  final CacheRereadPolicy? cacheRereadPolicy;

  /// Context to be passed to link execution chain.
  final Context? context;

  final Next<TParsed>? next;

  const ApiSubscriptionOptions({
    required this.query,
    this.operationName,
    this.variables = const {},
    this.policies,
    this.fetchPolicy,
    this.errorPolicy,
    this.cacheRereadPolicy,
    this.optimisticResult,
    this.context,
    this.next,
  });
}