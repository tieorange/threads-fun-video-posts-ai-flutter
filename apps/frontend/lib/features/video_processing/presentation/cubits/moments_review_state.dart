part of 'moments_review_cubit.dart';

final class MomentsReviewState {
  const MomentsReviewState({required this.moments, required this.selected, this.aiPayload});

  final List<FunnyMoment> moments;
  final Set<String> selected;
  final Map<String, dynamic>? aiPayload;

  List<FunnyMoment> get selectedMoments => moments.where((m) => selected.contains(m.id)).toList();

  bool isSelected(String id) => selected.contains(id);

  MomentsReviewState copyWith({
    List<FunnyMoment>? moments,
    Set<String>? selected,
    Map<String, dynamic>? aiPayload,
  }) {
    return MomentsReviewState(
      moments: moments ?? this.moments,
      selected: selected ?? this.selected,
      aiPayload: aiPayload ?? this.aiPayload,
    );
  }
}
