sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.code});
  final String? code;
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
