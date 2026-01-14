class DataUsageEstimator {
  /// Estimate data usage in MB based on bitrate and duration
  static double estimateDataUsage(int bitrateKbps, Duration duration) {
    final totalSeconds = duration.inSeconds;
    final bitsPerSecond = bitrateKbps * 1000;
    final totalBits = bitsPerSecond * totalSeconds;
    final totalBytes = totalBits / 8;
    final totalMB = totalBytes / (1024 * 1024);
    return totalMB;
  }

  /// Estimate battery drain percentage based on duration and mode
  static double estimateBatteryDrain(Duration duration, bool isPowerSaving) {
    final hours = duration.inHours + (duration.inMinutes % 60) / 60.0;

    // Normal mode: ~20% per hour
    // Power saving mode: ~12% per hour
    final drainPerHour = isPowerSaving ? 12.0 : 20.0;

    return hours * drainPerHour;
  }

  /// Get estimated hourly data usage
  static double getHourlyDataUsage(bool isPowerSaving) {
    // Normal: ~1.5 Mbps = ~675 MB/hour
    // Power saving: ~400 Kbps = ~180 MB/hour
    return isPowerSaving ? 180.0 : 675.0;
  }
}
