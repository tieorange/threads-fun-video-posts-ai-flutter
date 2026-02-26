part of 'process_cubit.dart';

sealed class ProcessState {
  const ProcessState();
}

final class ProcessIdle extends ProcessState {
  const ProcessIdle();
}

final class ProcessSubmitting extends ProcessState {
  const ProcessSubmitting();
}

final class ProcessRunning extends ProcessState {
  const ProcessRunning({required this.jobId, required this.progress});
  final String jobId;
  final int progress;
}

final class ProcessDone extends ProcessState {
  const ProcessDone(this.jobStatus);
  final JobStatus jobStatus;
}

final class ProcessFailure extends ProcessState {
  const ProcessFailure(this.message);
  final String message;
}
