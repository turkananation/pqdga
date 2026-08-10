import 'package:pqdga/src/classical/dga_core.dart';

/// CryptoLocker DGA
class CryptoLockerDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;
  final int domainsPerDay;
  final int seedConstant;

  const CryptoLockerDGA({
    this.tld = const [".com", ".net", ".org", ".info", ".biz", ".co.uk", ".ru"],
    this.minDomainLength = 12,
    this.maxDomainLength = 20,
    this.domainsPerDay = 1000,
    this.seedConstant = 0x1234,
  });
}
