import 'package:pqdga/pqdga.dart';

class ArithmeticDGA extends DGAAlgorithm {
  final int seed;
  final int multiplier;
  final int increment;
  final int modulus;

  const ArithmeticDGA({
    required this.seed,
    this.multiplier = 1103515245,
    this.increment = 12345,
    this.modulus = 2147483648,
  });
}
