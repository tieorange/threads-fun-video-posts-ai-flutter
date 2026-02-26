import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../logging/log_buffer.dart';
import '../logging/log_exporter.dart';
import '../logging/logger.dart';
import '../../features/video_processing/data/datasources/video_remote_datasource.dart';
import '../../features/video_processing/data/repositories/video_repository_impl.dart';
import '../../features/video_processing/data/repositories/process_repository_impl.dart';
import '../../features/video_processing/domain/usecases/analyze_video_usecase.dart';
import '../../features/video_processing/domain/usecases/build_ai_prompt_usecase.dart';
import '../../features/video_processing/domain/usecases/validate_and_parse_json_usecase.dart';
import '../../features/video_processing/domain/usecases/submit_process_usecase.dart';
import '../../features/video_processing/domain/usecases/poll_job_status_usecase.dart';
import '../../features/video_processing/presentation/cubits/analyze_cubit.dart';
import '../../features/video_processing/presentation/cubits/prompt_cubit.dart';
import '../../features/video_processing/presentation/cubits/json_paste_cubit.dart';
import '../../features/video_processing/presentation/cubits/moments_review_cubit.dart';
import '../../features/video_processing/presentation/cubits/process_cubit.dart';

final sl = GetIt.instance;

void setupDependencies() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Logging (singletons — shared across whole app)
  sl.registerLazySingleton<LogBuffer>(() => LogBuffer());
  sl.registerLazySingleton<AppLogger>(() => AppLogger(sl<LogBuffer>()));
  sl.registerLazySingleton<LogExporter>(() => LogExporter(sl<LogBuffer>()));

  // Dio
  sl.registerLazySingleton<Dio>(() => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      ));

  // Datasources
  sl.registerLazySingleton(() => VideoRemoteDatasource(sl<Dio>(), sl<AppLogger>()));

  // Repositories
  sl.registerLazySingleton(() => VideoRepositoryImpl(sl<VideoRemoteDatasource>()));
  sl.registerLazySingleton(() => ProcessRepositoryImpl(sl<VideoRemoteDatasource>()));

  // Use cases
  sl.registerLazySingleton(() => AnalyzeVideoUseCase(sl<VideoRepositoryImpl>()));
  sl.registerLazySingleton(() => const BuildAiPromptUseCase());
  sl.registerLazySingleton(() => const ValidateAndParseJsonUseCase());
  sl.registerLazySingleton(() => SubmitProcessUseCase(sl<ProcessRepositoryImpl>()));
  sl.registerLazySingleton(() => PollJobStatusUseCase(sl<ProcessRepositoryImpl>()));

  // Cubits (factories — new instance per registration)
  sl.registerFactory(() => AnalyzeCubit(sl<AnalyzeVideoUseCase>(), sl<AppLogger>()));
  sl.registerFactory(() => PromptCubit(sl<BuildAiPromptUseCase>(), sl<AppLogger>()));
  sl.registerFactory(() => JsonPasteCubit(sl<ValidateAndParseJsonUseCase>(), sl<AppLogger>()));
  sl.registerFactory(() => MomentsReviewCubit(sl<AppLogger>()));
  sl.registerFactory(
    () => ProcessCubit(sl<SubmitProcessUseCase>(), sl<PollJobStatusUseCase>(), sl<AppLogger>()),
  );
}
