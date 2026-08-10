import 'package:pqdga/src/classical/dga_core.dart';

/// Pushdo (Cutwail) DGA Configuration
class PushdoDGA extends DGAAlgorithm {
  final List<String> tld;
  final int domainLength;
  final int domainsPerDay;
  final int lcgMultiplier;
  final int lcgIncrement;
  final bool includeNumbers;

  const PushdoDGA({
    this.tld = const ['.com', '.net', '.org'],
    this.domainLength = 12,
    this.domainsPerDay = 500,
    this.lcgMultiplier = 1664525,
    this.lcgIncrement = 1013904223,
    this.includeNumbers = true,
  });
}
