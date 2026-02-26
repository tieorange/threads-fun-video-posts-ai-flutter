import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/funny_moment.dart';

part 'moments_review_state.dart';

class MomentsReviewCubit extends Cubit<MomentsReviewState> {
  MomentsReviewCubit() : super(const MomentsReviewState(moments: [], selected: {}));

  void load(List<FunnyMoment> moments) {
    final allSelected = {for (final m in moments) m.id};
    emit(MomentsReviewState(moments: moments, selected: allSelected));
  }

  void toggle(String momentId) {
    final current = Set<String>.from(state.selected);
    if (current.contains(momentId)) {
      current.remove(momentId);
    } else {
      current.add(momentId);
    }
    emit(MomentsReviewState(moments: state.moments, selected: current));
  }

  void selectAll() {
    final all = {for (final m in state.moments) m.id};
    emit(MomentsReviewState(moments: state.moments, selected: all));
  }

  void clearAll() {
    emit(MomentsReviewState(moments: state.moments, selected: const {}));
  }
}
