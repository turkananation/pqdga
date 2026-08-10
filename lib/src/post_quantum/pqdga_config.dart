import 'package:pqdga/src/post_quantum/pqdga_core.dart';

class PQDGAConfig {
  final PQDGAAlgorithm algorithm;
  final int minDomainLength;
  final int maxDomainLength;
  final bool includeSubdomains;
  final int seedRotationDays;

  PQDGAConfig({
    required this.algorithm,
    this.minDomainLength = 8,
    this.maxDomainLength = 20,
    this.includeSubdomains = false,
    this.seedRotationDays = 1,
  });
}
