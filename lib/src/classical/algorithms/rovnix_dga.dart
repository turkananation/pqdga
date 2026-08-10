import 'package:pqdga/src/classical/dga_core.dart';

/// Rovnix DGA Configuration
class RovnixDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;
  final int domainsPerDay;
  final String variant;

  const RovnixDGA({
    this.tld = const ['.com', '.net', '.ru'],
    this.minDomainLength = 10,
    this.maxDomainLength = 18,
    this.domainsPerDay = 1000,
    this.variant = "v3",
  });
}
