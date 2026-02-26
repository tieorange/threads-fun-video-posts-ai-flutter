import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/failure.dart';
import '../entities/job_status.dart';
import '../entities/funny_moment.dart';

abstract interface class IProcessRepository {
  Future<Either<Failure, String>> submitProcess(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
  );

  Future<Either<Failure, JobStatus>> getJobStatus(
    String jobId,
    List<FunnyMoment> moments,
  );
}
