import '../contracts/common.dart';

/// Operation names are local adapter identifiers, NOT executable HTTP routes.
/// S00 must provide a reviewed HTTP bridge after S02 WR-B. Until then a fixture
/// transport can exercise the same parsers without accessing a server.
class WorkerWireRequest {
  WorkerWireRequest({
    required this.operation,
    required this.context,
    Map<String, Object?> arguments = const {},
  }) : arguments = Map.unmodifiable(arguments);

  final String operation;
  final WorkerSessionContext context;
  final Map<String, Object?> arguments;
}

class WorkerWireResponse {
  const WorkerWireResponse(this.status, this.body);
  final int status;
  final Object? body;
}

/// No auth headers, tokens, credentials, or private payloads are loggable here.
abstract interface class WorkerReadTransport {
  Future<WorkerWireResponse> read(WorkerWireRequest request);
}

/// Writing is opt-in, and never queued or retried by an adapter.
abstract interface class WorkerWriteTransport {
  Future<WorkerWireResponse> write(WorkerWireRequest request);
}

class WorkerTransportFault implements Exception {
  const WorkerTransportFault(this.kind);
  final WorkerTransportFaultKind kind;
}

enum WorkerTransportFaultKind { offline, timeout, unreachable }

class WireContractException implements Exception {
  const WireContractException();
}

PortFailure unavailableFailure() =>
    PortFailure(kind: FailureKind.server, reasonCode: 'unavailable');

PortFailure wireFailure() => PortFailure(
  kind: FailureKind.server,
  reasonCode: 'wire_contract_unavailable',
);

PortFailure statusFailure(int status) => switch (status) {
  401 => PortFailure(
    kind: FailureKind.unauthenticated,
    reasonCode: 'session_expired',
  ),
  403 => PortFailure(kind: FailureKind.forbidden, reasonCode: 'unavailable'),
  404 => PortFailure(kind: FailureKind.notFound, reasonCode: 'not_found'),
  409 => PortFailure(kind: FailureKind.conflict, reasonCode: 'state_changed'),
  422 => PortFailure(
    kind: FailureKind.validation,
    reasonCode: 'invalid_request',
  ),
  >= 500 => PortFailure(
    kind: FailureKind.server,
    reasonCode: 'server_unavailable',
  ),
  _ => wireFailure(),
};

PortFailure faultFailure(WorkerTransportFault fault) => PortFailure(
  kind: FailureKind.network,
  reasonCode: fault.kind == WorkerTransportFaultKind.offline
      ? 'offline'
      : 'connection_unavailable',
);
