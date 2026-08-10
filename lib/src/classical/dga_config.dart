import 'package:pqdga/src/classical/dga_core.dart';

/// Configuration wrapper for DGA generation
class DGAConfig {
  final DGAAlgorithm algorithm;
  final int minDomainLength;
  final int maxDomainLength;
  final bool includeSubdomains;
  final int seedRotationDays;

  DGAConfig({
    required this.algorithm,
    this.minDomainLength = 8,
    this.maxDomainLength = 20,
    this.includeSubdomains = false,
    this.seedRotationDays = 1,
  });
}
