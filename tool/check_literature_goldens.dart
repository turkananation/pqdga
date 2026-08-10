import 'package:pqdga/pqdga.dart';

Future<void> main() async {
  final date = DateTime.utc(2015, 5, 14);
  Future<List<String>> gen(DGAAlgorithm a, {DateTime? d, int n = 5}) async =>
      (await DGAGenerator(DGAConfig(algorithm: a)).generateDomains(d ?? date, n))
          .domains;

  void check(String name, List<String> got, List<String> want) {
    final ok = got.length >= want.length &&
        List.generate(want.length, (i) => got[i] == want[i]).every((e) => e);
    print('$name: ${ok ? "OK" : "FAIL"}');
    if (!ok) {
      print('  got:  $got');
      print('  want: $want');
    }
  }

  check(
    'ramnit',
    await gen(const RamnitDGA()),
    const [
      'prklqkkwhgpshiejk.click',
      'rvcophrldij.com',
      'jwerjdldqihxucyfoh.eu',
      'kihjtklbkgdn.bid',
      'obmyqaflbudqfssibeb.click',
    ],
  );
  check(
    'nymaim',
    await gen(const NymaimDGA()),
    const [
      'rjvoupbixei.com',
      'ogqywunvso.net',
      'vfnevybb.com',
      'mwejxrzgip.com',
      'tkufyyjg.org',
    ],
  );
  check(
    'shiotob',
    await gen(const ShiotobDGA()),
    const [
      '4ypv1eehphg3a.com',
      'dduub92cik.net',
      'fzwrzifvtl.com',
      'wnjjsiya5x.net',
      'zyvdupb4uk.com',
    ],
  );
  check(
    'vawtrak',
    await gen(const VawtrakDGA()),
    const [
      'detglevgza.top',
      'arcxcps.top',
      'avgjqduxq.top',
      'kjolgrovcf.top',
      'tefsbuv.top',
    ],
  );
  check(
    'dircrypt',
    await gen(const DirCryptDGA()),
    const [
      'omihgxsjrjp.com',
      'tdqqrkabur.com',
      'ergxmwbqepucr.com',
      'czmhrhllgzvxzxmwb.com',
      'ibzcbcnbcjqofidoa.com',
    ],
  );
  check(
    'corebot',
    await gen(const CoreBotDGA()),
    const [
      'vgfofehgj5vchstmla6s.ddns.net',
      '3pqfkxqvy252yxi4uxkjc8a.ddns.net',
      '5junclmlqr5t561.ddns.net',
      'cbwxk0m0mjk25r5luxu.ddns.net',
      'mv3254mxa0uxu4cvkjgdg83.ddns.net',
    ],
  );
  check(
    'proslikefan',
    await gen(const ProslikefanDGA()),
    const [
      'gxguijagrkt.com',
      'megiujkh.net',
      'sxfngve.biz',
      'bnlctch.ru',
      'nlppkpjcss.cc',
    ],
  );
  check(
    'kraken',
    await gen(const KrakenDGA()),
    const [
      'klrbvjtb.com',
      'uaazieqmts.com',
      'zoipmnwr.net',
      'jbtobfdwjfzp.net',
      'smmyuhxlt.tv',
    ],
  );
  check(
    'pykspa',
    await gen(const PykspaDGA()),
    const [
      'ycaywwiugkeq.info',
      'fqouxifox.cc',
      'rktqeifox.com',
      'cyygawiq.info',
      'uismsmiq.biz',
    ],
  );
}
