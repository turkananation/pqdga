import 'package:pqdga/pqdga.dart';

class TimeBasedDGA extends DGAAlgorithm {
  final String seed;
  final List<String> tld;
  final int domainsPerDay;

  const TimeBasedDGA({
    required this.seed,
    this.tld = const [".com", ".net", ".org"],
    this.domainsPerDay = 1000,
  });
}
