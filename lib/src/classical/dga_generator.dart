import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pqdga/src/classical/algorithms/arithmetic_dga.dart';
import 'package:pqdga/src/classical/algorithms/bamital_dga.dart';
import 'package:pqdga/src/classical/algorithms/banjori_dga.dart';
import 'package:pqdga/src/classical/algorithms/conficker_dga.dart';
import 'package:pqdga/src/classical/algorithms/corebot_dga.dart';
import 'package:pqdga/src/classical/algorithms/cryptolocker_dga.dart';
import 'package:pqdga/src/classical/algorithms/dictionary_based_dga.dart';
import 'package:pqdga/src/classical/algorithms/dircrypt_dga.dart';
import 'package:pqdga/src/classical/algorithms/emotet_dga.dart';
import 'package:pqdga/src/classical/algorithms/fast_flux_dga.dart';
import 'package:pqdga/src/classical/algorithms/idn_dga.dart';
import 'package:pqdga/src/classical/algorithms/kraken_dga.dart';
import 'package:pqdga/src/classical/algorithms/locky_dga.dart';
import 'package:pqdga/src/classical/algorithms/markov_dga.dart';
import 'package:pqdga/src/classical/algorithms/matsnu_dga.dart';
import 'package:pqdga/src/classical/algorithms/multi_channel_dga.dart';
import 'package:pqdga/src/classical/algorithms/murofet_dga.dart';
import 'package:pqdga/src/classical/algorithms/necurs_dga.dart';
import 'package:pqdga/src/classical/algorithms/nested_label_dga.dart';
import 'package:pqdga/src/classical/algorithms/nymaim_dga.dart';
import 'package:pqdga/src/classical/algorithms/oracle_seed_dga.dart';
import 'package:pqdga/src/classical/algorithms/permutation_dga.dart';
import 'package:pqdga/src/classical/algorithms/proslikefan_dga.dart';
import 'package:pqdga/src/classical/algorithms/pushdo_dga.dart';
import 'package:pqdga/src/classical/algorithms/pykspa_dga.dart';
import 'package:pqdga/src/classical/algorithms/qakbot_dga.dart';
import 'package:pqdga/src/classical/algorithms/ramnit_dga.dart';
import 'package:pqdga/src/classical/algorithms/ranbyus_dga.dart';
import 'package:pqdga/src/classical/algorithms/rovnix_dga.dart';
import 'package:pqdga/src/classical/algorithms/shiotob_dga.dart';
import 'package:pqdga/src/classical/algorithms/simda_dga.dart';
import 'package:pqdga/src/classical/algorithms/suppobox_dga.dart';
import 'package:pqdga/src/classical/algorithms/time_based_dga.dart';
import 'package:pqdga/src/classical/algorithms/tinba_dga.dart';
import 'package:pqdga/src/classical/algorithms/torpig_dga.dart';
import 'package:pqdga/src/classical/algorithms/vawtrak_dga.dart';
import 'package:pqdga/src/classical/dga_config.dart';
import 'package:pqdga/src/classical/dga_core.dart';
import 'package:pqdga/src/classical/dga_result.dart';
import 'package:pqdga/src/classical/corpus/literature_prng.dart';
import 'package:pqdga/src/common/classical_soc_metadata.dart';
import 'package:pqdga/src/common/multi_channel_codec.dart';
import 'package:pqdga/src/common/predictability.dart';
import 'package:pointycastle/export.dart';

/// Classical family handler for registry dispatch.
typedef DGAHandler =
    DGAResult Function(
      DGAGenerator generator,
      DateTime date,
      int count,
      DGAAlgorithm algorithm,
    );

/// Main Generator Logic using PointyCastle
class DGAGenerator {
  final DGAConfig config;

  static const String _vowels = "aeiou";
  static const String _consonants = "bcdfghjklmnpqrstvwxyz";
  static const String _charset = "abcdefghijklmnopqrstuvwxyz0123456789";
  static const String _charsetAlpha = "abcdefghijklmnopqrstuvwxyz";

  /// Type → handler registry. New families register here (no central if-ladder).
  static final Map<Type, DGAHandler> registry = {
    MatsnuDGA: (g, d, c, a) => g._generateMatsnu(d, c, a as MatsnuDGA),
    NecursDGA: (g, d, c, a) => g._generateNecurs(d, c, a as NecursDGA),
    PushdoDGA: (g, d, c, a) => g._generatePushdo(d, c, a as PushdoDGA),
    ConfickerDGA: (g, d, c, a) => g._generateConficker(d, c, a as ConfickerDGA),
    RovnixDGA: (g, d, c, a) => g._generateRovnix(d, c, a as RovnixDGA),
    CryptoLockerDGA: (g, d, c, a) =>
        g._generateCryptoLocker(d, c, a as CryptoLockerDGA),
    BamitalDGA: (g, d, c, a) => g._generateBamital(d, c, a as BamitalDGA),
    TinbaDGA: (g, d, c, a) => g._generateTinba(d, c, a as TinbaDGA),
    MurofetDGA: (g, d, c, a) => g._generateMurofet(d, c, a as MurofetDGA),
    SimdaDGA: (g, d, c, a) => g._generateSimda(d, c, a as SimdaDGA),
    TimeBasedDGA: (g, d, c, a) => g._generateTimeBased(d, c, a as TimeBasedDGA),
    DictionaryBasedDGA: (g, d, c, a) =>
        g._generateDictionaryBased(d, c, a as DictionaryBasedDGA),
    ArithmeticDGA: (g, d, c, a) =>
        g._generateArithmetic(d, c, a as ArithmeticDGA),
    PermutationDGA: (g, d, c, a) =>
        g._generatePermutation(d, c, a as PermutationDGA),
    LockyDGA: (g, d, c, a) => g._generateLocky(d, c, a as LockyDGA),
    QakBotDGA: (g, d, c, a) => g._generateQakBot(d, c, a as QakBotDGA),
    SuppoboxDGA: (g, d, c, a) => g._generateSuppobox(d, c, a as SuppoboxDGA),
    BanjoriDGA: (g, d, c, a) => g._generateBanjori(d, c, a as BanjoriDGA),
    RanbyusDGA: (g, d, c, a) => g._generateRanbyus(d, c, a as RanbyusDGA),
    // R8 research generics
    MarkovDGA: (g, d, c, a) => g._generateMarkov(d, c, a as MarkovDGA),
    IdnDGA: (g, d, c, a) => g._generateIdn(d, c, a as IdnDGA),
    OracleSeedDGA: (g, d, c, a) =>
        g._generateOracleSeed(d, c, a as OracleSeedDGA),
    NestedLabelDGA: (g, d, c, a) =>
        g._generateNestedLabel(d, c, a as NestedLabelDGA),
    MultiChannelDGA: (g, d, c, a) =>
        g._generateMultiChannel(d, c, a as MultiChannelDGA),
    FastFluxDGA: (g, d, c, a) => g._generateFastFlux(d, c, a as FastFluxDGA),
    // Classical P1
    RamnitDGA: (g, d, c, a) => g._generateRamnit(d, c, a as RamnitDGA),
    NymaimDGA: (g, d, c, a) => g._generateNymaim(d, c, a as NymaimDGA),
    ShiotobDGA: (g, d, c, a) => g._generateShiotob(d, c, a as ShiotobDGA),
    PykspaDGA: (g, d, c, a) => g._generatePykspa(d, c, a as PykspaDGA),
    VawtrakDGA: (g, d, c, a) => g._generateVawtrak(d, c, a as VawtrakDGA),
    EmotetDGA: (g, d, c, a) => g._generateEmotet(d, c, a as EmotetDGA),
    // Classical P2
    KrakenDGA: (g, d, c, a) => g._generateKraken(d, c, a as KrakenDGA),
    TorpigDGA: (g, d, c, a) => g._generateTorpig(d, c, a as TorpigDGA),
    CoreBotDGA: (g, d, c, a) => g._generateCoreBot(d, c, a as CoreBotDGA),
    DirCryptDGA: (g, d, c, a) => g._generateDirCrypt(d, c, a as DirCryptDGA),
    ProslikefanDGA: (g, d, c, a) =>
        g._generateProslikefan(d, c, a as ProslikefanDGA),
  };

  DGAGenerator(this.config);

  /// Main generation entry point (registry dispatch).
  Future<DGAResult> generateDomains(DateTime date, int count) async {
    final algo = config.algorithm;
    final handler = registry[algo.runtimeType];
    if (handler == null) {
      throw UnimplementedError(
        'Algorithm not implemented: ${algo.runtimeType}',
      );
    }
    return handler(this, date, count, algo);
  }

