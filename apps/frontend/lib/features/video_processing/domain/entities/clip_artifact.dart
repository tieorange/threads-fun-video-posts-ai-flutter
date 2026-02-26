class ClipArtifact {
  const ClipArtifact({
    required this.momentId,
    required this.startSec,
    required this.endSec,
    required this.downloadUrl,
  });

  final String momentId;
  final double startSec;
  final double endSec;
  final String downloadUrl;
}
