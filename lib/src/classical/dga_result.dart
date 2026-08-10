/// Result of DGA generation with metadata for analysis
class DGAResult {
  final List<String> domains;
  final DateTime generationDate;
  final String algorithm;
  final String seed;
  final Map<String, dynamic> metadata;

  DGAResult({
    required this.domains,
    required this.generationDate,
    required this.algorithm,
    required this.seed,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'DGAResult(algo: $algorithm, date: $generationDate, domains: ${domains.length})';
  }
}
