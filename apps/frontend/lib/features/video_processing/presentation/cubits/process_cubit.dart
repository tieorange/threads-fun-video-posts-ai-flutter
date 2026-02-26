import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/usecases/submit_process_usecase.dart';
import '../../domain/usecases/poll_job_status_usecase.dart';

part 'process_state.dart';

class ProcessCubit extends Cubit<ProcessState> {
  ProcessCubit(this._submitProcess, this._pollStatus)
      : super(const ProcessIdle());

  final SubmitProcessUseCase _submitProcess;
  final PollJobStatusUseCase _pollStatus;

  Timer? _pollTimer;
  List<FunnyMoment> _moments = [];

  Future<void> startProcessing(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
    List<FunnyMoment> moments,
  ) async {
    _moments = moments;
    emit(const ProcessSubmitting());

    final result = await _submitProcess(youtubeUrl, aiPayload);
    result.fold(
      (failure) => emit(ProcessFailure(failure.message)),
      (jobId) {
        emit(ProcessRunning(jobId: jobId, progress: 0));
        _startPolling(jobId);
      },
    );
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final result = await _pollStatus(jobId, _moments);
      result.fold(
        (failure) {
          _pollTimer?.cancel();
          emit(ProcessFailure(failure.message));
        },
        (status) {
          switch (status.status) {
            case JobStatusType.queued:
            case JobStatusType.running:
              emit(ProcessRunning(jobId: jobId, progress: status.progress));
            case JobStatusType.done:
              _pollTimer?.cancel();
              emit(ProcessDone(status));
            case JobStatusType.failed:
              _pollTimer?.cancel();
              emit(ProcessFailure(status.error ?? 'Processing failed'));
          }
        },
      );
    });
  }

  void reset() {
    _pollTimer?.cancel();
    emit(const ProcessIdle());
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
