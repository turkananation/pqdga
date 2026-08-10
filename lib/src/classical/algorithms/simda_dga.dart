import 'package:pqdga/src/classical/dga_core.dart';

/// Simda DGA
class SimdaDGA extends DGAAlgorithm {
  final List<String> tld;
  final int domainLength;
  final int domainsPerDay;
  final int xorConstant;

  const SimdaDGA({
    this.tld = const [".com", ".net", ".org", ".info"],
    this.domainLength = 16,
    this.domainsPerDay = 32,
    this.xorConstant = 0xABCD,
  });
}
