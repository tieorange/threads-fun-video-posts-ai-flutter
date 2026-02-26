part of 'moments_review_cubit.dart';

final class MomentsReviewState {
  const MomentsReviewState({
    required this.moments,
    required this.selected,
  });

  final List<FunnyMoment> moments;
  final Set<String> selected;

  List<FunnyMoment> get selectedMoments =>
      moments.where((m) => selected.contains(m.id)).toList();

  bool isSelected(String id) => selected.contains(id);
}
