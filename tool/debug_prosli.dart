import 'package:pqdga/src/classical/corpus/literature_prng.dart';

void main() {
  const s = 'prospect.5.14.2015.com';
  print('hash $s = ${proslikefanHashString(s)} abs=${proslikefanAbsHash(s)}');
  var r = proslikefanAbsHash(s) + 0;
  print('r0=$r len=${r % 7 + 6}');
  final buf = StringBuffer();
  var k = 0;
  final target = r % 7 + 6;
  while (k < target) {
    r = proslikefanAbsHash('${buf.toString()}$r');
    buf.writeCharCode(0x61 + (r % 26));
    k++;
    print('step $k ${buf.toString()} r=$r');
  }
  print('domain ${buf.toString()}.com');
  
  // step through hash of seed char by char
  var h = 0;
  for (final cu in s.codeUnits) {
    final before = h;
    h = asInt32((h << 5) - h + cu);
    print('ch=${String.fromCharCode(cu)} before=$before after=$h');
  }
}
