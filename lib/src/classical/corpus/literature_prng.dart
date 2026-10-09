/// Literature-faithful PRNG primitives used by classical P1/P2 re-keys.
///
/// Sourced from public open reimplementations (baderj/domain_generation_algorithms
/// and bin.re write-ups). Lab-only — no malware samples.
library;

/// Park–Miller / MINSTD LCG used by Ramnit and DirCrypt (baderj).
///
/// Step: `x ← (16807·(x mod 127773) − 2836·⌊x/127773⌋) mod 2³²`
class ParkMillerLcg {
  int value;

  ParkMillerLcg(int seed) : value = seed & 0xFFFFFFFF;

  /// Advance and return `value % modulus` (modulus > 0).
  int randIntModulus(int modulus) {
    if (modulus <= 0) {
      throw ArgumentError.value(modulus, 'modulus', 'must be > 0');
    }
    final ix = value;
    var lcg = (16807 * (ix % 127773) - 2836 * (ix ~/ 127773)) & 0xFFFFFFFF;
    value = lcg;
    return lcg % modulus;
  }
}

/// Nymaim-style 4-word PRNG seeded from calendar fields (baderj/nymaim).
class NymaimPrng {
  final List<int> r = List<int>.filled(4, 0);

  NymaimPrng(DateTime date) {
    // isoweekday % 7: Mon=1…Sun=7 → 1…0 (matches Python datetime.isoweekday()%7)
    final iso = date.weekday; // Dart: Mon=1…Sun=7 (same as Python isoweekday)
    final s = date.year + (date.month << 16) + (iso % 7) + (date.day << 16);
    r[0] = (s + 0x52455641) & 0xFFFFFFFF; // 'REVA'
    var r1 = s + 0x49484F4C; // 'IHOL'
    r[1] = r1 <= 0xFFFFFFFF ? r1 : 0;
    r[2] = (s + 0x59554820) & 0xFFFFFFFF; // 'YUH '
    r[3] = (s + 0x4D415620) & 0xFFFFFFFF; // 'MAV '
  }

  int rand(int m) {
    final t0 = ((r[0] << 11) ^ r[0]) & 0xFFFFFFFF;
    var t3 = ((r[3] >> 19) ^ r[3]) ^ t0;
    t3 = t3 ^ (t0 >> 8);
    t3 &= 0xFFFFFFFF;

    final c = r[2];
    for (var i = 0; i < 3; i++) {
      r[i] = (r[i] + r[i + 1]) & 0xFFFFFFFF;
    }
    r[3] = t3;

    final nr = ((((c + t3) & 0xFFFFFFFF) ~/ 100) % m);
    return nr;
  }
}

/// Vawtrak glibc-style LCG (baderj/vawtrak): `x ← (1103515245·x + 12345) & 0x7FFFFFFF`.
class VawtrakLcg {
  int state;

  VawtrakLcg(int seed) : state = seed & 0xFFFFFFFF;

  int rand() {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    return state;
  }
}

/// Wrap to signed int32 (ctypes `c_int` assignment parity).
int asInt32(int x) {
  final u = x & 0xFFFFFFFF;
  return u >= 0x80000000 ? u - 0x100000000 : u;
}

/// Proslikefan Java-style string hash (baderj/proslikefan) as signed 32-bit.
int proslikefanHashString(String s) {
  var h = 0;
  for (final cu in s.codeUnits) {
    // h = (h << 5) - h + c  with c_int wrap each step
    h = asInt32((h << 5) - h + cu);
  }
  return h;
}

int proslikefanAbsHash(String s) => proslikefanHashString(s).abs();

/// Corebot Numerical Recipes LCG (baderj/corebot): `x ← (1664525·x + 1013904223) mod 2³²`.
class CorebotLcg {
  int state;

  CorebotLcg(int seed) : state = seed & 0xFFFFFFFF;

  int next() {
    state = (1664525 * state + 1013904223) & 0xFFFFFFFF;
    return state;
  }
}

/// Kraken-style helpers (baderj/kraken v1/v2).
int krakenRand(int r) => (1103515245 * r + 12435) & 0xFFFFFFFF;

int krakenCrop(int r) => (r ~/ 256) % 32768;

/// Fold product high/low 32-bit halves (Ramnit reseed).
int ramnitReseed(int firstSeed, int secondSeed) {
  final a = BigInt.from(firstSeed & 0xFFFFFFFF);
  final b = BigInt.from(secondSeed & 0xFFFFFFFF);
  final product = a * b;
  final folded = product + (product >> 32);
  return (folded & BigInt.from(0xFFFFFFFF)).toInt();
}
