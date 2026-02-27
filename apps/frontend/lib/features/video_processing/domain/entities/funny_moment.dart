class FunnyMoment {
  const FunnyMoment({
    required this.id,
    required this.startSec,
    required this.endSec,
    required this.caption,
    required this.postText,
    required this.reason,
  });

  final String id;
  final double startSec;
  final double endSec;
  final String caption;
  final String postText;
  final String reason;
  Map<String, dynamic> toJson() => {
    'id': id,
    'startSec': startSec,
    'endSec': endSec,
    'caption': caption,
    'postText': postText,
    'reason': reason,
  };

  factory FunnyMoment.fromJson(Map<String, dynamic> json) => FunnyMoment(
    id: json['id'] as String,
    startSec: (json['startSec'] as num).toDouble(),
    endSec: (json['endSec'] as num).toDouble(),
    caption: json['caption'] as String,
    postText: json['postText'] as String,
    reason: json['reason'] as String,
  );
}
