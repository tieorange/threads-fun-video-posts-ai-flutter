import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'analyze_cubit.dart';
import 'prompt_cubit.dart';
import 'json_paste_cubit.dart';
import '../../data/datasources/chat_local_storage_datasource.dart';
import 'moments_review_cubit.dart';
import '../../domain/entities/funny_moment.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/usecases/submit_process_usecase.dart';
import '../../domain/usecases/poll_job_status_usecase.dart';
import '../../../../../core/logging/log_entry.dart';
import '../../../../../core/logging/logger.dart';

part 'process_state.dart';

class ProcessCubit extends Cubit<ProcessState> {
  ProcessCubit(this._submitProcess, this._pollStatus, this._storage, this._log)
    : super(const ProcessIdle()) {
    _restoreState();
  }

  final SubmitProcessUseCase _submitProcess;
  final PollJobStatusUseCase _pollStatus;
  final ChatLocalStorageDatasource _storage;
  final AppLogger _log;

  bool _isDisposed = false;
  String? _activeJobId;
  List<FunnyMoment> _moments = [];

  Future<void> startProcessing(
    String youtubeUrl,
    Map<String, dynamic> aiPayload,
    List<FunnyMoment> moments,
  ) async {
    _moments = moments;
    _log.info(
      'process_submit_start',
      'Submitting job',
      layer: AppLayer.presentation,
      data: {'url': youtubeUrl, 'momentCount': moments.length},
    );
    emit(const ProcessSubmitting());

    final result = await _submitProcess(youtubeUrl, aiPayload);
    result.fold(
      (failure) {
        _log.error('process_submit_failed', failure.message, layer: AppLayer.presentation);
        emit(ProcessFailure(failure.message));
      },
      (jobId) {
        _log.info(
          'process_job_queued',
          'Job queued, starting poll',
          layer: AppLayer.presentation,
          jobId: jobId,
        );
        _log.setJobId(jobId);
        _storage.saveJob(jobId: jobId, moments: _moments, youtubeUrl: youtubeUrl);
        emit(ProcessRunning(jobId: jobId, progress: 0));
        _startPolling(jobId);
      },
    );
  }

  void _restoreState() {
    final jobData = _storage.loadJob();
    if (jobData != null) {
      _log.info(
        'process_restored',
        'Restoring active job from persistence',
        layer: AppLayer.presentation,
        jobId: jobData.jobId,
      );
      _moments = jobData.moments;
      _log.setJobId(jobData.jobId);
      emit(ProcessRunning(jobId: jobData.jobId, progress: 0));
      _startPolling(jobData.jobId);
    }
  }

  Future<void> _startPolling(String jobId) async {
    _activeJobId = jobId;

    while (!_isDisposed && _activeJobId == jobId) {
      final result = await _pollStatus(jobId, _moments);

      if (_isDisposed || _activeJobId != jobId) break;

      final shouldContinue = result.fold(
        (failure) {
          _log.error(
            'process_poll_failed',
            failure.message,
            layer: AppLayer.presentation,
            jobId: jobId,
          );
          emit(ProcessFailure(failure.message));
          return false;
        },
        (status) {
          switch (status.status) {
            case JobStatusType.queued:
            case JobStatusType.running:
              _log.debug(
                'process_poll_running',
                'Job running (${status.progress}%)',
                layer: AppLayer.presentation,
                jobId: jobId,
                data: {'progress': status.progress},
              );
              emit(ProcessRunning(jobId: jobId, progress: status.progress));
              return true;
            case JobStatusType.done:
              _log.info(
                'process_done',
                'Job done',
                layer: AppLayer.presentation,
                jobId: jobId,
                data: {'clipCount': status.clips.length},
              );
              emit(ProcessDone(status));
              return false;
            case JobStatusType.failed:
              _log.error(
                'process_job_failed',
                status.error ?? 'Processing failed',
                layer: AppLayer.presentation,
                jobId: jobId,
              );
              emit(ProcessFailure(status.error ?? 'Processing failed'));
              return false;
          }
        },
      );

      if (!shouldContinue) break;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void resetAll(BuildContext context) {
    _activeJobId = null;
    _log.setJobId('');

    // Reset all related cubits to prevent stale state leaks
    context.read<AnalyzeCubit>().reset();
    context.read<PromptCubit>().reset();
    context.read<JsonPasteCubit>().reset();
    context.read<MomentsReviewCubit>().reset();

    emit(const ProcessIdle());
  }

  void reset() {
    _activeJobId = null;
    _log.setJobId('');
    emit(const ProcessIdle());
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    _activeJobId = null;
    return super.close();
  }
}
