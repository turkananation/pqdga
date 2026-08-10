import 'package:pqdga/src/classical/dga_core.dart';

/// Matsnu (Sality) DGA Configuration
class MatsnuDGA extends DGAAlgorithm {
  final List<String> tld;
  final int domainLength;
  final int domainsPerDay;

  const MatsnuDGA({
    this.tld = const ['.com', '.net', '.org', '.info'],
    this.domainLength = 12,
    this.domainsPerDay = 1000,
  });
}
