import 'package:pqdga/src/classical/dga_core.dart';

/// Tinba (Tiny Banker) DGA
class TinbaDGA extends DGAAlgorithm {
  final List<String> tld;
  final int domainLength;
  final int domainsPerDay;
  final int botId;
  final int prngMultiplier;
  final int prngIncrement;

  const TinbaDGA({
    this.tld = const [".com", ".net", ".ru"],
    this.domainLength = 14,
    this.domainsPerDay = 1000,
    this.botId = 0x12345678, // Simulating fixed Bot ID for research
    this.prngMultiplier = 0x343FD,
    this.prngIncrement = 0x269EC3,
  });
}
