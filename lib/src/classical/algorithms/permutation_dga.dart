import 'package:pqdga/pqdga.dart';

class PermutationDGA extends DGAAlgorithm {
  final String baseDomain;
  final int permutationRounds;

  const PermutationDGA({required this.baseDomain, this.permutationRounds = 3});
}
