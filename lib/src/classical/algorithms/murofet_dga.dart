import 'package:pqdga/src/classical/dga_core.dart';

/// Murofet (Licat) DGA
class MurofetDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;
  final int domainsPerHour;
  final int domainsPerDay;
  final bool useHourlySeed;

  const MurofetDGA({
    this.tld = const [".com", ".net", ".org", ".ru", ".biz"],
    this.minDomainLength = 7,
    this.maxDomainLength = 12,
    this.domainsPerHour = 50,
    this.domainsPerDay = 1200,
    this.useHourlySeed = true,
  });
}
