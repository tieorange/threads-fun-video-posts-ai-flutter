import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';
import '../repositories/process_repository.dart';

class SubmitProcessUseCase {
  const SubmitProcessUseCase(this._repository);

  final IProcessRepository _repository;

  Future<Either<Failure, String>> call(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
  ) =>
      _repository.submitProcess(youtubeUrl, aiPayload);
}
