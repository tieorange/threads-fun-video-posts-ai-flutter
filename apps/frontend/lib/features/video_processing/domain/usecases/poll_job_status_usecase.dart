import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';
import '../entities/job_status.dart';
import '../entities/funny_moment.dart';
import '../repositories/process_repository.dart';

class PollJobStatusUseCase {
  const PollJobStatusUseCase(this._repository);

  final IProcessRepository _repository;

  Future<Either<Failure, JobStatus>> call(String jobId, List<FunnyMoment> moments) =>
      _repository.getJobStatus(jobId, moments);
}
