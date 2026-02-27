import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/funny_moment.dart';
import '../../../../../core/logging/log_entry.dart';
import '../../../../../core/logging/logger.dart';

part 'moments_review_state.dart';

class MomentsReviewCubit extends Cubit<MomentsReviewState> {
  MomentsReviewCubit(this._log) : super(const MomentsReviewState(moments: [], selected: {}));

  final AppLogger _log;

  void load(List<FunnyMoment> moments, Map<String, dynamic> aiPayload) {
    final allSelected = {for (final m in moments) m.id};
    _log.info(
      'moments_loaded',
      'Loaded moments, all pre-selected',
      layer: AppLayer.presentation,
      data: {'count': moments.length},
    );
    emit(MomentsReviewState(moments: moments, selected: allSelected, aiPayload: aiPayload));
  }

  void toggle(String momentId) {
    final current = Set<String>.from(state.selected);
    if (current.contains(momentId)) {
      current.remove(momentId);
    } else {
      current.add(momentId);
    }
    _log.debug(
      'moment_toggled',
      'Moment selection toggled',
      layer: AppLayer.presentation,
      data: {
        'momentId': momentId,
        'nowSelected': current.contains(momentId),
        'totalSelected': current.length,
      },
    );
    emit(MomentsReviewState(moments: state.moments, selected: current));
  }

  void selectAll() {
    final all = {for (final m in state.moments) m.id};
    _log.info('moments_select_all', 'All moments selected', layer: AppLayer.presentation);
    emit(MomentsReviewState(moments: state.moments, selected: all));
  }

  void clearAll() {
    _log.info('moments_clear_all', 'All moments deselected', layer: AppLayer.presentation);
    emit(MomentsReviewState(moments: state.moments, selected: const {}));
  }

  void restoreMoments(List<FunnyMoment> moments, Map<String, dynamic> aiPayload) {
    final allSelected = {for (final m in moments) m.id};
    _log.info(
      'moments_restored',
      'Restored moments from persistence',
      layer: AppLayer.presentation,
      data: {'count': moments.length},
    );
    emit(MomentsReviewState(moments: moments, selected: allSelected, aiPayload: aiPayload));
  }

  void reset() {
    emit(const MomentsReviewState(moments: [], selected: {}));
  }
}
