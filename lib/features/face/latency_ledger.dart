/// Measures what each detector option actually costs on this device.
///
/// Latency is averaged per option-set. The cost of a single option is then the
/// difference between the current set and the same set with that option off —
/// a real measurement, or nothing at all. It never estimates.
class LatencyLedger {
  static const _minSamples = 12;

  final Map<int, _Running> _byKey = {};

  void record(int key, double ms) =>
      (_byKey[key] ??= _Running()).add(ms);

  double? average(int key) {
    final r = _byKey[key];
    return (r == null || r.count < _minSamples) ? null : r.mean;
  }

  /// Extra milliseconds per frame attributable to [bit], or null while either
  /// side of the comparison is still unmeasured.
  double? costOf(int key, int bit) {
    if (key & bit == 0) return null;
    final with_ = average(key);
    final without = average(key & ~bit);
    if (with_ == null || without == null) return null;
    final delta = with_ - without;
    return delta <= 0 ? 0 : delta;
  }

  void clear() => _byKey.clear();
}

class _Running {
  int count = 0;
  double mean = 0;

  void add(double v) {
    count++;
    mean += (v - mean) / count;
  }
}

abstract final class OptionBit {
  static const contours = 1 << 0;
  static const landmarks = 1 << 1;
  static const classification = 1 << 2;
  static const tracking = 1 << 3;
  static const accurate = 1 << 4;
}
