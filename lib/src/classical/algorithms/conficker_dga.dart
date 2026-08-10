import 'package:pqdga/src/classical/dga_core.dart';

/// Conficker DGA Configuration
class ConfickerDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;
  final int domainsPerDay;
  final String variant;
  final bool useWeekSeed;

  const ConfickerDGA({
    this.tld = const [
      '.com',
      '.net',
      '.org',
      '.info',
      '.biz',
      '.cc',
      '.cn',
      '.ws',
    ],
    this.minDomainLength = 8,
    this.maxDomainLength = 15,
    this.domainsPerDay = 50000,
    this.variant = "C",
    this.useWeekSeed = true,
  });
}
