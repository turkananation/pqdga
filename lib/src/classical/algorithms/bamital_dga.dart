import 'package:pqdga/src/classical/dga_core.dart';

/// Bamital DGA
class BamitalDGA extends DGAAlgorithm {
  final List<String> wordList;
  final List<String> tld;
  final int wordsPerDomain;
  final bool appendNumbers;
  final int domainsPerDay;

  const BamitalDGA({
    required this.wordList, // Dictionary must be provided
    this.tld = const [".com"],
    this.wordsPerDomain = 2,
    this.appendNumbers = true,
    this.domainsPerDay = 750,
  });
}