  // --- Matsnu (MD5 based) ---
  DGAResult _generateMatsnu(DateTime date, int count, MatsnuDGA algo) {
    final domains = <String>[];
    final dateStr =
        "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";

    // PointyCastle MD5
    final digest = MD5Digest();
    final hashBytes = digest.process(Uint8List.fromList(utf8.encode(dateStr)));
    final hexString = hashBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    for (int i = 0; i < count; i++) {
      final startPos = (i * 2) % (hexString.length - algo.domainLength);
      final domainPart = hexString.substring(
        startPos,
        startPos + algo.domainLength,
      );
      final tld = algo.tld[i % algo.tld.length];
      domains.add("$domainPart$tld");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Matsnu",
      seed: dateStr,
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.trivial,
        charset: 'hex',
        lengthMin: algo.domainLength,
        lengthMax: algo.domainLength,
        tldSet: algo.tld,
        seedPacking: 'YYYYMMDD string → MD5 hex substrings',
        prng: 'md5',
        socLesson:
            'High hex_ratio labels; MD5(date) stream is fully precomputable.',
        extra: {'md5': hexString},
      ),
    );
  }

  // --- Necurs (Custom PRNG) ---
  DGAResult _generateNecurs(DateTime date, int count, NecursDGA algo) {
    final domains = <String>[];
    final seed = (date.year * 10000) + (date.month * 100) + date.day;
    int prngState = seed;

    int nextPRNG() {
      prngState = (prngState * 214013 + 2531011) & 0xFFFFFFFF;
      return (prngState >> 16) & 0x7FFF;
    }

    for (int i = 0; i < count; i++) {
      final length =
          algo.minDomainLength +
          (nextPRNG() % (algo.maxDomainLength - algo.minDomainLength + 1));
      final buffer = StringBuffer();

      if (algo.usePronounceablePattern) {
        bool useConsonant = (nextPRNG() % 2) == 0;
        for (int j = 0; j < length; j++) {
          final charset = useConsonant ? _consonants : _vowels;
          buffer.write(charset[nextPRNG() % charset.length]);
          if (nextPRNG() % 10 < 8) useConsonant = !useConsonant;
        }
      } else {
        for (int j = 0; j < length; j++) {
          buffer.write(_charsetAlpha[nextPRNG() % _charsetAlpha.length]);
        }
      }
      final tld = algo.tld[nextPRNG() % algo.tld.length];
      domains.add("${buffer.toString()}$tld");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Necurs",
      seed: seed.toString(),
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.trivial,
        charset: algo.usePronounceablePattern
            ? 'pronounceable CV (a-z)'
            : 'a-z',
        lengthMin: algo.minDomainLength,
        lengthMax: algo.maxDomainLength,
        tldSet: algo.tld,
        seedPacking: 'year*10000+month*100+day',
        prng: 'msvc_lcg_214013_2531011',
        domainsPerDay: algo.domainsPerDay,
        socLesson:
            'Date-only LCG; vowel/consonant transitions fingerprint pronounceable mode.',
        extra: {'use_pronounceable_pattern': algo.usePronounceablePattern},
      ),
    );
  }

  // --- Pushdo (LCG) ---
  DGAResult _generatePushdo(DateTime date, int count, PushdoDGA algo) {
    final domains = <String>[];
    int seed = ((date.year << 16) | (date.month << 8) | date.day) & 0xFFFFFFFF;
    final charset = algo.includeNumbers ? _charset : _charsetAlpha;

    for (int i = 0; i < count; i++) {
      final buffer = StringBuffer();
      for (int j = 0; j < algo.domainLength; j++) {
        seed = (algo.lcgMultiplier * seed + algo.lcgIncrement) & 0xFFFFFFFF;
        final charIndex = (seed >> 16) % charset.length;
        buffer.write(charset[charIndex]);
      }
      final tld = algo.tld[i % algo.tld.length];
      domains.add("${buffer.toString()}$tld");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Pushdo",
      seed: seed.toString(),
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.trivial,
        charset: algo.includeNumbers ? 'a-z0-9' : 'a-z',
        lengthMin: algo.domainLength,
        lengthMax: algo.domainLength,
        tldSet: algo.tld,
        seedPacking: '(year<<16)|(month<<8)|day then LCG',
        prng: 'lcg_${algo.lcgMultiplier}_${algo.lcgIncrement}',
        socLesson:
            'Fixed-length LCG labels; multi-TLD rotation is a batch IOC.',
        extra: {
          'include_numbers': algo.includeNumbers,
          'lcg_multiplier': algo.lcgMultiplier,
          'lcg_increment': algo.lcgIncrement,
        },
      ),
    );
  }

  // --- Conficker (MD5 + LCG) ---
  DGAResult _generateConficker(DateTime date, int count, ConfickerDGA algo) {
    final domains = <String>[];
    // Approximate week number for research
    int weekOfYear = ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7)
        .ceil();

    final seedStr = algo.useWeekSeed
        ? "${date.year}${date.month}${date.day}$weekOfYear"
        : "${date.year}${date.month}${date.day}";

    final digest = MD5Digest();
    final hashBytes = digest.process(Uint8List.fromList(utf8.encode(seedStr)));

    int seedValue = 0;
    for (var b in hashBytes.take(8)) {
      seedValue = (seedValue << 8) | (b & 0xFF);
    }
    int seed = seedValue & 0xFFFFFFFF;

    for (int i = 0; i < count; i++) {
      seed = (seed * 1103515245 + 12345) & 0xFFFFFFFF;
      final length =
          algo.minDomainLength +
          ((seed >> 16) % (algo.maxDomainLength - algo.minDomainLength + 1));

      final buffer = StringBuffer();
      int tempSeed = seed;
      for (int j = 0; j < length; j++) {
        tempSeed = (tempSeed * 1103515245 + 12345) & 0xFFFFFFFF;
        final charIndex = (tempSeed >> 16) % _charsetAlpha.length;
        buffer.write(_charsetAlpha[charIndex]);
      }
      final tldIndex = (seed >> 8) % algo.tld.length;
      domains.add("${buffer.toString()}${algo.tld[tldIndex]}");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Conficker-${algo.variant}",
      seed: seedStr,
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.trivial,
        charset: 'a-z',
        lengthMin: algo.minDomainLength,
        lengthMax: algo.maxDomainLength,
        tldSet: algo.tld,
        seedPacking: algo.useWeekSeed
            ? 'year+month+day+weekOfYear → MD5 → LCG'
            : 'year+month+day → MD5 → LCG',
        prng: 'md5_seed+glibc_lcg',
        domainsPerDay: algo.domainsPerDay,
        socLesson:
            'High daily volume + multi-TLD bursts; week buckets when useWeekSeed.',
        extra: {
          'variant': algo.variant,
          'use_week_seed': algo.useWeekSeed,
          'week_of_year': weekOfYear,
        },
      ),
    );
  }

  // --- Rovnix (CRC32 + LCG) ---
  DGAResult _generateRovnix(DateTime date, int count, RovnixDGA algo) {
    final domains = <String>[];
    final dateStr = "${date.year}${date.month}${date.day}";
    int seed = _calculateCRC32(dateStr);

    for (int i = 0; i < count; i++) {
      seed = (seed * 1103515245 + 12345) & 0xFFFFFFFF;
      final length =
          algo.minDomainLength +
          ((seed >> 16) % (algo.maxDomainLength - algo.minDomainLength + 1));

      final buffer = StringBuffer();
      int tempSeed = seed + i;
      bool useConsonant = (tempSeed & 1) == 1;

      for (int j = 0; j < length; j++) {
        tempSeed = (tempSeed * 1103515245 + 12345) & 0xFFFFFFFF;
        final charset = useConsonant ? _consonants : _vowels;
        buffer.write(charset[(tempSeed >> 16) % charset.length]);
        useConsonant = (tempSeed % 10) < 6;
      }
      final tldIndex = (seed + i) % algo.tld.length;
      domains.add("${buffer.toString()}${algo.tld[tldIndex]}");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Rovnix-${algo.variant}",
      seed: seed.toString(),
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.trivial,
        charset: 'pronounceable CV (a-z)',
        lengthMin: algo.minDomainLength,
        lengthMax: algo.maxDomainLength,
        tldSet: algo.tld,
        seedPacking: 'CRC32(year+month+day) → LCG',
        prng: 'crc32+glibc_lcg',
        socLesson:
            'CRC32 date seed + CV pattern; variant string is catalog IOC.',
        extra: {'variant': algo.variant},
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CRYPTOLOCKER Implementation
  // -------------------------------------------------------------------------
  DGAResult _generateCryptoLocker(
    DateTime date,
    int count,
    CryptoLockerDGA algo,
  ) {
    final domains = <String>[];
    // Seed = (year + 0x1234) * (month + day)
    final seed = ((date.year + algo.seedConstant) * (date.month + date.day));
    int state = seed;

    for (int i = 0; i < count; i++) {
      // PRNG
      state = ((state * 1664525 + 1013904223) & 0xFFFFFFFF);

      final length =
          algo.minDomainLength +
          ((state >> 16) % (algo.maxDomainLength - algo.minDomainLength + 1));

      final buffer = StringBuffer();
      int tempState = state + i;

      for (int j = 0; j < length; j++) {
        tempState = ((tempState * 1664525 + 1013904223) & 0xFFFFFFFF);
        final charIndex = (tempState >> 16) % _charsetAlpha.length;
        buffer.write(_charsetAlpha[charIndex]);
      }

      final tldIndex = (state + i) % algo.tld.length;
      domains.add("${buffer.toString()}${algo.tld[tldIndex]}");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "CryptoLocker",
      seed: seed.toString(),
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.trivial,
        charset: 'a-z',
        lengthMin: algo.minDomainLength,
        lengthMax: algo.maxDomainLength,
        tldSet: algo.tld,
        seedPacking: '(year+seedConstant)*(month+day)',
        prng: 'numerical_recipes_lcg_1664525',
        socLesson:
            'Ransomware-era daily sets; arithmetic date seed is trivial.',
        extra: {'seed_constant': algo.seedConstant},
      ),
    );
  }

  // -------------------------------------------------------------------------
  // BAMITAL Implementation
  // -------------------------------------------------------------------------
  DGAResult _generateBamital(DateTime date, int count, BamitalDGA algo) {
    final domains = <String>[];
    // Seed: (year << 9) | (month << 5) | day
    final seed = ((date.year << 9) | (date.month << 5) | date.day);
    final rnd = Random(seed);

    for (int i = 0; i < count; i++) {
      final buffer = StringBuffer();
      // 70% chance for 2 words, 30% for 3 words
      final wordCount = rnd.nextInt(10) < 7 ? 2 : 3;

      for (int w = 0; w < wordCount; w++) {
        buffer.write(algo.wordList[rnd.nextInt(algo.wordList.length)]);
      }

      if (algo.appendNumbers && rnd.nextInt(10) < 3) {
        buffer.write(rnd.nextInt(90) + 10); // 10-99
      }

      final tld = algo.tld[rnd.nextInt(algo.tld.length)];
      domains.add("${buffer.toString()}$tld");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Bamital",
      seed: seed.toString(),
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.configSeeded,
        charset: 'dictionary',
        tldSet: algo.tld,
        seedPacking: '(year<<9)|(month<<5)|day → Random',
        prng: 'dart_Random_seeded',
        needsLexicalModel: true,
        needsConfigExtract: true,
        socLesson:
            'Wordlist composition defeats entropy-only rules; extract wordlist then precompute.',
        extra: {
          'wordlist_size': algo.wordList.length,
          'append_numbers': algo.appendNumbers,
          'wordlist_id': 'caller-supplied',
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TINBA Implementation
  // -------------------------------------------------------------------------
  DGAResult _generateTinba(DateTime date, int count, TinbaDGA algo) {
    final domains = <String>[];
    final dateSeed = ((date.year << 16) | (date.month << 8) | date.day);

    // Combine BotID with Date
    int seed = (algo.botId ^ dateSeed) & 0xFFFFFFFF;

    for (int i = 0; i < count; i++) {
      final buffer = StringBuffer();
      int state = seed + i;

      for (int j = 0; j < algo.domainLength; j++) {
        state =
            ((state * algo.prngMultiplier + algo.prngIncrement) & 0xFFFFFFFF);
        // Extract char from high bits
        final val = (state >> 16);
        buffer.write(_charset[val % _charset.length]);
      }

      final tldIndex = (seed + i) % algo.tld.length;
      domains.add("${buffer.toString()}${algo.tld[tldIndex]}");

      // Update seed for next domain
      seed = ((seed * algo.prngMultiplier + algo.prngIncrement) & 0xFFFFFFFF);
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Tinba",
      seed: "${algo.botId}",
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.configSeeded,
        charset: 'a-z0-9',
        lengthMin: algo.domainLength,
        lengthMax: algo.domainLength,
        tldSet: algo.tld,
        seedPacking: 'botId XOR (year<<16|month<<8|day)',
        prng: 'lcg_${algo.prngMultiplier}_${algo.prngIncrement}',
        needsConfigExtract: true,
        socLesson:
            'Bot-id is a config IOC; short fixed-length alnum labels for banker context.',
        extra: {
          'bot_id': algo.botId,
          'prng_multiplier': algo.prngMultiplier,
          'prng_increment': algo.prngIncrement,
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // MUROFET Implementation
  // -------------------------------------------------------------------------
  DGAResult _generateMurofet(DateTime date, int count, MurofetDGA algo) {
    final domains = <String>[];
    // Defaulting to hour 0 for daily generation simulation
    const hour = 0;

    int seed;
    if (algo.useHourlySeed) {
      seed =
          ((date.year << 21) |
          (date.month << 17) |
          (date.day << 12) |
          (hour << 7));
    } else {
      seed = ((date.year << 21) | (date.month << 17) | (date.day << 12));
    }
    seed &= 0xFFFFFFFF;
    int state = seed;

    for (int i = 0; i < count; i++) {
      // Hash function step
      state = ((state * 214013 + 2531011) & 0xFFFFFFFF);

      final length =
          algo.minDomainLength +
          ((state >> 16) % (algo.maxDomainLength - algo.minDomainLength + 1));

      final buffer = StringBuffer();
      int tempState = state + i;

      for (int j = 0; j < length; j++) {
        tempState = ((tempState * 214013 + 2531011) & 0xFFFFFFFF);
        final charIndex = (tempState >> 16) % _charsetAlpha.length;
        buffer.write(_charsetAlpha[charIndex]);
      }

      final tldIndex = (state + i) % algo.tld.length;
      domains.add("${buffer.toString()}${algo.tld[tldIndex]}");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Murofet",
      seed: seed.toString(),
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.trivial,
        charset: 'a-z',
        lengthMin: algo.minDomainLength,
        lengthMax: algo.maxDomainLength,
        tldSet: algo.tld,
        seedPacking: algo.useHourlySeed
            ? 'year/month/day/hour bit-pack'
            : 'year/month/day bit-pack',
        prng: 'msvc_lcg_214013_2531011',
        socLesson:
            'Hourly seed mode shrinks sinkhole windows; still date/hour public.',
        extra: {'use_hourly_seed': algo.useHourlySeed},
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SIMDA Implementation
  // -------------------------------------------------------------------------
  DGAResult _generateSimda(DateTime date, int count, SimdaDGA algo) {
    final domains = <String>[];
    // XOR Based seed
    final seed =
        ((date.year ^ algo.xorConstant) + (date.month ^ date.day)) & 0xFFFFFFFF;
    int state = seed;

    int limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;

    for (int i = 0; i < limit; i++) {
      state = ((state * 1103515245 + 12345) & 0xFFFFFFFF);

      final buffer = StringBuffer();
      int tempState = state + i;

      for (int j = 0; j < algo.domainLength; j++) {
        tempState = ((tempState * 1103515245 + 12345) & 0xFFFFFFFF);
        final charIndex = (tempState >> 16) % _charset.length;
        buffer.write(_charset[charIndex]);
      }

      final tldIndex = i % algo.tld.length;
      domains.add("${buffer.toString()}${algo.tld[tldIndex]}");
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Simda",
      seed: seed.toString(),
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.configSeeded,
        charset: 'a-z0-9',
        lengthMin: algo.domainLength,
        lengthMax: algo.domainLength,
        tldSet: algo.tld,
        seedPacking: '(year XOR xorConstant)+(month XOR day)',
        prng: 'glibc_lcg',
        domainsPerDay: algo.domainsPerDay,
        needsConfigExtract: true,
        socLesson:
            'XOR constant is a YARA/config IOC; then date precompute works.',
        extra: {'xor_constant': algo.xorConstant},
      ),
    );
  }

  // -------------------------------------------------------------------------
  // GENERIC: TimeBased, Dictionary, Arithmetic, Permutation
  // -------------------------------------------------------------------------

  DGAResult _generateTimeBased(DateTime date, int count, TimeBasedDGA algo) {
    final domains = <String>[];
    final dateSeed = date.millisecondsSinceEpoch ~/ 86400000; // Epoch Day
    final digest = SHA256Digest();

    for (int i = 0; i < count; i++) {
      final input = "${algo.seed}-$dateSeed-$i";
      final hash = digest.process(Uint8List.fromList(utf8.encode(input)));

      // Calculate variable length
      final lenRange = config.maxDomainLength - config.minDomainLength;
      final len =
          config.minDomainLength + (hash[0] % (lenRange > 0 ? lenRange : 1));

      final buffer = StringBuffer();
      for (int j = 0; j < len; j++) {
        buffer.write(_charset[hash[j % hash.length] % _charset.length]);
      }

      final tld = algo.tld[hash.last % algo.tld.length];
      domains.add("${buffer.toString()}$tld");
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "TimeBased",
      seed: algo.seed,
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.configSeeded,
        charset: 'a-z0-9',
        lengthMin: config.minDomainLength,
        lengthMax: config.maxDomainLength,
        tldSet: algo.tld,
        seedPacking: 'SHA256(configSeed-epochDay-i)',
        prng: 'sha256',
        needsConfigExtract: true,
        socLesson:
            'Wall-clock epoch-day buckets; config seed string is the extract target.',
        extra: {'config_seed_string': algo.seed},
      ),
    );
  }

  DGAResult _generateDictionaryBased(
    DateTime date,
    int count,
    DictionaryBasedDGA algo,
  ) {
    // Simplistic random pick based on date seed
    final seed = (date.year << 9) | (date.month << 5) | date.day;
    final rnd = Random(seed);
    final domains = <String>[];

    for (int i = 0; i < count; i++) {
      final w1 = algo.wordList[rnd.nextInt(algo.wordList.length)];
      final w2 = algo.wordList[rnd.nextInt(algo.wordList.length)];
      final tld = algo.tld[rnd.nextInt(algo.tld.length)];
      domains.add("$w1$w2$tld");
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Dictionary",
      seed: "$seed",
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.configSeeded,
        charset: 'dictionary',
        tldSet: algo.tld,
        seedPacking: '(year<<9)|(month<<5)|day → Random word pairs',
        prng: 'dart_Random_seeded',
        needsLexicalModel: true,
        needsConfigExtract: true,
        socLesson:
            'English-looking concatenations defeat entropy rules; need wordlist + LM.',
        extra: {
          'wordlist_size': algo.wordList.length,
          'wordlist_id': 'caller-supplied',
        },
      ),
    );
  }

  DGAResult _generateArithmetic(DateTime date, int count, ArithmeticDGA algo) {
    final domains = <String>[];
    int seed = algo.seed + (date.millisecondsSinceEpoch ~/ 86400000);

    for (int i = 0; i < count; i++) {
      seed = (algo.multiplier * seed + algo.increment) % algo.modulus;
      final buffer = StringBuffer();
      // Simple generic generation
      int temp = seed;
      for (int j = 0; j < 10; j++) {
        // Fixed length 10 for generic
        temp = (algo.multiplier * temp + algo.increment) % algo.modulus;
        buffer.write(_charset[temp % _charset.length]);
      }
      domains.add("${buffer.toString()}.com");
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Arithmetic",
      seed: "${algo.seed}",
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.configSeeded,
        charset: 'a-z0-9',
        lengthMin: 10,
        lengthMax: 10,
        tldSet: const ['.com'],
        seedPacking: 'config_seed + epochDay → modular LCG',
        prng: 'mod_lcg_m${algo.modulus}',
        needsConfigExtract: true,
        socLesson:
            'Uniform fixed-length alnum; LCG constants are fingerprint IOCs.',
        extra: {
          'config_seed': algo.seed,
          'multiplier': algo.multiplier,
          'increment': algo.increment,
          'modulus': algo.modulus,
        },
      ),
    );
  }

  DGAResult _generatePermutation(
    DateTime date,
    int count,
    PermutationDGA algo,
  ) {
    final domains = <String>[];
    final dateSeed = date.millisecondsSinceEpoch ~/ 86400000;

    for (int i = 0; i < count; i++) {
      int seed = dateSeed + i;
      List<String> chars = algo.baseDomain.split('');
      final rnd = Random(seed);

      // Fisher-Yates Shuffle
      for (int k = chars.length - 1; k > 0; k--) {
        int n = rnd.nextInt(k + 1);
        var temp = chars[k];
        chars[k] = chars[n];
        chars[n] = temp;
      }
      domains.add("${chars.join()}.com");
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: "Permutation",
      seed: algo.baseDomain,
      metadata: ClassicalSocMetadata.build(
        predictability: PredictabilityClass.configSeeded,
        charset: 'permutation_of_base',
        lengthMin: algo.baseDomain.length,
        lengthMax: algo.baseDomain.length,
        tldSet: const ['.com'],
        seedPacking: 'epochDay+i → Fisher-Yates on baseDomain',
        prng: 'dart_Random_fisher_yates',
        needsConfigExtract: true,
        socLesson:
            'Finite permutation set of base string; exhaust when base known.',
        extra: {'base_domain': algo.baseDomain},
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P0: LOCKY (v2-style mul/ror PRNG)
  // -------------------------------------------------------------------------
  DGAResult _generateLocky(DateTime date, int count, LockyDGA algo) {
    final domains = <String>[];
    final lengths = <int>[];

    for (int domainNr = 0; domainNr < count; domainNr++) {
      final domain = _lockyDomain(date, algo, domainNr);
      domains.add(domain);
      lengths.add(domain.split('.').first.length);
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Locky-${algo.variant}',
      seed: 'cfg=${algo.seed},shift=${algo.shift},mod=${algo.mod}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': 'a-y',
          'length_min': 5,
          'length_max': 15,
          'length_samples': lengths,
          'tld_set': algo.tld,
          'prng': 'mul_ror_0xB11924E1',
          'seed_packing': 'year+const, optional cfg seed, day//2, month',
          'config_seed': algo.seed,
          'domains_per_window': algo.domainsPerWindow,
        },
        predictability: PredictabilityClass.trivial,
        socLesson:
            'Known default cfg → full precompute; a-y charset + length 5–15 bands.',
      ),
    );
  }

  String _lockyDomain(DateTime date, LockyDGA algo, int domainNr) {
    final shift = algo.shift;
    final seed = algo.seed & 0xFFFFFFFF;

    int t = _ror32(_mul32(0xB11924E1, date.year + 0x1BF5), shift);
    if (seed != 0) {
      t = _ror32(_mul32(0xB11924E1, t + seed + 0x27100001), shift);
    }
    t = _ror32(_mul32(0xB11924E1, t + (date.day ~/ 2) + 0x27100001), shift);
    t = _ror32(_mul32(0xB11924E1, t + date.month + 0x2709A354), shift);

    final nr = _rol32(domainNr % algo.mod, 21);
    final s = _rol32(seed, 17);
    var r =
        (_ror32(_mul32(0xB11924E1, nr + t + s + 0x27100001), shift) +
            0x27100001) &
        0xFFFFFFFF;
    final length = (r % 11) + 5;

    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      r =
          (_ror32(_mul32(0xB11924E1, _rol32(r, i)), shift) + 0x27100001) &
          0xFFFFFFFF;
      buffer.writeCharCode((r % 25) + 0x61); // a-y
    }

    r = _ror32(_mul32(r, 0xB11924E1), shift);
    final tldIndex = ((r + 0x27100001) & 0xFFFFFFFF) % algo.tld.length;
    return '${buffer.toString()}.${algo.tld[tldIndex]}';
  }

  // -------------------------------------------------------------------------
  // P0: QAKBOT (CRC32 date seed + MT19937)
  // -------------------------------------------------------------------------
  DGAResult _generateQakBot(DateTime date, int count, QakBotDGA algo) {
    final seedMaterial = _qakbotDateSeedString(date, algo.configSeed);
    final crc = _calculateCRC32(seedMaterial);
    final mtSeed = (crc + (algo.sandbox ? 1 : 0)) & 0xFFFFFFFF;
    final mt = _MT19937(mtSeed);

    final domains = <String>[];
    final lengths = <int>[];

    for (int i = 0; i < count; i++) {
      final tldNr = mt.randInt(0, algo.tld.length - 1);
      final length = mt.randInt(algo.minDomainLength, algo.maxDomainLength);
      final buffer = StringBuffer();
      for (int l = 0; l < length; l++) {
        buffer.writeCharCode(mt.randInt(0, 25) + 0x61);
      }
      lengths.add(length);
      domains.add('${buffer.toString()}.${algo.tld[tldNr]}');
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'QakBot',
      seed: seedMaterial,
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': 'a-z',
          'length_min': algo.minDomainLength,
          'length_max': algo.maxDomainLength,
          'length_samples': lengths,
          'tld_set': algo.tld,
          'prng': 'MT19937',
          'seed_packing': 'CRC32(dayBucket.mon.year.configSeedHex)',
          'config_seed': algo.configSeed,
          'mt_seed': mtSeed,
          'sandbox': algo.sandbox,
          'domains_per_month_hint': algo.domainsPerMonthHint,
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Extract config seed then MT19937 precompute; TLD diversity + NX storms.',
      ),
    );
  }

  String _qakbotDateSeedString(DateTime date, int configSeed) {
    var dx = (date.day - 1) ~/ 10;
    if (dx > 2) dx = 2;
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    final mon = months[date.month - 1];
    final seedHex = configSeed.toRadixString(16).padLeft(8, '0');
    return '$dx.$mon.${date.year}.$seedHex';
  }

  // -------------------------------------------------------------------------
  // P0: SUPPOBOX-style (two-word bit-shuffle dictionary)
  // -------------------------------------------------------------------------
  DGAResult _generateSuppobox(DateTime date, int count, SuppoboxDGA algo) {
    if (algo.wordList.length < 256) {
      throw ArgumentError(
        'SuppoboxDGA.wordList must contain at least 256 words '
        '(got ${algo.wordList.length}); literature lists are 384.',
      );
    }

    final unix =
        algo.unixSeconds ?? date.toUtc().millisecondsSinceEpoch ~/ 1000;
    var seed = unix >> 9;
    final domains = <String>[];
    const shuffle = [3, 9, 13, 6, 2, 4, 11, 7, 14, 1, 10, 5, 8, 12, 0];

    final limit = count > algo.domainsPerWindow ? algo.domainsPerWindow : count;
    for (int c = 0; c < limit; c++) {
      var nr = seed;
      final res = List<int>.filled(16, 0);
      for (int i = 0; i < 15; i++) {
        res[shuffle[i]] = nr & 1;
        nr >>= 1;
      }

      var firstWordIndex = 0;
      for (int i = 0; i < 7; i++) {
        firstWordIndex = (firstWordIndex << 1) ^ res[i];
      }
      var secondWordIndex = 0;
      for (int i = 7; i < 15; i++) {
        secondWordIndex = (secondWordIndex << 1) ^ res[i];
      }
      secondWordIndex += 0x80;

      final w1 = algo.wordList[firstWordIndex % algo.wordList.length];
      final w2 = algo.wordList[secondWordIndex % algo.wordList.length];
      domains.add('$w1$w2${algo.tld}');
      seed += 1;
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Suppobox',
      seed: 'unix>>9 base=${unix >> 9}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': 'dictionary',
          'tld_set': [algo.tld],
          'seed_packing': 'unix_seconds>>9 then increment',
          'wordlist_id': 'caller-supplied',
          'wordlist_size': algo.wordList.length,
          'unix_seconds': unix,
          'needs_lexical_model': true,
        },
        predictability: PredictabilityClass.configSeeded,
        needsLexicalModel: true,
        needsConfigExtract: true,
        socLesson:
            'Two-word English FQDNs defeat entropy rules; extract wordlist then precompute.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P0: BANJORI (first-four-letter mutation of seed domain)
  // -------------------------------------------------------------------------
  DGAResult _generateBanjori(DateTime date, int count, BanjoriDGA algo) {
    if (algo.seedDomain.length < 4) {
      throw ArgumentError(
        'BanjoriDGA.seedDomain must be at least 4 characters',
      );
    }

    final domains = <String>[];
    var domain = algo.seedDomain;

    if (algo.includeSeedDomain) {
      domains.add(domain);
    }

    while (domains.length < count) {
      domain = _banjoriNextDomain(domain);
      domains.add(domain);
    }

    // Trim if includeSeedDomain false and we overshot is impossible; if true and
    // count==0 edge — not needed. If includeSeed and count domains already ok.
    final out = domains.take(count).toList();

    return DGAResult(
      domains: out,
      generationDate: date,
      algorithm: 'Banjori',
      seed: algo.seedDomain,
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': 'a-z (first 4 mutate; tail fixed)',
          'seed_packing': 'hardcoded seed domain; date unused for generation',
          'prng': 'map_to_lowercase_letter 4-char recurrence',
          'date_affects_generation': false,
          'fixed_tail': algo.seedDomain.length > 4
              ? algo.seedDomain.substring(4)
              : '',
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Constant tail/TLD IOC; seed domain from sample restores full sequence.',
      ),
    );
  }

  String _banjoriNextDomain(String domain) {
    final dl = domain.codeUnits.toList();
    int mapToLower(int s) => 0x61 + ((s - 0x61) % 26);

    dl[0] = mapToLower(dl[0] + dl[3]);
    dl[1] = mapToLower(dl[0] + 2 * dl[1]);
    dl[2] = mapToLower(dl[0] + dl[2] - 1);
    dl[3] = mapToLower(dl[1] + dl[2] + dl[3]);
    return String.fromCharCodes(dl);
  }

  // -------------------------------------------------------------------------
  // P0: RANBYUS (May arithmetic variant)
  // -------------------------------------------------------------------------
  DGAResult _generateRanbyus(DateTime date, int count, RanbyusDGA algo) {
    if (algo.variant != 'may') {
      throw UnimplementedError(
        'Ranbyus variant "${algo.variant}" not implemented; use variant: "may"',
      );
    }

    // Work in unsigned 32-bit space matching the original C reimplementation.
    var day = date.day & 0xFFFFFFFF;
    var month = date.month & 0xFFFFFFFF;
    var year = date.year & 0xFFFFFFFF;
    var seed = algo.seed & 0xFFFFFFFF;
    var tldIndex = date.day;
    final domains = <String>[];

    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    // TLD rotation uses len-1 of literature table (8 of 9) as in original samples.
    final tldMod = algo.tld.length > 1 ? algo.tld.length - 1 : 1;

    for (int d = 0; d < limit; d++) {
      final buffer = StringBuffer();
      for (int i = 0; i < 14; i++) {
        day =
            ((day >> 15) ^ _mul32(16, (day & 0x1FFF) ^ _mul32(4, seed ^ day))) &
            0xFFFFFFFF;
        year =
            ((((year & 0xFFFFFFF0) << 17) & 0xFFFFFFFF) ^
                (((year ^ _mul32(7, year)) >> 11) & 0xFFFFFFFF)) &
            0xFFFFFFFF;
        month =
            (_mul32(14, month & 0xFFFFFFFE) ^
                (((month ^ _mul32(4, month)) >> 8) & 0xFFFFFFFF)) &
            0xFFFFFFFF;
        seed =
            ((seed >> 6) ^ ((((day + _mul32(8, seed)) << 8) & 0x3FFFF00))) &
            0xFFFFFFFF;
        final x = ((day ^ month ^ year) % 25) + 97;
        buffer.writeCharCode(x);
      }
      final tld = algo.tld[tldIndex % tldMod];
      tldIndex += 1;
      domains.add('${buffer.toString()}.$tld');
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Ranbyus-${algo.variant}',
      seed: '0x${algo.seed.toRadixString(16).padLeft(8, '0')}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': 'a-y',
          'length_min': 14,
          'length_max': 14,
          'tld_set': algo.tld,
          'prng': 'ranbyus_may_arithmetic',
          'seed_packing': 'day/month/year state + config seed dword',
          'config_seed': algo.seed,
          'domains_per_day': algo.domainsPerDay,
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Fixed length 14 a-y labels; config seed dword is the extract IOC.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // R8: MARKOV / n-gram LM
  // -------------------------------------------------------------------------
  DGAResult _generateMarkov(DateTime date, int count, MarkovDGA algo) {
    if (algo.charset.length < 2) {
      throw ArgumentError('MarkovDGA.charset must have at least 2 chars');
    }
    if (algo.minDomainLength < 1 ||
        algo.maxDomainLength < algo.minDomainLength) {
      throw ArgumentError('invalid Markov length bounds');
    }
    final seed = _dateSeed32(date) ^ (algo.seed & 0xFFFFFFFF);
    var state = seed;
    final domains = <String>[];
    // Fixed research bigram table: next-char preference by index offset.
    for (var i = 0; i < count; i++) {
      state = _lcg(state);
      final span = algo.maxDomainLength - algo.minDomainLength + 1;
      final length = algo.minDomainLength + ((state >> 16) % span);
      final buffer = StringBuffer();
      var prev = (state >> 8) % algo.charset.length;
      buffer.write(algo.charset[prev]);
      for (var j = 1; j < length; j++) {
        state = _lcg(state);
        // Prefer nearby alphabet neighbors (pronounceable-ish).
        final delta = ((state >> 16) % 5) - 2; // -2..+2
        var next = (prev + delta + algo.charset.length) % algo.charset.length;
        // Light vowel bias every other step for LM flavor.
        if (j.isOdd) {
          const vowels = 'aeiou';
          next = algo.charset.indexOf(vowels[(state >> 8) % vowels.length]);
          if (next < 0) next = (state >> 8) % algo.charset.length;
        }
        buffer.write(algo.charset[next]);
        prev = next;
      }
      final tld = _normTld(algo.tld[i % algo.tld.length]);
      domains.add('${buffer.toString()}$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Markov',
      seed: '0x${seed.toRadixString(16)}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': algo.charset,
          'length_min': algo.minDomainLength,
          'length_max': algo.maxDomainLength,
          'order': algo.order,
          'campaign_id': algo.campaignId,
          'prng': 'lcg+bigram_bias',
          'seed_packing': 'date32 xor config_seed',
          'needs_lexical_model': true,
        },
        predictability: PredictabilityClass.configSeeded,
        needsLexicalModel: true,
        needsConfigExtract: true,
        socLesson:
            'n-gram LM labels defeat entropy-only detectors; train lexical models.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // R8: IDN / homoglyph / punycode
  // -------------------------------------------------------------------------
  DGAResult _generateIdn(DateTime date, int count, IdnDGA algo) {
    final base = algo.baseWord.toLowerCase();
    if (base.isEmpty) {
      throw ArgumentError('IdnDGA.baseWord must be non-empty');
    }
    // Confusable map: ASCII -> single non-ASCII lookalike (lab set).
    const confusables = <String, String>{
      'a': 'а', // Cyrillic a
      'e': 'е', // Cyrillic e
      'o': 'о', // Cyrillic o
      'p': 'р', // Cyrillic er
      'c': 'с', // Cyrillic es
      'x': 'х', // Cyrillic ha
      'y': 'у', // Cyrillic u
      'i': 'і', // Ukrainian i
    };
    var state = _dateSeed32(date) ^ (algo.seed & 0xFFFFFFFF);
    final domains = <String>[];
    final unicodeLabels = <String>[];

    for (var i = 0; i < count; i++) {
      state = _lcg(state);
      final chars = base.split('');
      var subs = 0;
      final maxSubs = algo.maxSubstitutions.clamp(0, chars.length);
      for (var j = 0; j < chars.length && subs < maxSubs; j++) {
        state = _lcg(state);
        final ch = chars[j];
        if (confusables.containsKey(ch) && ((state >> 16) & 1) == 1) {
          chars[j] = confusables[ch]!;
          subs++;
        }
      }
      // Ensure at least one substitution for IDN path when possible.
      if (subs == 0) {
        for (var j = 0; j < chars.length; j++) {
          if (confusables.containsKey(chars[j])) {
            chars[j] = confusables[chars[j]]!;
            subs = 1;
            break;
          }
        }
      }
      final uLabel = chars.join();
      unicodeLabels.add(uLabel);
      final tld = _normTld(algo.tld[i % algo.tld.length]);
      if (algo.emitPunycode) {
        final aLabel = _toPunycodeLabel(uLabel);
        domains.add('$aLabel$tld');
      } else {
        domains.add('$uLabel$tld');
      }
    }

    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Idn',
      seed: base,
      metadata: ClassicalSocMetadata.enrich(
        {
          'base_word': base,
          'emit_punycode': algo.emitPunycode,
          'max_substitutions': algo.maxSubstitutions,
          'unicode_labels': unicodeLabels,
          'idn_abuse': true,
          'seed_packing': 'base_word + date32 xor seed',
          'tld_set': algo.tld,
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        needsIdnMonitoring: true,
        socLesson:
            'Homoglyph/IDN path; monitor xn-- and confusable scripts, not ASCII-only filters.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // R8: Oracle-seeded
  // -------------------------------------------------------------------------
  DGAResult _generateOracleSeed(DateTime date, int count, OracleSeedDGA algo) {
    final material = algo.oracleMaterial;
    if (material == null || material.isEmpty) {
      throw ArgumentError(
        'OracleSeedDGA.oracleMaterial required (public oracle bytes)',
      );
    }
    if (algo.charset.isEmpty) {
      throw ArgumentError('OracleSeedDGA.charset must be non-empty');
    }
    final digest = SHA256Digest();
    final packed = utf8.encode(
      '${algo.domainSeparator}|${algo.oracleId}|'
      '${date.toUtc().toIso8601String()}',
    );
    final input = Uint8List(material.length + packed.length);
    input.setAll(0, material);
    input.setAll(material.length, packed);
    final hash = digest.process(input);
    var state = 0;
    for (final b in hash.take(8)) {
      state = ((state << 8) | (b & 0xFF)) & 0xFFFFFFFF;
    }
    final domains = <String>[];
    for (var i = 0; i < count; i++) {
      state = _lcg(state);
      final span = algo.maxDomainLength - algo.minDomainLength + 1;
      final length = algo.minDomainLength + ((state >> 16) % span);
      final buffer = StringBuffer();
      var temp = state ^ i;
      for (var j = 0; j < length; j++) {
        temp = _lcg(temp);
        buffer.write(algo.charset[(temp >> 16) % algo.charset.length]);
      }
      final tld = _normTld(algo.tld[i % algo.tld.length]);
      domains.add('${buffer.toString()}$tld');
    }
    final oracleFp = hash
        .take(8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'OracleSeed',
      seed: 'oracle=${algo.oracleId};fp=$oracleFp',
      metadata: ClassicalSocMetadata.enrich(
        {
          'oracle_id': algo.oracleId,
          'oracle_material_length': material.length,
          'oracle_fingerprint': oracleFp,
          'charset': algo.charset,
          'length_min': algo.minDomainLength,
          'length_max': algo.maxDomainLength,
          'tld_set': algo.tld,
          'domain_separator': algo.domainSeparator,
        },
        predictability: PredictabilityClass.oracleSeeded,
        socLesson:
            'Cannot pure-date sinkhole; ingest oracle stream or use first-seen PDNS.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // R8: Nested labels
  // -------------------------------------------------------------------------
  DGAResult _generateNestedLabel(
    DateTime date,
    int count,
    NestedLabelDGA algo,
  ) {
    if (algo.labelDepth < 1) {
      throw ArgumentError('NestedLabelDGA.labelDepth must be >= 1');
    }
    if (algo.charset.isEmpty) {
      throw ArgumentError('NestedLabelDGA.charset must be non-empty');
    }
    var state = _dateSeed32(date) ^ (algo.seed & 0xFFFFFFFF);
    final domains = <String>[];
    for (var i = 0; i < count; i++) {
      final labels = <String>[];
      for (var d = 0; d < algo.labelDepth; d++) {
        state = _lcg(state);
        final span = algo.maxLabelLength - algo.minLabelLength + 1;
        final length = algo.minLabelLength + ((state >> 16) % span);
        final buf = StringBuffer();
        var temp = state + d + i;
        for (var j = 0; j < length; j++) {
          temp = _lcg(temp);
          buf.write(algo.charset[(temp >> 16) % algo.charset.length]);
        }
        labels.add(buf.toString());
      }
      if (algo.emitWildcardMarker && labels.isNotEmpty) {
        labels[0] = '*${labels[0]}';
      }
      final tld = _normTld(algo.tld[i % algo.tld.length]).substring(1);
      domains.add('${labels.join('.')}.$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'NestedLabel',
      seed: '0x${(algo.seed & 0xFFFFFFFF).toRadixString(16)}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'label_depth': algo.labelDepth,
          'length_min': algo.minLabelLength,
          'length_max': algo.maxLabelLength,
          'charset': algo.charset,
          'emit_wildcard_marker': algo.emitWildcardMarker,
          'structural_depth_ioc': true,
          'tld_set': algo.tld,
        },
        predictability: PredictabilityClass.trivial,
        socLesson:
            'Deep subdomain counts / wildcard markers are structural IOCs; DNS length limits constrain depth.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // R8: Multi-channel
  // -------------------------------------------------------------------------
  DGAResult _generateMultiChannel(
    DateTime date,
    int count,
    MultiChannelDGA algo,
  ) {
    if (algo.channels.isEmpty) {
      throw ArgumentError('MultiChannelDGA.channels must be non-empty');
    }
    if (algo.charset.isEmpty || algo.tokenLength < 1) {
      throw ArgumentError('invalid MultiChannel token config');
    }
    var state = _dateSeed32(date) ^ (algo.seed & 0xFFFFFFFF);
    final domains = <String>[];
    final channelEncodings = <Map<String, String>>[];
    for (var i = 0; i < count; i++) {
      state = _lcg(state);
      final buf = StringBuffer();
      var temp = state ^ i;
      for (var j = 0; j < algo.tokenLength; j++) {
        temp = _lcg(temp);
        buf.write(algo.charset[(temp >> 16) % algo.charset.length]);
      }
      final token = buf.toString();
      final tld = _normTld(algo.tld[i % algo.tld.length]);
      final encoded = MultiChannelCodec.encodeAll(
        token,
        channels: algo.channels,
        tld: tld,
      );
      channelEncodings.add(encoded);
      // Primary domains list uses DNS channel when present, else first channel.
      domains.add(
        encoded[MultiChannelCodec.channelDns] ?? encoded.values.first,
      );
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'MultiChannel',
      seed: algo.campaignId,
      metadata: ClassicalSocMetadata.enrich(
        {
          'campaign_id': algo.campaignId,
          'channels': algo.channels,
          'token_length': algo.tokenLength,
          'channel_encodings': channelEncodings,
          'charset': algo.charset,
          'tld_set': algo.tld,
          'needs_alt_channel_telemetry': true,
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        needsAltChannelTelemetry: true,
        socLesson:
            'DNS is one encoding of the same stream; extend monitoring to DoH/alt channels.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // R8: Fast-flux schedule coupling
  // -------------------------------------------------------------------------
  DGAResult _generateFastFlux(DateTime date, int count, FastFluxDGA algo) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('FastFluxDGA.charset must be non-empty');
    }
    var state = _dateSeed32(date) ^ (algo.seed & 0xFFFFFFFF);
    final domains = <String>[];
    for (var i = 0; i < count; i++) {
      state = _lcg(state);
      final span = algo.maxDomainLength - algo.minDomainLength + 1;
      final length = algo.minDomainLength + ((state >> 16) % span);
      final buf = StringBuffer();
      var temp = state + i;
      for (var j = 0; j < length; j++) {
        temp = _lcg(temp);
        buf.write(algo.charset[(temp >> 16) % algo.charset.length]);
      }
      final tld = _normTld(algo.tld[i % algo.tld.length]);
      domains.add('${buf.toString()}$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'FastFlux',
      seed: '0x${(algo.seed & 0xFFFFFFFF).toRadixString(16)}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': algo.charset,
          'length_min': algo.minDomainLength,
          'length_max': algo.maxDomainLength,
          'tld_set': algo.tld,
          ...algo.schedule.toMetadata(),
        },
        predictability: PredictabilityClass.trivial,
        needsFluxCorrelation: true,
        socLesson:
            'Pair NX/resolution with TTL + NS churn; names alone miss flux infra.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P1: RAMNIT — literature Park–Miller (baderj / bin.re)
  // -------------------------------------------------------------------------
  DGAResult _generateRamnit(DateTime date, int count, RamnitDGA algo) {
    final seed = algo.resolvedSeed;
    final tlds = [
      for (final t in algo.tld) t.replaceAll('.', '').toLowerCase(),
    ];
    if (tlds.isEmpty) {
      throw ArgumentError('RamnitDGA.tld must be non-empty');
    }
    final minL = algo.sldMinLength < 1 ? 1 : algo.sldMinLength;
    final maxL = algo.sldMaxLength < minL ? minL : algo.sldMaxLength;
    final randomInt = ParkMillerLcg(seed);
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var idx = 0; idx < limit; idx++) {
      final firstSeed = randomInt.value;
      final domainLen = randomInt.randIntModulus(1 + (maxL - minL)) + minL;
      final secondSeed = randomInt.value;
      final buf = StringBuffer();
      for (var i = 0; i < domainLen; i++) {
        // modulus 25 → a–y only (literature)
        buf.writeCharCode(0x61 + randomInt.randIntModulus(25));
      }
      final tld = tlds[idx % tlds.length];
      domains.add('${buf.toString()}.$tld');
      randomInt.value = ramnitReseed(firstSeed, secondSeed);
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Ramnit',
      seed: '0x${seed.toRadixString(16)}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': 'a-y',
          'length_min': minL,
          'length_max': maxL,
          'config_seed': seed,
          'seed_hex': seed.toRadixString(16),
          'prng': 'park_miller_lcg',
          'seed_packing': 'config_hex_dword',
          'tld_set': tlds,
          'domains_per_day': algo.domainsPerDay,
          'literature': 'baderj/ramnit',
          'fidelity': 'literature-perfect',
          'date_independent': true,
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Ramnit seed dword is the extract IOC; labels are a–y Park–Miller, not MD5.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P1: NYMAIM — literature date PRNG (baderj/nymaim)
  // -------------------------------------------------------------------------
  DGAResult _generateNymaim(DateTime date, int count, NymaimDGA algo) {
    final r = NymaimPrng(date);
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var i = 0; i < limit; i++) {
      final length = r.rand(6) + 6;
      final buf = StringBuffer();
      for (var l = 0; l < length; l++) {
        buf.writeCharCode(0x61 + (r.rand(26) % 26));
      }
      final label = buf.toString();
      final t = label.codeUnitAt(label.length - 2) - 0x61;
      final String tld;
      if (t < 9) {
        tld = '.com';
      } else if (t < 13) {
        tld = '.org';
      } else if (t < 17) {
        tld = '.biz';
      } else if (t < 21) {
        tld = '.net';
      } else {
        tld = '.info';
      }
      domains.add('$label$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Nymaim',
      seed: 'nymaim-date=${date.year}-${date.month}-${date.day}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': 6,
          'length_max': 11,
          'prng': 'nymaim_4word',
          'seed_packing': 'year+(month<<16)+(isoweekday%7)+(day<<16)+magics',
          'magic_dwords': ['REVA', 'IHOL', 'YUH ', 'MAV '],
          'tld_set': algo.tld,
          'domains_per_day': algo.domainsPerDay,
          'literature': 'baderj/nymaim',
          'fidelity': 'literature-perfect',
        },
        predictability: PredictabilityClass.trivial,
        socLesson:
            'Date-only Nymaim PRNG — full daily precompute once algorithm is known.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P1: SHIOTOB — literature seed-domain mutation (baderj/shiotob)
  // -------------------------------------------------------------------------
  DGAResult _generateShiotob(DateTime date, int count, ShiotobDGA algo) {
    var domain = algo.seedDomain.trim().toLowerCase();
    if (!domain.contains('.')) {
      throw ArgumentError(
        'ShiotobDGA.seedDomain must include a TLD (e.g. 4ypv1eehphg3a.com)',
      );
    }
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var i = 0; i < limit; i++) {
      domains.add(domain);
      domain = _shiotobNext(domain);
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Shiotob',
      seed: algo.seedDomain,
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': 'qwerty_subset',
          'seed_domain': algo.seedDomain,
          'prng': 'shiotob_mutation',
          'tld_set': ['.com', '.net'],
          'domains_per_day': algo.domainsPerDay,
          'date_independent': true,
          'literature': 'baderj/shiotob',
          'fidelity': 'literature-perfect',
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Seed domain is the extract IOC; chain is date-independent mutation.',
      ),
    );
  }

  String _shiotobNext(String domain) {
    const qwerty = 'qwertyuiopasdfghjklzxcvbnm123945678';
    final hostWithTld = domain;
    // sum of characters excluding last 3 chars (".xx" style in literature)
    var sof = 0;
    final cut = hostWithTld.length >= 3 ? hostWithTld.length - 3 : 0;
    for (var i = 0; i < cut; i++) {
      sof += hostWithTld.codeUnitAt(i);
    }
    final asciiCodes = List<int>.filled(166, 0);
    for (var i = 0; i < hostWithTld.length && i < 166; i++) {
      asciiCodes[i] = hostWithTld.codeUnitAt(i);
    }
    final oldHostnameLength = domain.length - 4;
    for (var i = 0; i < 66; i++) {
      for (var j = 0; j < 66; j++) {
        final edi = j + i;
        if (edi < 65) {
          final p = oldHostnameLength * asciiCodes[j];
          final cl = p ^ asciiCodes[edi] ^ sof;
          asciiCodes[edi] = cl & 0xFF;
        }
      }
    }
    final cx = ((asciiCodes[2] * oldHostnameLength) ^ asciiCodes[0]) & 0xFF;
    var hostnameLength = cx ~/ 16;
    if (hostnameLength < 10) {
      hostnameLength = oldHostnameLength;
    }
    if (hostnameLength < 1) hostnameLength = 1;
    if (hostnameLength > 63) hostnameLength = 63;
    final buf = StringBuffer();
    for (var i = 0; i < hostnameLength; i++) {
      final index = asciiCodes[i] ~/ 8;
      final safe = index < qwerty.length ? index : qwerty.length - 1;
      buf.write(qwerty[safe]);
    }
    final tld = domain.endsWith('.net') ? '.com' : '.net';
    return '${buf.toString()}$tld';
  }

  // -------------------------------------------------------------------------
  // P1: PYKSPA — literature precursor (baderj/pykspa/precursor)
  // -------------------------------------------------------------------------
  DGAResult _generatePykspa(DateTime date, int count, PykspaDGA algo) {
    // Python mktime local — lab pins UTC midnight epoch seconds for stability.
    final utc = DateTime.utc(date.year, date.month, date.day);
    final unix = utc.millisecondsSinceEpoch ~/ 1000;
    final seed = algo.seedOverride ?? (unix ~/ (2 * 24 * 3600));
    var r = seed & 0xFFFFFFFF;
    const tlds = ['biz', 'com', 'net', 'org', 'info', 'cc'];
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var domainNr = 0; domainNr < limit; domainNr++) {
      // r = int(r ** 2) & 0xFFFFFFFF  — use BigInt for overflow parity
      r = ((BigInt.from(r) * BigInt.from(r)) & BigInt.from(0xFFFFFFFF)).toInt();
      r = (r + domainNr) & 0xFFFFFFFF;
      final domainLength = (r % 10) + 6;
      final sld = _pykspaSld(domainLength, r);
      final tld = tlds[r % 6];
      domains.add('$sld.$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Pykspa',
      seed: 'bucket=$seed',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': 6,
          'length_max': 15,
          'prng': 'pykspa_precursor',
          'seed_packing': 'unix//(2*86400)',
          'seed_bucket': seed,
          'tld_set': tlds,
          'domains_per_day': algo.domainsPerDay,
          'literature': 'baderj/pykspa/precursor',
          'fidelity': 'literature-perfect',
          'needs_lexical_model': true,
        },
        predictability: PredictabilityClass.trivial,
        needsLexicalModel: true,
        socLesson:
            '2-day time buckets; precursor path is literature-aligned (improved needs MD6).',
      ),
    );
  }

  String _pykspaSld(int sldLen, int r0) {
    var r = r0 & 0xFFFFFFFF;
    var a = (sldLen * sldLen) & 0xFFFFFFFF;
    final buf = StringBuffer();
    for (var i = 0; i < sldLen; i++) {
      final x = (i * (r % 4567 + r % 19)) & 0xFFFFFFFF;
      final y = r % 123456;
      final z = r % 5;
      final p = (r * (z + y + x)) & 0xFFFFFFFF;
      final ind = (a + p) & 0xFFFFFFFF;
      buf.writeCharCode(0x61 + (ind % 26));
      r = (r + i) & 0xFFFFFFFF;
      final shift = ((i * i) & 0xFF) & 31;
      r = (r >> shift) & 0xFFFFFFFF;
      a = (a + sldLen) & 0xFFFFFFFF;
    }
    return buf.toString();
  }

  // -------------------------------------------------------------------------
  // P1: VAWTRAK — literature glibc LCG → .top (baderj/vawtrak)
  // -------------------------------------------------------------------------
  DGAResult _generateVawtrak(DateTime date, int count, VawtrakDGA algo) {
    final rng = VawtrakLcg(algo.seed);
    final tld = _normTld(algo.tld);
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var i = 0; i < limit; i++) {
      final length = rng.rand() % 5 + 7;
      final buf = StringBuffer();
      for (var j = 0; j < length; j++) {
        buf.writeCharCode(0x61 + (rng.rand() % 26));
      }
      domains.add('${buf.toString()}$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Vawtrak',
      seed: '0x${(algo.seed & 0xFFFFFFFF).toRadixString(16)}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': 7,
          'length_max': 11,
          'config_seed': algo.seed,
          'campaign_id': algo.campaignId,
          'tier': algo.tier,
          'prng': 'glibc_lcg',
          'tld_set': [tld],
          'domains_per_day': algo.domainsPerDay,
          'date_independent': true,
          'literature': 'baderj/vawtrak',
          'fidelity': 'literature-perfect',
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Vawtrak seed dword is the extract target; literature path is .top only.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P1: EMOTET — research volume/TLD era model (no baderj pin)
  // -------------------------------------------------------------------------
  DGAResult _generateEmotet(DateTime date, int count, EmotetDGA algo) {
    var state = _dateSeed32(date) ^ (algo.seed & 0xFFFFFFFF);
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var i = 0; i < limit; i++) {
      state = _lcg(state);
      final span = algo.maxDomainLength - algo.minDomainLength + 1;
      final length = algo.minDomainLength + ((state >> 16) % span);
      final buf = StringBuffer();
      var temp = state;
      for (var j = 0; j < length; j++) {
        temp = _lcg(temp);
        buf.write(_charsetAlpha[(temp >> 16) % _charsetAlpha.length]);
      }
      final tld = _normTld(algo.tld[i % algo.tld.length]);
      domains.add('${buf.toString()}$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Emotet',
      seed: '0x${(algo.seed & 0xFFFFFFFF).toRadixString(16)}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': algo.minDomainLength,
          'length_max': algo.maxDomainLength,
          'config_seed': algo.seed,
          'prng': 'lcg',
          'tld_set': algo.tld,
          'domains_per_day': algo.domainsPerDay,
          'literature': 'research-model/era-volume',
          'fidelity': 'research-model',
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Era volume + broad TLD model — not a single Emotet generation pin.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P2: KRAKEN — literature v2 (baderj/kraken/v2)
  // -------------------------------------------------------------------------
  DGAResult _generateKraken(DateTime date, int count, KrakenDGA algo) {
    final seedSet = algo.seedSet.toLowerCase();
    if (seedSet != 'a' && seedSet != 'b') {
      throw ArgumentError('KrakenDGA.seedSet must be "a" or "b"');
    }
    final tldSet = algo.tldSet == 2 ? 2 : 1;
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    // Literature get_domains: for i; for temp_file in range(2) where 0→nex, 1→ex
    // (Python truthiness: 0 is False → 'nex' branch; 1 is True → 'ex' branch).
    var produced = 0;
    var index = 0;
    while (produced < limit) {
      // Order matches range(2): false first (nex label), then true (ex label).
      for (final tempFile in [false, true]) {
        if (algo.exOnly && tempFile) continue;
        domains.add(
          _krakenV2Domain(index * 2, date, seedSet, tempFile, tldSet),
        );
        produced++;
        if (produced >= limit) break;
      }
      index++;
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Kraken',
      seed: 'v2/$seedSet/tld$tldSet',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': 7,
          'length_max': 12,
          'seed_set': seedSet,
          'tld_set_nr': tldSet,
          'prng': 'kraken_v2',
          'domains_per_day': algo.domainsPerDay,
          'ex_only': algo.exOnly,
          'literature': 'baderj/kraken/v2',
          'fidelity': 'literature-perfect',
        },
        predictability: PredictabilityClass.trivial,
        socLesson:
            'Kraken v2 date discards + seed set a/b — full precompute for the day.',
      ),
    );
  }

  String _krakenV2Domain(
    int index,
    DateTime date,
    String seedSet,
    bool tempFile,
    int tldSetNr,
  ) {
    const tldSets = {
      1: ['com', 'net', 'tv', 'cc'],
      2: ['dyndns.org', 'yi.org', 'dynserv.com', 'mooo.com'],
    };
    const seeds = {
      'a': {'ex': 24938314, 'nex': 24938315},
      'b': {'ex': 1600000, 'nex': 1600001},
    };
    final tlds = tldSets[tldSetNr]!;
    final seedMap = seeds[seedSet]!;
    final domainNr = index ~/ 2;
    var r = tempFile
        ? 3 * domainNr + seedMap['ex']!
        : 3 * domainNr + seedMap['nex']!;

    // discards = (mktime(date) - 1207000000) // 604800 + 2
    final utc = DateTime.utc(date.year, date.month, date.day);
    final ts = utc.millisecondsSinceEpoch ~/ 1000;
    var discards = (ts - 1207000000) ~/ 604800 + 2;
    if (domainNr % 9 < 8) {
      if (domainNr % 9 >= 6) {
        discards -= 1;
      }
      for (var i = 0; i < discards; i++) {
        r = krakenCrop(krakenRand(r));
      }
    }
    final rands = List<int>.filled(3, 0);
    for (var i = 0; i < 3; i++) {
      r = krakenRand(r);
      rands[i] = krakenCrop(r);
    }
    final domainLength = (rands[0] * rands[1] + rands[2]) % 6 + 7;
    final buf = StringBuffer();
    for (var i = 0; i < domainLength; i++) {
      r = krakenRand(r);
      final ch = krakenCrop(r) % 26 + 0x61;
      buf.writeCharCode(ch);
    }
    final tld = tlds[domainNr % 4];
    return '${buf.toString()}.$tld';
  }

  // -------------------------------------------------------------------------
  // P2: TORPIG — windowed seed rotation research model
  // -------------------------------------------------------------------------
  DGAResult _generateTorpig(DateTime date, int count, TorpigDGA algo) {
    final window = algo.windowDays < 1 ? 1 : algo.windowDays;
    final dayOfYear =
        int.parse(
          '${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}',
        ) +
        date.year * 366;
    final windowIndex = dayOfYear ~/ window;
    var state =
        (windowIndex * 0x9E3779B9 ^ (algo.seed & 0xFFFFFFFF)) & 0xFFFFFFFF;
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var i = 0; i < limit; i++) {
      state = _lcg(state);
      final span = algo.maxDomainLength - algo.minDomainLength + 1;
      final length = algo.minDomainLength + ((state >> 16) % span);
      final buf = StringBuffer();
      var temp = state;
      for (var j = 0; j < length; j++) {
        temp = _lcg(temp);
        buf.write(_charsetAlpha[(temp >> 16) % _charsetAlpha.length]);
      }
      final tld = _normTld(algo.tld[i % algo.tld.length]);
      domains.add('${buf.toString()}$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Torpig',
      seed: 'window=$windowIndex;days=$window',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': algo.minDomainLength,
          'length_max': algo.maxDomainLength,
          'window_days': window,
          'window_index': windowIndex,
          'config_seed': algo.seed,
          'prng': 'lcg',
          'tld_set': algo.tld,
          'domains_per_day': algo.domainsPerDay,
          'seed_rotation_lesson': true,
          'literature': 'research-model/time-window',
          'fidelity': 'research-model',
        },
        predictability: PredictabilityClass.trivial,
        socLesson:
            'Seed rotates on day windows — precompute whole window, not one day.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P2: COREBOT — literature NR LCG + .ddns.net (baderj/corebot)
  // -------------------------------------------------------------------------
  DGAResult _generateCoreBot(DateTime date, int count, CoreBotDGA algo) {
    // r = (r + year + ((nr_b << 16) + (month << 8) | day)) & 0xFFFFFFFF
    // r = (r + year + ((nr_b << 16) + ((month << 8) | day))) & 0xFFFFFFFF
    var r =
        (algo.seed +
            date.year +
            ((algo.nrB << 16) + ((date.month << 8) | date.day))) &
        0xFFFFFFFF;
    // literature: range(ord('a'), ord('z')) + range(ord('0'), ord('9'))
    // → a–y and 0–8
    const litCharset = 'abcdefghijklmnopqrstuvwxy012345678';
    final lcg = CorebotLcg(r);
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    final suffix = algo.suffix.startsWith('.')
        ? algo.suffix
        : '.${algo.suffix}';
    for (var i = 0; i < limit; i++) {
      const lenL = 0xC;
      const lenU = 0x18;
      lcg.next();
      final domainLen = lenL + (lcg.state % (lenU - lenL));
      final buf = StringBuffer();
      for (var k = domainLen; k > 0; k--) {
        lcg.next();
        buf.write(litCharset[lcg.state % litCharset.length]);
      }
      domains.add('${buf.toString()}$suffix');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'CoreBot',
      seed: 'nr_b=${algo.nrB};r0=${algo.seed}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': litCharset,
          'length_min': 12,
          'length_max': 23,
          'config_seed': algo.seed,
          'nr_b': algo.nrB,
          'prng': 'numerical_recipes_lcg',
          'suffix': suffix,
          'domains_per_day': algo.domainsPerDay,
          'literature': 'baderj/corebot',
          'fidelity': 'literature-perfect',
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Corebot .ddns.net + NR LCG; nr_b and date packing are config IOCs.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P2: DIRCRYPT — literature Park–Miller → .com (baderj/dircrypt)
  // -------------------------------------------------------------------------
  DGAResult _generateDirCrypt(DateTime date, int count, DirCryptDGA algo) {
    final rng = ParkMillerLcg(algo.seed);
    final tld = _normTld(algo.tld);
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    for (var i = 0; i < limit; i++) {
      final domainLen = rng.randIntModulus(12 + 1) + 8;
      final buf = StringBuffer();
      for (var j = 0; j < domainLen; j++) {
        buf.writeCharCode(0x61 + rng.randIntModulus(25 + 1));
      }
      domains.add('${buf.toString()}$tld');
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'DirCrypt',
      seed: '0x${(algo.seed & 0xFFFFFFFF).toRadixString(16)}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': 8,
          'length_max': 20,
          'config_seed': algo.seed,
          'prng': 'park_miller_lcg',
          'tld_set': [tld],
          'domains_per_day': algo.domainsPerDay,
          'date_independent': true,
          'literature': 'baderj/dircrypt',
          'fidelity': 'literature-perfect',
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'DirCrypt seed hex is the extract IOC; all labels land on .com.',
      ),
    );
  }

  // -------------------------------------------------------------------------
  // P2: PROSLIKEFAN — literature string-hash (baderj/proslikefan)
  // -------------------------------------------------------------------------
  DGAResult _generateProslikefan(
    DateTime date,
    int count,
    ProslikefanDGA algo,
  ) {
    final tlds = [
      for (final t in algo.tld) t.replaceAll('.', '').toLowerCase(),
    ];
    if (tlds.isEmpty) {
      throw ArgumentError('ProslikefanDGA.tld must be non-empty');
    }
    final domains = <String>[];
    final limit = count > algo.domainsPerDay ? algo.domainsPerDay : count;
    var produced = 0;
    final waves = algo.waves < 1 ? 1 : algo.waves;
    outer:
    for (var i = 0; i < waves; i++) {
      for (final tld in tlds) {
        if (produced >= limit) break outer;
        final seedString =
            '${algo.magic}.${date.month}.${date.day}.${date.year}.$tld';
        var r = proslikefanAbsHash(seedString) + i;
        final buf = StringBuffer();
        var k = 0;
        // Literature re-evaluates `r % 7 + 6` each iteration as r mutates.
        while (k < r % 7 + 6) {
          r = proslikefanAbsHash('${buf.toString()}$r');
          buf.writeCharCode(0x61 + (r % 26));
          k++;
        }
        domains.add('${buf.toString()}.$tld');
        produced++;
      }
    }
    return DGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Proslikefan',
      seed: 'magic=${algo.magic}',
      metadata: ClassicalSocMetadata.enrich(
        {
          'charset': _charsetAlpha,
          'length_min': 6,
          'length_max': 12,
          'magic': algo.magic,
          'prng': 'java_string_hash',
          'tld_set': tlds,
          'domains_per_day': algo.domainsPerDay,
          'literature': 'baderj/proslikefan',
          'fidelity': 'literature-perfect',
        },
        predictability: PredictabilityClass.configSeeded,
        needsConfigExtract: true,
        socLesson:
            'Magic string (prospect/OK) is the config IOC; then date×TLD expand.',
      ),
    );
  }

  // --- Helpers: 32-bit ops, CRC32, MT19937 ---

  int _mul32(int a, int b) => (a * b) & 0xFFFFFFFF;

  int _lcg(int state, {int mul = 1103515245, int add = 12345}) =>
      ((state * mul + add) & 0xFFFFFFFF);

  int _dateSeed32(DateTime date) =>
      ((date.year << 16) | (date.month << 8) | date.day) & 0xFFFFFFFF;

  String _normTld(String tld) {
    if (tld.isEmpty) return '.com';
    return tld.startsWith('.') ? tld : '.$tld';
  }

  /// Minimal Bootstring/punycode encoder for a single Unicode label (R8 lab).
  String _toPunycodeLabel(String input) {
    // Fast path: pure ASCII.
    if (input.codeUnits.every((c) => c < 0x80)) {
      return input.toLowerCase();
    }
    const base = 36;
    const tmin = 1;
    const tmax = 26;
    const skew = 38;
    const damp = 700;
    const initialBias = 72;
    const initialN = 128;
    var n = initialN;
    var delta = 0;
    var bias = initialBias;
    final output = StringBuffer();
    var b = 0;
    for (final c in input.codeUnits) {
      if (c < 0x80) {
        output.writeCharCode(c >= 65 && c <= 90 ? c + 32 : c);
        b++;
      }
    }
    final h0 = b;
    if (b > 0) output.write('-');
    var h = b;
    final inputCps = input.runes.toList();
    final len = inputCps.length;
    while (h < len) {
      var m = 0x7fffffff;
      for (final c in inputCps) {
        if (c >= n && c < m) m = c;
      }
      delta += (m - n) * (h + 1);
      n = m;
      for (final c in inputCps) {
        if (c < n) {
          delta++;
        } else if (c == n) {
          var q = delta;
          for (var k = base; ; k += base) {
            final t = k <= bias ? tmin : (k >= bias + tmax ? tmax : k - bias);
            if (q < t) break;
            final code = t + ((q - t) % (base - t));
            output.writeCharCode(code < 26 ? 97 + code : 22 + code);
            q = (q - t) ~/ (base - t);
          }
          output.writeCharCode(q < 26 ? 97 + q : 22 + q);
          // adapt
          delta = h == h0 ? delta ~/ damp : delta >> 1;
          delta += delta ~/ (h + 1);
          var k = 0;
          while (delta > ((base - tmin) * tmax) ~/ 2) {
            delta ~/= base - tmin;
            k += base;
          }
          bias = k + (((base - tmin + 1) * delta) ~/ (delta + skew));
          delta = 0;
          h++;
        }
      }
      delta++;
      n++;
    }
    return 'xn--${output.toString()}';
  }

  int _ror32(int v, int s) {
    v &= 0xFFFFFFFF;
    final shift = s % 32;
    if (shift == 0) return v;
    return ((v >> shift) | (v << (32 - shift))) & 0xFFFFFFFF;
  }

  int _rol32(int v, int s) {
    v &= 0xFFFFFFFF;
    final shift = s % 32;
    if (shift == 0) return v;
    return ((v << shift) | (v >> (32 - shift))) & 0xFFFFFFFF;
  }

  int _calculateCRC32(String input) {
    final bytes = utf8.encode(input);
    int crc = 0xFFFFFFFF;
    for (var byte in bytes) {
      crc = crc ^ (byte & 0xFF);
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >>> 1) ^ 0xEDB88320;
        } else {
          crc = crc >>> 1;
        }
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}

/// MT19937 matching the QakBot literature reimplementation (32-bit).
class _MT19937 {
  int _index = 624;
  final List<int> _mt = List<int>.filled(624, 0);

  _MT19937(int seed) {
    _mt[0] = seed & 0xFFFFFFFF;
    for (int i = 1; i < 624; i++) {
      final prev = _mt[i - 1];
      _mt[i] = (1812433253 * (prev ^ (prev >> 30)) + i) & 0xFFFFFFFF;
    }
  }

  int extractNumber() {
    if (_index >= 624) {
      _twist();
    }
    var y = _mt[_index];
    y ^= y >> 11;
    y ^= (y << 7) & 2636928640;
    y ^= (y << 15) & 4022730752;
    y ^= y >> 18;
    _index += 1;
    return y & 0xFFFFFFFF;
  }

  void _twist() {
    for (int i = 0; i < 624; i++) {
      final y =
          ((_mt[i] & 0x80000000) + (_mt[(i + 1) % 624] & 0x7fffffff)) &
          0xFFFFFFFF;
      _mt[i] = (_mt[(i + 397) % 624] ^ (y >> 1)) & 0xFFFFFFFF;
      if (y.isOdd) {
        _mt[i] = (_mt[i] ^ 0x9908b0df) & 0xFFFFFFFF;
      }
    }
    _index = 0;
  }

  /// Literature helper: map 28 bits into inclusive [lower, upper].
  int randInt(int lower, int upper) {
    final r = extractNumber() & 0xFFFFFFF;
    final t = lower + (r / (1 << 28)) * (upper - lower + 1);
    return t.floor();
  }
}
