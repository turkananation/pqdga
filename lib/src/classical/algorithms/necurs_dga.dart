import 'package:pqdga/src/classical/dga_core.dart';

/// Necurs DGA Configuration
class NecursDGA extends DGAAlgorithm {
  final List<String> tld;
  final int minDomainLength;
  final int maxDomainLength;
  final int domainsPerDay;
  final bool usePronounceablePattern;

  const NecursDGA({
    this.tld = const [
      ".com",
      ".net",
      ".org",
      ".info",
      ".biz",
      ".ru",
      ".cn",
      ".co.uk",
      ".de",
      ".fr",
      ".jp",
      ".br",
      ".in",
      ".it",
      ".pl",
      ".au",
      ".za",
      ".ca",
      ".nl",
      ".es",
      ".mx",
      ".se",
      ".ch",
      ".at",
      ".be",
      ".cz",
      ".dk",
      ".no",
      ".pt",
      ".fi",
      ".gr",
      ".hu",
      ".ie",
      ".ro",
      ".sk",
    ],
    this.minDomainLength = 8,
    this.maxDomainLength = 20,
    this.domainsPerDay = 2048,
    this.usePronounceablePattern = true,
  });
}
