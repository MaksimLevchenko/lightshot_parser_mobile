enum DownloadSource {
  lightshot,
  imgur,
}

String buildTrackingKey(DownloadSource source, String sourceId) {
  return '${source.name}@@$sourceId';
}

String canonicalizeTrackingKey(String value) {
  final parsed = parseTrackingKey(value);
  return buildTrackingKey(parsed.source, parsed.sourceId);
}

({DownloadSource source, String sourceId}) parseTrackingKey(String value) {
  final separatorIndex = value.indexOf('@@');
  if (separatorIndex <= 0) {
    return (
      source: DownloadSource.lightshot,
      sourceId: value,
    );
  }

  final sourceName = value.substring(0, separatorIndex);
  final sourceId = value.substring(separatorIndex + 2);
  final source = DownloadSource.values.where((item) => item.name == sourceName);
  if (source.isEmpty || sourceId.isEmpty) {
    return (
      source: DownloadSource.lightshot,
      sourceId: value,
    );
  }

  return (
    source: source.first,
    sourceId: sourceId,
  );
}
