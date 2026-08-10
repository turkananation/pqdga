import 'package:pqdga/pqdga.dart';

class DictionaryBasedDGA extends DGAAlgorithm {
  final List<String> wordList;
  final List<String> tld;

  const DictionaryBasedDGA({
    required this.wordList,
    this.tld = const [".com", ".net"],
  });
}
