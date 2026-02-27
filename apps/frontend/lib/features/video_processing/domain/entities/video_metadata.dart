class VideoMetadata {
  const VideoMetadata({
    required this.videoId,
    required this.title,
    required this.durationSec,
    required this.sourceUrl,
  });

  final String videoId;
  final String title;
  final double durationSec;
  final String sourceUrl;
  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'durationSec': durationSec,
    'sourceUrl': sourceUrl,
  };

  factory VideoMetadata.fromJson(Map<String, dynamic> json) => VideoMetadata(
    videoId: json['videoId'] as String,
    title: json['title'] as String,
    durationSec: (json['durationSec'] as num).toDouble(),
    sourceUrl: json['sourceUrl'] as String,
  );
}
