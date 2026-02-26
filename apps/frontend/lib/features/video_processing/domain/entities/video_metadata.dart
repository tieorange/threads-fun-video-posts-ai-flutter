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
}
