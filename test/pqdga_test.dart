import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pqdga/pqdga.dart';
import 'package:pqforge/pqforge.dart';
import 'package:test/test.dart';

void main() {
  group('Classical P0 golden vectors', () {
    test('Locky v2 config#1 matches open-literature domains for 2016-02-24', () async {
      final date = DateTime.utc(2016, 2, 24);
      final result = await DGAGenerator(
        DGAConfig(algorithm: const LockyDGA()),
      ).generateDomains(date, 8);

      expect(result.algorithm, 'Locky-v2');
      expect(result.metadata['predictability'], 'trivial');
      expect(result.metadata['charset'], 'a-y');
      expect(result.domains, [
        'nqksuqcwbfyffh.nl',
        'iahyhfbgbkh.uk',
        'rxcrspvpd.pw',
        'fkurom.nl',
        'oiplyfrbciayvuu.pm',
        'qjqgkwgqlotxc.yt',
        'lsuohnyjvk.eu',
        'uqphbvjx.uk',
      ]);
    });

    test('QakBot MT19937 path matches reference for 2016-07-11 seed 0', () async {
      final date = DateTime.utc(2016, 7, 11);
      final result = await DGAGenerator(
        DGAConfig(algorithm: const QakBotDGA(configSeed: 0)),
      ).generateDomains(date, 10);

      expect(result.algorithm, 'QakBot');
      expect(result.seed, '1.jul.2016.00000000');
      expect(result.metadata['predictability'], 'config-seeded');
      expect(result.metadata['prng'], 'MT19937');
      expect(result.domains, [
        'slcjuisocqjwtvgtqmjqszj.com',
        'rxpsgnfivvdeqe.com',
        'ethhshzarzutqiid.biz',
        'wytgqpqutnj.biz',
        'rnpybuoayzg.org',
        'vwdkbnrsejxgjzyra.info',
        'gzcapifegehhyb.org',
        'tpamjqbe.info',
        'wrkzdoixvlu.net',
        'yxgjkxtwwxrjupmkcxq.net',
      ]);
    });

    test('Banjori mutates first four letters from seed domain', () async {
      final date = DateTime.utc(2024, 1, 1);
      final result = await DGAGenerator(
        DGAConfig(
          algorithm: const BanjoriDGA(
            seedDomain: 'earnestnessbiophysicalohax.com',
          ),
        ),
      ).generateDomains(date, 10);

      expect(result.algorithm, 'Banjori');
      expect(result.metadata['date_affects_generation'], false);
      expect(result.metadata['predictability'], 'config-seeded');
      expect(result.domains, [
        'earnestnessbiophysicalohax.com',
        'kwtoestnessbiophysicalohax.com',
        'rvcxestnessbiophysicalohax.com',
        'hjbtestnessbiophysicalohax.com',
        'txmoestnessbiophysicalohax.com',
        'agekestnessbiophysicalohax.com',
        'dbzwestnessbiophysicalohax.com',
        'sgjxestnessbiophysicalohax.com',
        'igjyestnessbiophysicalohax.com',
        'zxahestnessbiophysicalohax.com',
      ]);
      // Tail after first four chars stays fixed.
      for (final d in result.domains) {
        expect(d.substring(4), 'estnessbiophysicalohax.com');
      }
    });

    test('Ranbyus May matches C reference for 2015-05-14 seed 0xB6354BC3', () async {
      final date = DateTime.utc(2015, 5, 14);
      final result = await DGAGenerator(
        DGAConfig(algorithm: const RanbyusDGA(seed: 0xB6354BC3)),
      ).generateDomains(date, 8);

      expect(result.algorithm, 'Ranbyus-may');
      expect(result.metadata['predictability'], 'config-seeded');
      expect(result.metadata['length_min'], 14);
      expect(result.domains, [
        'ikwoqkwuajpbyx.com',
        'niukpdrluwlfox.pw',
        'rcnxisuibbadng.in',
        'wbqtidjvsdiwee.me',
        'jrdyumcieyipnv.cc',
        'yvyfwikedfxitk.su',
        'tviurcntxylxnj.tw',
        'lycyrvfcemepfm.net',
      ]);
    });

    test('Suppobox two-word shuffle matches fixture wordlist + fixed unix', () async {
      final wordsFile = File('test/fixtures/suppobox_words1.txt');
      expect(wordsFile.existsSync(), isTrue, reason: 'fixture wordlist missing');
      final words = wordsFile
          .readAsLinesSync()
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      expect(words.length, greaterThanOrEqualTo(256));

      // 2016-01-01 00:00:00 UTC
      const unix = 1451606400;
      final result = await DGAGenerator(
        DGAConfig(
          algorithm: SuppoboxDGA(wordList: words, unixSeconds: unix),
        ),
      ).generateDomains(DateTime.utc(2016, 1, 1), 5);

      expect(result.algorithm, 'Suppobox');
      expect(result.metadata['needs_lexical_model'], true);
      expect(result.metadata['predictability'], 'config-seeded');
      expect(result.domains, [
        'figurewagon.net',
        'thoughwagon.net',
        'figurewithout.net',
        'thoughwithout.net',
        'figurekitchen.net',
      ]);
    });
  });

  group('Classical baseline still dispatches', () {
    test('Conficker produces domains with metadata-ready result', () async {
      final result = await DGAGenerator(
        DGAConfig(algorithm: const ConfickerDGA()),
      ).generateDomains(DateTime.utc(2024, 1, 1), 3);
      expect(result.domains, hasLength(3));
      expect(result.algorithm, contains('Conficker'));
    });

    test('registry maps every implemented classical type', () {
      expect(DGAGenerator.registry.containsKey(LockyDGA), isTrue);
      expect(DGAGenerator.registry.containsKey(ConfickerDGA), isTrue);
      expect(DGAGenerator.registry.containsKey(MarkovDGA), isTrue);
      expect(DGAGenerator.registry.containsKey(RamnitDGA), isTrue);
      expect(DGAGenerator.registry.containsKey(KrakenDGA), isTrue);
      expect(DGAGenerator.registry.length, greaterThanOrEqualTo(36));
    });
  });

  group('R2/R3 PQ core', () {
    test('PQDGAResult carries predictable/secretBound flags', () {
      final r = PQDGAResult(
        domains: const ['example.com'],
        generationDate: DateTime.utc(2024, 1, 1),
        algorithm: 'test',
        seed: 'public',
        predictable: true,
        secretBound: false,
        epoch: '2024-01-01',
      );
      expect(r.predictable, isTrue);
      expect(r.secretBound, isFalse);
      expect(r.toSocSummary()['xof'], 'SHAKE256');
    });

    test('QuantumResistant public-seed golden vectors (SHAKE256)', () async {
      final date = DateTime.utc(2024, 6, 15, 12);
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: const QuantumResistantPqdga(
            campaignId: 'toy-campaign',
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);

      expect(result.algorithm, 'QuantumResistant');
      expect(result.xof, 'SHAKE256');
      expect(result.epoch, '2024-06-15');
      expect(result.predictable, isTrue);
      expect(result.secretBound, isFalse);
      expect(result.metadata['predictability'], 'trivial');
      expect(result.metadata['seed_public'], isTrue);
      expect(
        result.metadata['soc_lesson'],
        contains('PQ hash ≠ secret'),
      );
      expect(result.metadata['playbook_flags']['sinkhole_precompute'], isTrue);
      expect(result.domains, [
        'o9pszeoaq00.net',
        '5jkb7awf2oa.net',
        '2d6afcb1bc.org',
        '4riv445bs.com',
        'wcgjc1v3wuve.com',
      ]);
      for (final d in result.domains) {
        expect(DnsLabelCodec.validateFqdn(d).isSuccess, isTrue);
      }
    });

    test('QuantumResistant secret-bound mode flips flags', () async {
      final secret = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: QuantumResistantPqdga(
            seedPublic: false,
            secretMaterial: secret,
            campaignId: 'toy-secret',
          ),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 15), 3);

      expect(result.predictable, isFalse);
      expect(result.secretBound, isTrue);
      expect(result.metadata['predictability'], 'secret-seeded');
      expect(result.metadata['playbook_flags']['sinkhole_precompute'], isFalse);
      expect(result.domains, hasLength(3));
      // Seed explainability must not embed raw secret bytes.
      expect(result.seed.contains('010203'), isFalse);
    });

    test('PQ registry lists all implemented PQ families', () {
      expect(PQDGAGenerator.registry.containsKey(QuantumResistantPqdga), isTrue);
      expect(PQDGAGenerator.registry.containsKey(SharedSecretPqdga), isTrue);
      expect(
        PQDGAGenerator.registry.containsKey(SignatureAuthenticatedPqdga),
        isTrue,
      );
      expect(PQDGAGenerator.registry.containsKey(IdentityBasedPqdga), isTrue);
      expect(
        PQDGAGenerator.registry.containsKey(HybridSharedSecretPqdga),
        isTrue,
      );
      expect(PQDGAGenerator.registry.containsKey(DecentralizedPqdga), isTrue);
      expect(
        PQDGAGenerator.registry.containsKey(EnvelopeRendezvousPqdga),
        isTrue,
      );
      expect(PQDGAGenerator.registry.containsKey(RateLimitedPqdga), isTrue);
      expect(PQDGAGenerator.registry.containsKey(MultiRecipientPqdga), isTrue);
      expect(PQDGAGenerator.registry.length, greaterThanOrEqualTo(9));
    });
  });

  group('R4 SharedSecret ML-KEM', () {
    final fixedSs = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    test('fixed shared secret golden vectors (SHAKE256)', () async {
      final date = DateTime.utc(2024, 6, 15, 12);
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(
            sharedSecret: fixedSs,
            campaignId: 'toy-campaign',
            // Length-only IOC stand-in (not a real CT).
            kemCiphertext: Uint8List(1088),
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);

      expect(result.algorithm, 'SharedSecret');
      expect(result.xof, 'SHAKE256');
      expect(result.epoch, '2024-06-15');
      expect(result.predictable, isFalse);
      expect(result.secretBound, isTrue);
      expect(result.kemAlgorithm, 'ML-KEM-768');
      expect(result.kemCiphertextLength, 1088);
      expect(result.metadata['predictability'], 'secret-seeded');
      expect(result.metadata['seed_public'], isFalse);
      expect(result.metadata['ss_resolve_path'], 'direct');
      expect(
        result.metadata['soc_lesson'],
        contains('shared secret'),
      );
      expect(result.metadata['playbook_flags']['sinkhole_precompute'], isFalse);
      expect(
        result.metadata['playbook_flags']['needs_behavioral_detection'],
        isTrue,
      );
      expect(result.domains, [
        'k2bnb18b8o02.net',
        'jqr6yly00.com',
        'ugzxhcoed2fc.org',
        'ektsguxh9hgb.net',
        'asej3w9w1anf.net',
      ]);
      // Never leak raw ss bytes into seed/metadata strings.
      expect(result.seed.contains('010203'), isFalse);
      expect(result.toString().contains('010203'), isFalse);
      final summary = result.toSocSummary();
      expect(summary['secret_bound'], isTrue);
      expect(summary['kem_algorithm'], 'ML-KEM-768');
      expect(summary['kem_ciphertext_length'], 1088);
      for (final d in result.domains) {
        expect(DnsLabelCodec.validateFqdn(d).isSuccess, isTrue);
      }
    });

    test('missing secret material throws ArgumentError', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const SharedSecretPqdga()),
        ).generateDomains(DateTime.utc(2024, 1, 1), 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('labEstablish encaps/decaps round-trip matches domains', () async {
      final kemSeed = Uint8List.fromList(List<int>.generate(64, (i) => i));
      final encapsNonce =
          Uint8List.fromList(List<int>.generate(32, (i) => 200 - i));
      final session = SharedSecretPqdga.labEstablish(
        algorithm: PqKemAlgorithm.mlKem768,
        kemSeed: kemSeed,
        encapsNonce: encapsNonce,
        campaignId: 'toy-roundtrip',
      );

      expect(session.sharedSecret, hasLength(32));
      expect(
        session.kemCiphertext,
        hasLength(PqKemAlgorithm.mlKem768.ciphertextBytes),
      );

      final date = DateTime.utc(2024, 7, 1);
      final cfg = PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 10,
      );
      final direct = await PQDGAGenerator(cfg).generateDomains(date, 4);

      final viaDecaps = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.asDecapsConfig,
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 4);

      expect(viaDecaps.domains, direct.domains);
      expect(viaDecaps.metadata['ss_resolve_path'], 'decapsulate');
      expect(direct.metadata['ss_resolve_path'], 'direct');
      expect(viaDecaps.kemCiphertextLength, session.kemCiphertext.length);
      expect(viaDecaps.secretBound, isTrue);
      expect(viaDecaps.predictable, isFalse);
    });

    test('different shared secrets produce different domains', () async {
      final date = DateTime.utc(2024, 6, 15);
      final a = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(sharedSecret: fixedSs),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 3);
      final otherSs =
          Uint8List.fromList(List<int>.generate(32, (i) => 255 - i));
      final b = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(sharedSecret: otherSs),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 3);
      expect(a.domains, isNot(equals(b.domains)));
    });

    test('epoch rotation changes domain set', () async {
      final r1 = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(sharedSecret: fixedSs),
          minDomainLength: 8,
          maxDomainLength: 10,
          seedRotationDays: 1,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 15), 3);
      final r2 = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(sharedSecret: fixedSs),
          minDomainLength: 8,
          maxDomainLength: 10,
          seedRotationDays: 1,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 16), 3);
      expect(r1.epoch, '2024-06-15');
      expect(r2.epoch, '2024-06-16');
      expect(r1.domains, isNot(equals(r2.domains)));
    });
  });

  group('R5 SignatureAuthenticated ML-DSA', () {
    final sigSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    test('public-seed golden domains + verifiable detached sigs', () async {
      final session = SignatureAuthenticatedPqdga.labEstablish(
        algorithm: PqSignatureAlgorithm.mlDsa65,
        sigSeed: sigSeed,
        campaignId: 'toy-campaign',
      );
      final date = DateTime.utc(2024, 6, 15, 12);
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);

      expect(result.algorithm, 'SignatureAuthenticated');
      expect(result.xof, 'SHAKE256');
      expect(result.epoch, '2024-06-15');
      // Public seed ⇒ names precomputable; authenticity is the ML-DSA gate.
      expect(result.predictable, isTrue);
      expect(result.secretBound, isFalse);
      expect(result.sigAlgorithm, 'ML-DSA-65');
      expect(result.signatureLength, PqSignatureAlgorithm.mlDsa65.signatureBytes);
      expect(result.signatures, isNotNull);
      expect(result.signatures, hasLength(5));
      expect(result.pubkeyFingerprint, 'c6ebc350335e2ef5ee74f8069451943d');
      expect(result.metadata['predictability'], 'trivial');
      expect(result.metadata['requires_signature'], isTrue);
      expect(
        result.metadata['playbook_flags']['requires_signature'],
        isTrue,
      );
      expect(
        result.metadata['playbook_flags']['sinkhole_precompute'],
        isTrue,
      );
      expect(
        result.metadata['soc_lesson'],
        contains('ML-DSA'),
      );
      expect(result.domains, [
        'xnj7zp2ci.com',
        'nwckhhwa.net',
        '1nlcrbap.org',
        'fs8mrnp6.org',
        'lexqfoft.com',
      ]);

      // Detached sigs verify; lengths are stable IOC sizes (bytes may vary).
      for (var i = 0; i < result.domains.length; i++) {
        final sig = result.signatures![i];
        expect(sig, hasLength(PqSignatureAlgorithm.mlDsa65.signatureBytes));
        expect(
          session.algorithm.verify(
            domain: result.domains[i],
            epoch: result.epoch!,
            signature: sig,
          ),
          isTrue,
        );
        expect(
          SignatureAuthenticatedPqdga.verifyDomain(
            publicKey: session.signaturePublicKey,
            domain: result.domains[i],
            epoch: result.epoch!,
            campaignId: 'toy-campaign',
            signature: sig,
            algorithm: PqSignatureAlgorithm.mlDsa65,
          ),
          isTrue,
        );
      }

      // Never leak raw sk bytes into seed/summary strings.
      expect(result.seed.contains('010203'), isFalse);
      final summary = result.toSocSummary();
      expect(summary['sig_algorithm'], 'ML-DSA-65');
      expect(summary['signature_length'], 3309);
      expect(summary['pubkey_fingerprint'], result.pubkeyFingerprint);
      for (final d in result.domains) {
        expect(DnsLabelCodec.validateFqdn(d).isSuccess, isTrue);
      }
    });

    test('missing signing key throws ArgumentError', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const SignatureAuthenticatedPqdga()),
        ).generateDomains(DateTime.utc(2024, 1, 1), 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('tampered domain fails verify (anti-sinkhole drill)', () async {
      final session = SignatureAuthenticatedPqdga.labEstablish(
        algorithm: PqSignatureAlgorithm.mlDsa65,
        sigSeed: sigSeed,
        campaignId: 'toy-campaign',
      );
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 15), 1);

      final ok = session.algorithm.verify(
        domain: result.domains.first,
        epoch: result.epoch!,
        signature: result.signatures!.first,
      );
      expect(ok, isTrue);

      final forged = session.algorithm.verify(
        domain: 'sinkhole-attacker.example',
        epoch: result.epoch!,
        signature: result.signatures!.first,
      );
      expect(forged, isFalse);
    });

    test('secret-bound mode flips name predictability flags', () async {
      final secret = Uint8List.fromList(List<int>.generate(32, (i) => i + 7));
      final session = SignatureAuthenticatedPqdga.labEstablish(
        algorithm: PqSignatureAlgorithm.mlDsa65,
        sigSeed: sigSeed,
        campaignId: 'toy-secret-sig',
        seedPublic: false,
        secretMaterial: secret,
      );
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 15), 2);

      expect(result.predictable, isFalse);
      expect(result.secretBound, isTrue);
      expect(result.metadata['predictability'], 'secret-seeded');
      expect(result.metadata['playbook_flags']['sinkhole_precompute'], isFalse);
      expect(result.metadata['playbook_flags']['requires_signature'], isTrue);
      expect(result.signatures, hasLength(2));
      expect(
        session.algorithm.verify(
          domain: result.domains.first,
          epoch: result.epoch!,
          signature: result.signatures!.first,
        ),
        isTrue,
      );
    });

    test('requireSignature false emits names without signatures', () async {
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: const SignatureAuthenticatedPqdga(
            requireSignature: false,
            campaignId: 'toy-nosig',
          ),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 15), 2);

      expect(result.domains, hasLength(2));
      expect(result.signatures, isNull);
      expect(result.signatureLength, isNull);
      expect(result.metadata['requires_signature'], isFalse);
    });
  });

  group('R7 SOC features', () {
    test('per-domain features cover length entropy ratios tld', () {
      final f = SocFeatures.forDomain('abc123def.com');
      expect(f.labelLength, 9);
      expect(f.fqdnLength, 'abc123def.com'.length);
      expect(f.tld, 'com');
      expect(f.subdomainDepth, 2);
      expect(f.digitRatio, closeTo(3 / 9, 1e-9));
      expect(f.entropy, greaterThan(0));
      expect(f.charsetClass, anyOf('alnum', 'hex'));
      expect(f.idn, isFalse);
      expect(f.toJson()['tld'], 'com');
    });

    test('idn / punycode flag', () {
      final f = SocFeatures.forDomain('xn--fsq.com');
      expect(f.idn, isTrue);
    });

    test('batch features from PQ result include predictability', () async {
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: const QuantumResistantPqdga(campaignId: 'toy'),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 15), 5);
      final batch = SocFeatures.fromPqdgaResult(result);
      expect(batch.domainCount, 5);
      expect(batch.tldDiversity, greaterThan(0));
      expect(batch.predictable, isTrue);
      expect(batch.secretBound, isFalse);
      expect(batch.lengthHistogram, isNotEmpty);
      expect(batch.toJson()['domain_count'], 5);
    });

    test('ioc template helper reads metadata', () async {
      final ss = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(
            sharedSecret: ss,
            kemCiphertext: Uint8List(1088),
          ),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(DateTime.utc(2024, 6, 15), 1);
      final ioc = SocFeatures.iocTemplateFromPqdga(result);
      expect(ioc['kem_algorithm'], 'ML-KEM-768');
      expect(ioc['kem_ciphertext_length'], 1088);
    });

    test('classical batch pulls predictability metadata', () async {
      final result = await DGAGenerator(
        DGAConfig(algorithm: const LockyDGA()),
      ).generateDomains(DateTime.utc(2016, 2, 24), 4);
      final batch = SocFeatures.fromDgaResult(result);
      expect(batch.domainCount, 4);
      expect(batch.predictability, 'trivial');
    });
  });

  group('R6 Identity / Hybrid / Decentralized', () {
    final sigSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    final date = DateTime.utc(2024, 6, 15, 12);

    test('IdentityBased golden domains from vk namespace', () async {
      final session = IdentityBasedPqdga.labEstablish(
        sigSeed: sigSeed,
        campaignId: 'toy-campaign',
      );
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);

      expect(result.algorithm, 'IdentityBased');
      expect(result.predictable, isTrue);
      expect(result.secretBound, isFalse);
      expect(result.metadata['predictability'], 'config-seeded');
      expect(result.metadata['playbook_flags']['needs_config_extract'], isTrue);
      expect(result.pubkeyFingerprint, 'c6ebc350335e2ef5ee74f8069451943d');
      expect(result.domains, [
        'aq3v0qhaz0.com',
        'dtivp8e7.net',
        'ib90vx1mjk21.net',
        '35up450j.com',
        '274318lx13i.net',
      ]);
      expect(result.signatures, isNull);
    });

    test('IdentityBased optional sign path verifies', () async {
      final session = IdentityBasedPqdga.labEstablish(
        sigSeed: sigSeed,
        campaignId: 'toy-id-sig',
        requireSignature: true,
      );
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 2);

      expect(result.signatures, hasLength(2));
      expect(result.sigAlgorithm, 'ML-DSA-65');
      expect(result.metadata['requires_signature'], isTrue);
      expect(
        SignatureAuthenticatedPqdga.verifyDomain(
          publicKey: session.identityPublicKey,
          domain: result.domains.first,
          epoch: result.epoch!,
          campaignId: 'toy-id-sig',
          signature: result.signatures!.first,
        ),
        isTrue,
      );
    });

    test('IdentityBased missing vk throws ArgumentError', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const IdentityBasedPqdga()),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('HybridSharedSecret golden + combiner round-trip', () async {
      final classical =
          Uint8List.fromList(List<int>.generate(32, (i) => 0x10 + i));
      final pqSs = Uint8List.fromList(List<int>.generate(32, (i) => 0x80 + i));
      final session = HybridSharedSecretPqdga.labEstablish(
        classicalSharedSecret: classical,
        postQuantumSharedSecret: pqSs,
        campaignId: 'toy-campaign',
      );
      final direct = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);
      final viaCombiner = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.asCombinerConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);

      expect(direct.algorithm, 'HybridSharedSecret');
      expect(direct.predictable, isFalse);
      expect(direct.secretBound, isTrue);
      expect(direct.kemAlgorithm, 'ML-KEM-768');
      expect(direct.metadata['playbook_flags']['hybrid_kem'], isTrue);
      expect(direct.domains, viaCombiner.domains);
      expect(direct.domains, [
        's6hmar1rl9d.org',
        'xdb9h9o2.com',
        'wq6m0f0fj.com',
        'v46nnjsugn3.net',
        'jz2man6r2z.org',
      ]);
      expect(direct.seed.contains('a0'), isFalse);
    });

    test('HybridSharedSecret missing material throws ArgumentError', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const HybridSharedSecretPqdga()),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Decentralized base32 DNS golden + abstract mode', () async {
      final session = DecentralizedPqdga.labEstablish(
        sigSeed: sigSeed,
        campaignId: 'toy-campaign',
        encoding: 'base32',
        idByteLength: 16,
      );
      final dns = await PQDGAGenerator(
        PQDGAConfig(algorithm: session.algorithm, seedRotationDays: 1),
      ).generateDomains(date, 5);

      expect(dns.algorithm, 'Decentralized');
      expect(dns.predictable, isTrue);
      expect(dns.secretBound, isFalse);
      expect(dns.metadata['encoding'], 'base32');
      expect(dns.metadata['dns_mode'], isTrue);
      expect(
        dns.metadata['playbook_flags']['needs_channel_agility_monitoring'],
        isTrue,
      );
      expect(dns.pubkeyFingerprint, 'c6ebc350335e2ef5ee74f8069451943d');
      expect(dns.domains, [
        'doses4sgczomparygt5reauz4q.com',
        '5ruhuhemofpzbex4avrnze7tbe.org',
        's4kjrwxi3y7ybkroccychctqj4.com',
        'wvdzyidiece4mrogf2tzvhhb2i.com',
        'efpkizpyg5myptgd7jjo7kvjxu.com',
      ]);
      for (final d in dns.domains) {
        expect(DnsLabelCodec.validateFqdn(d).isSuccess, isTrue);
      }

      final abs = await PQDGAGenerator(
        PQDGAConfig(algorithm: session.asAbstractConfig, seedRotationDays: 1),
      ).generateDomains(date, 2);
      expect(abs.metadata['dns_mode'], isFalse);
      expect(abs.domains.first, startsWith('pqdga:base32:'));
      expect(abs.domains, [
        'pqdga:base32:doses4sgczomparygt5reauz4q',
        'pqdga:base32:5ruhuhemofpzbex4avrnze7tbe',
      ]);
    });

    test('Decentralized missing namespace throws ArgumentError', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const DecentralizedPqdga()),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('R8 research generics goldens', () {
    final date = DateTime.utc(2024, 6, 15, 12);

    test('Markov n-gram LM golden + lexical flag', () async {
      final result = await DGAGenerator(
        DGAConfig(algorithm: const MarkovDGA()),
      ).generateDomains(date, 5);
      expect(result.algorithm, 'Markov');
      expect(result.metadata['predictability'], 'config-seeded');
      expect(result.metadata['needs_lexical_model'], isTrue);
      expect(result.domains, [
        'uaaikegigac.com',
        'jonuuijacig.net',
        'uuvijuvefonazus.org',
        'fusayihegiioqeg.info',
        'fusopigeeijedop.com',
      ]);
    });

    test('Idn punycode goldens start with xn--', () async {
      final result = await DGAGenerator(
        DGAConfig(algorithm: const IdnDGA(baseWord: 'paypal')),
      ).generateDomains(date, 5);
      expect(result.algorithm, 'Idn');
      expect(result.metadata['idn_abuse'], isTrue);
      expect(result.metadata['predictability'], 'config-seeded');
      expect(result.domains, [
        'xn--ayal-f6dc.com',
        'xn--ppal-53d8i.net',
        'xn--papl-73d6i.org',
        'xn--ypal-43d9g.com',
        'xn--pypl-53dc.net',
      ]);
      for (final d in result.domains) {
        expect(d, startsWith('xn--'));
      }
    });

    test('OracleSeed golden + requires material', () async {
      final material =
          Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final result = await DGAGenerator(
        DGAConfig(
          algorithm: OracleSeedDGA(
            oracleMaterial: material,
            oracleId: 'lab-btc-tip',
          ),
        ),
      ).generateDomains(date, 5);
      expect(result.algorithm, 'OracleSeed');
      expect(result.metadata['predictability'], 'oracle-seeded');
      expect(result.metadata['needs_oracle_feed'], isTrue);
      expect(result.domains, [
        'av3jg3vw28fva.com',
        'mptm8fmsuc.net',
        'jtfgml1oonu76.org',
        'ttdpryjq8esq.com',
        'x1umnqd6re.net',
      ]);

      await expectLater(
        DGAGenerator(
          DGAConfig(algorithm: const OracleSeedDGA()),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('NestedLabel depth metadata + golden', () async {
      final result = await DGAGenerator(
        DGAConfig(algorithm: const NestedLabelDGA(labelDepth: 3)),
      ).generateDomains(date, 5);
      expect(result.algorithm, 'NestedLabel');
      expect(result.metadata['label_depth'], 3);
      expect(result.metadata['structural_depth_ioc'], isTrue);
      expect(result.domains, [
        'tp8fjp.fvpq.poj264.com',
        'p6z2l32.kyvt91n8.g75i81.net',
        'c5y5z1.na288c.grn.org',
        'j02j.5ri.k4cbo.com',
        '1len.u06a6v.d5wj.net',
      ]);
      for (final d in result.domains) {
        expect(d.split('.').length, greaterThanOrEqualTo(4));
      }
    });

    test('MultiChannel encodes DNS + alt channels', () async {
      final result = await DGAGenerator(
        DGAConfig(algorithm: const MultiChannelDGA()),
      ).generateDomains(date, 5);
      expect(result.algorithm, 'MultiChannel');
      expect(result.metadata['needs_alt_channel_telemetry'], isTrue);
      expect(result.domains, [
        'mxbpszc7hvfd.com',
        '6ozlu8irpjd1.net',
        'syrcngfro59m.com',
        'ze9jcll5z584.net',
        '9ybxitdopt13.com',
      ]);
      final encodings =
          result.metadata['channel_encodings'] as List<dynamic>;
      expect(encodings.first['doh'], contains('doh://'));
      expect(encodings.first['chat'], startsWith('@pqdga_'));
    });

    test('FastFlux attaches schedule metadata', () async {
      final result = await DGAGenerator(
        DGAConfig(algorithm: const FastFluxDGA()),
      ).generateDomains(date, 5);
      expect(result.algorithm, 'FastFlux');
      expect(result.metadata['needs_infra_correlation'], isTrue);
      expect(result.metadata['flux_ttl_seconds'], 60);
      expect(result.domains, [
        '4zufol6t7o.com',
        'ah5vqaiwa0ap0mv.net',
        'v5oyghpjc3h.org',
        'mkupokcp47nynq9.info',
        '5j5ysl1lypgq5.com',
      ]);
    });
  });

  group('Classical P1/P2 goldens', () {
    final date = DateTime.utc(2024, 6, 15, 12);

    test('P1 Ramnit/Nymaim/Shiotob/Pykspa/Vawtrak/Emotet', () async {
      Future<List<String>> gen(DGAAlgorithm a) async =>
          (await DGAGenerator(DGAConfig(algorithm: a)).generateDomains(date, 5))
              .domains;

      // Defaults are literature-perfect seeds (baderj); date 2024-06-15 pin.
      expect(await gen(const RamnitDGA()), [
        'prklqkkwhgpshiejk.click',
        'rvcophrldij.com',
        'jwerjdldqihxucyfoh.eu',
        'kihjtklbkgdn.bid',
        'obmyqaflbudqfssibeb.click',
      ]);
      expect(await gen(const NymaimDGA()), [
        'fzccdhdgwi.info',
        'sczmuewtex.com',
        'tvnfwaffhaz.com',
        'wqlnwri.net',
        'frfrpgahane.biz',
      ]);
      expect(await gen(const ShiotobDGA()), [
        '4ypv1eehphg3a.com',
        'dduub92cik.net',
        'fzwrzifvtl.com',
        'wnjjsiya5x.net',
        'zyvdupb4uk.com',
      ]);
      expect(await gen(const PykspaDGA()), [
        'oigsvwiugkeq.info',
        'iqsgnsdsholapet.org',
        'ifzyzwnansnan.cc',
        'syagts.biz',
        'uqsssa.biz',
      ]);
      expect(await gen(const VawtrakDGA()), [
        'detglevgza.top',
        'arcxcps.top',
        'avgjqduxq.top',
        'kjolgrovcf.top',
        'tefsbuv.top',
      ]);
      expect(await gen(const EmotetDGA()), [
        'hebpvttrqrtycsbw.com',
        'ebpvttrqrtycsbwkz.net',
        'bpvttrqrtycsbwkzgc.org',
        'pvttrqrtycsbwkzgc.info',
        'vttrqrtycsbwk.biz',
      ]);
    });

    test('P2 Kraken/Torpig/CoreBot/DirCrypt/Proslikefan', () async {
      Future<DGAResult> gen(DGAAlgorithm a) async =>
          DGAGenerator(DGAConfig(algorithm: a)).generateDomains(date, 5);

      final kraken = await gen(const KrakenDGA());
      expect(kraken.algorithm, 'Kraken');
      expect(kraken.domains, [
        'duugsbhvssc.com',
        'awrzhika.com',
        'lvctmusxcyz.net',
        'yeovgouhorts.net',
        'egbmbdey.tv',
      ]);

      final torpig = await gen(const TorpigDGA());
      expect(torpig.metadata['seed_rotation_lesson'], isTrue);
      expect(torpig.domains, [
        'ewfqkieqfze.com',
        'wfqkieqfzet.net',
        'fqkieqfze.biz',
        'qkieqfze.org',
        'kieqfzetu.com',
      ]);

      final core = await gen(const CoreBotDGA());
      expect(core.metadata['prng'], 'numerical_recipes_lcg');
      expect(core.domains, [
        '6atc2cj7di6m27jy65.ddns.net',
        'snulydahclid1hwt1ry.ddns.net',
        'efsfen3vctopob3.ddns.net',
        'wpud3830cnc6k0a.ddns.net',
        'afsryv3fkpmjsdy.ddns.net',
      ]);

      final dir = await gen(const DirCryptDGA());
      expect(dir.domains, [
        'omihgxsjrjp.com',
        'tdqqrkabur.com',
        'ergxmwbqepucr.com',
        'czmhrhllgzvxzxmwb.com',
        'ibzcbcnbcjqofidoa.com',
      ]);

      final pros = await gen(const ProslikefanDGA());
      expect(pros.domains, [
        'flneydke.com',
        'mvnpbd.net',
        'xytiekrwkca.biz',
        'qxdddnfzs.ru',
        'hprvngdr.cc',
      ]);
    });
  });

  group('Classical pre-P0 golden coverage', () {
    final date = DateTime.utc(2024, 6, 15, 12);
    final words = ['alpha', 'bravo', 'charlie', 'delta', 'echo', 'foxtrot'];

    Future<List<String>> gen(DGAAlgorithm a, {int n = 3}) async =>
        (await DGAGenerator(DGAConfig(algorithm: a)).generateDomains(date, n))
            .domains;

    test('malware-style pre-P0 families pin domains', () async {
      expect(await gen(const MatsnuDGA()), [
        'c2cb5d2a3705.com',
        'cb5d2a37053b.net',
        '5d2a37053b30.org',
      ]);
      expect(await gen(const NecursDGA()), [
        'imcapoitewayexetexu.br',
        'ykgezuklmheonqake.ie',
        'obvzilavijesoa.ro',
      ]);
      expect(await gen(const PushdoDGA()), [
        '6n2l2qf7hb9f.com',
        '3q64gnk7q4us.net',
        'jfdqxgw0vy3l.org',
      ]);
      expect(await gen(const ConfickerDGA()), [
        'fmywewlgm.org',
        'mywewlgmiox.cc',
        'ywewlgmi.cc',
      ]);
      expect(await gen(const RovnixDGA()), [
        'eoonrkvoag.ru',
        'auenuuawajii.ru',
        'akqeumeaabkyr.ru',
      ]);
      expect(await gen(const CryptoLockerDGA()), [
        'pboyhcyjehchn.biz',
        'aevpjagvyxibfzlbh.ru',
        'nflsdnnpaxgpuqgynvkk.ru',
      ]);
      expect(await gen(BamitalDGA(wordList: words)), [
        'deltadelta23.com',
        'echoalpha98.com',
        'foxtrotalpha79.com',
      ]);
      expect(await gen(const TinbaDGA()), [
        'ks42zktggv8jh9.ru',
        'vwan2ww5a8nxsj.net',
        'argyuld83z9qft.com',
      ]);
      expect(await gen(const MurofetDGA()), [
        'prxfmlatoawb.biz',
        'uphsdlmz.org',
        'dablvvzv.biz',
      ]);
      expect(await gen(const SimdaDGA()), [
        'gbh0svw4x462k6gc.com',
        '13ay00d3q2mr36b1.net',
        'h9r86cwzev4lpt0m.org',
      ]);
    });

    test('generic pre-P0 families pin domains', () async {
      expect(await gen(const TimeBasedDGA(seed: 'lab')), [
        '59jrjcqmjjntc7b.org',
        'm0a6ztga.com',
        'eil776kbs2tv.net',
      ]);
      expect(await gen(const ArithmeticDGA(seed: 42)), [
        'fk5qzg5in4.com',
        'k5qzg5in4t.com',
        '5qzg5in4tu.com',
      ]);
      expect(await gen(const PermutationDGA(baseDomain: 'labseed01.com')), [
        'ld0aoecm1se.b.com',
        '.dcbls0ao1eem.com',
        'a1mo.bdes0lec.com',
      ]);
      expect(await gen(DictionaryBasedDGA(wordList: words)), [
        'foxtrotdelta.net',
        'deltabravo.com',
        'alphaecho.com',
      ]);
    });
  });

  group('PQ extras goldens', () {
    final date = DateTime.utc(2024, 6, 15, 12);
    final kemSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    final encNonce = Uint8List.fromList(List<int>.generate(32, (i) => 100 + i));

    test('EnvelopeRendezvous short decoy + envelope IOC', () async {
      final session = EnvelopeRendezvousPqdga.labEstablish(
        kemSeed: kemSeed,
        encapsNonce: encNonce,
      );
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 3);

      expect(result.algorithm, 'EnvelopeRendezvous');
      expect(result.predictable, isFalse);
      expect(result.secretBound, isTrue);
      expect(result.kemAlgorithm, 'ML-KEM-768');
      expect(result.kemCiphertextLength, 1088);
      expect(result.metadata['decoy_domain'], isTrue);
      expect(result.metadata['envelope_payload_length'], isNotNull);
      expect(result.metadata['playbook_flags']['name_is_decoy'], isTrue);
      expect(result.domains, [
        '6nxm8pii.org',
        '6j51yzmj.net',
        '0drn2vpw.com',
      ]);
      for (final d in result.domains) {
        expect(DnsLabelCodec.validateFqdn(d).isSuccess, isTrue);
      }
    });

    test('EnvelopeRendezvous missing materials throws', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const EnvelopeRendezvousPqdga()),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('RateLimited caps emission per hour', () async {
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: const RateLimitedPqdga(maxNamesPerHour: 2),
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 10);

      expect(result.algorithm, 'RateLimited');
      expect(result.predictable, isTrue);
      expect(result.secretBound, isFalse);
      expect(result.domains.length, 2);
      expect(result.metadata['capped'], isTrue);
      expect(result.metadata['effective_cap'], 2);
      expect(result.metadata['playbook_flags']['rate_limited'], isTrue);
      expect(result.domains, [
        'lcojbsa91x3v.com',
        'o0jgco2z.net',
      ]);
    });

    test('MultiRecipient compartmentation golden', () async {
      final session = MultiRecipientPqdga.labEstablish(
        additionalRecipients: 2,
        primarySeed: kemSeed,
        encapsNonce: encNonce,
      );
      final result = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 3);

      expect(result.algorithm, 'MultiRecipient');
      expect(result.predictable, isFalse);
      expect(result.secretBound, isTrue);
      expect(result.kemCiphertextLength, 1088);
      expect(result.metadata['additional_recipient_count'], 2);
      expect(result.metadata['playbook_flags']['compartmentation'], isTrue);
      expect(result.domains, [
        'winwks2yn53.net',
        'x1fvk6fhl.net',
        '880y7c13x.com',
      ]);
    });

    test('MultiRecipient missing session key throws', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const MultiRecipientPqdga()),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });


  group('R9 binding research ladder', () {
    final fixedSs = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    final date = DateTime.utc(2024, 6, 15, 12);

    test('KMAC256 matches NIST SP 800-185 / BouncyCastle sample vectors', () {
      // NIST SP 800-185 samples (as in BouncyCastle KMACTest):
      // K = 40..5f (32 bytes), X = 00010203
      final key = Uint8List.fromList([
        for (var i = 0x40; i <= 0x5f; i++) i,
      ]);
      final data = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

      // S = "My Tagged Application", L = 512 bits (64 bytes)
      final tagged = Kmac256.macUtf8(
        key: key,
        data: data,
        outputLengthBytes: 64,
        customization: 'My Tagged Application',
      );
      expect(
        tagged.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '20c570c31346f703c9ac36c61c03cb64c3970d0cfc787e9b79599d273a68d2f7'
        'f69d4cc3de9d104a351689f27cf6f5951f0103f33f4f24871024d9c27773a8dd',
      );

      // S = empty, L = 256 bits — independent pure-Keccak reference agrees
      // with this implementation (cSHAKE256 path verified vs NIST cSHAKE sample).
      final emptyS = Kmac256.mac(
        key: key,
        data: data,
        outputLengthBytes: 32,
      );
      expect(
        emptyS.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        'b423798ac38d465560a058b982f56f7ff5d62a5cfa813ab8522998ed32e00a38',
      );

      // Different customization must change the MAC.
      expect(tagged.sublist(0, 32), isNot(equals(emptyS)));
    });

    test('R9a KmacSharedSecret golden + differs from SHAKE SharedSecret', () async {
      final kmac = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: KmacSharedSecretPqdga(
            sharedSecret: fixedSs,
            campaignId: 'toy-campaign',
            kemCiphertext: Uint8List(1088),
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);

      final shake = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(
            sharedSecret: fixedSs,
            campaignId: 'toy-campaign',
            kemCiphertext: Uint8List(1088),
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 5);

      expect(kmac.algorithm, 'KmacSharedSecret');
      expect(kmac.xof, 'KMAC256');
      expect(kmac.predictable, isFalse);
      expect(kmac.secretBound, isTrue);
      expect(kmac.kemCiphertextLength, 1088);
      expect(kmac.metadata['binding_mode'], 'kmac-shared-secret');
      expect(kmac.metadata['playbook_flags']['binding_ladder'], 'R9a');
      expect(kmac.domains, isNot(equals(shake.domains)));
      expect(kmac.domains, hasLength(5));
      for (final d in kmac.domains) {
        expect(DnsLabelCodec.validateFqdn(d).isSuccess, isTrue);
      }
      expect(kmac.seed.contains('010203'), isFalse);
    });

    test('R9a KmacSharedSecret missing material throws', () async {
      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: const KmacSharedSecretPqdga()),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('R9a labEstablish decaps round-trip', () async {
      final kemSeed = Uint8List.fromList(List<int>.generate(64, (i) => i + 3));
      final encapsNonce =
          Uint8List.fromList(List<int>.generate(32, (i) => 180 - i));
      final session = KmacSharedSecretPqdga.labEstablish(
        kemSeed: kemSeed,
        encapsNonce: encapsNonce,
        campaignId: 'toy-kmac-rt',
      );
      final a = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      final b = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.asDecapsConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      expect(a.domains, b.domains);
      expect(a.secretBound, isTrue);
    });

    test('R9b HybridKmac golden + differs from Hybrid SHAKE', () async {
      final classical =
          Uint8List.fromList(List<int>.generate(32, (i) => 0xA0 + (i & 0x0f)));
      final pqSs =
          Uint8List.fromList(List<int>.generate(32, (i) => 0x10 + i));
      final kmacSession = HybridKmacPqdga.labEstablish(
        classicalSharedSecret: classical,
        postQuantumSharedSecret: pqSs,
      );
      final shakeSession = HybridSharedSecretPqdga.labEstablish(
        classicalSharedSecret: classical,
        postQuantumSharedSecret: pqSs,
      );

      final kmac = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: kmacSession.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 3);
      final shake = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: shakeSession.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 3);

      expect(kmac.algorithm, 'HybridKmac');
      expect(kmac.xof, 'KMAC256');
      expect(kmac.secretBound, isTrue);
      expect(kmac.metadata['binding_mode'], 'hybrid-kmac');
      expect(kmac.metadata['playbook_flags']['needs_classical_and_pq_break'], isTrue);
      expect(kmac.domains, isNot(equals(shake.domains)));
      expect(kmac.domains, hasLength(3));

      final viaCombiner = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: kmacSession.asCombinerConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
          seedRotationDays: 1,
        ),
      ).generateDomains(date, 3);
      expect(viaCombiner.domains, kmac.domains);
    });

    test('R9c Ratcheting advance changes names; epoch-only matches', () async {
      final root =
          Uint8List.fromList(List<int>.generate(32, (i) => 0xC0 + (i & 0x0f)));
      final s0 = RatchetingPqdga.labEstablish(rootSecret: root, epochIndex: 0);
      final s1 = s0.advance();

      final r0 = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: s0.asEpochOnlyConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      final r1 = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: s1.asEpochOnlyConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      final r0FromRoot = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: RatchetingPqdga(
            rootSecret: root,
            epochIndex: 0,
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);

      expect(r0.algorithm, 'Ratcheting');
      expect(r0.secretBound, isTrue);
      expect(r0.metadata['epoch_index'], 0);
      expect(r1.metadata['epoch_index'], 1);
      expect(r0.domains, isNot(equals(r1.domains)));
      expect(r0.domains, r0FromRoot.domains);
      expect(r0.metadata['claims_forward_secrecy'], isFalse);
      expect(r0.metadata['forward_evolution_experiment'], isTrue);
    });

    test('R9d Hierarchical siblings differ; leaf-only matches', () async {
      final root =
          Uint8List.fromList(List<int>.generate(32, (i) => 0xD0 + (i & 0x0f)));
      final team1 = HierarchicalPqdga.labEstablish(
        rootSecret: root,
        hierarchyPath: const ['region-a', 'team-1'],
      );
      final team2 = team1.deriveSibling(const ['region-a', 'team-2']);

      final a = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: team1.asLeafOnlyConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      final b = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: team2.asLeafOnlyConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      final a2 = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: HierarchicalPqdga(
            rootSecret: root,
            hierarchyPath: const ['region-a', 'team-1'],
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);

      expect(a.algorithm, 'Hierarchical');
      expect(a.secretBound, isTrue);
      expect(a.metadata['hierarchy_path'], ['region-a', 'team-1']);
      expect(a.domains, isNot(equals(b.domains)));
      expect(a.domains, a2.domains);
    });

    test('R9e MultiParty requires all parties', () async {
      final session = MultiPartyPqdga.labEstablish(partyCount: 3);
      final ok = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.asSecretsOnlyConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      expect(ok.algorithm, 'MultiParty');
      expect(ok.secretBound, isTrue);
      expect(ok.metadata['party_count'], 3);
      expect(ok.metadata['distinct_from_multi_recipient'], isTrue);
      expect(ok.domains, hasLength(3));

      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: session.withoutParty(1)),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('R9f Threshold k-of-n quorum', () async {
      final session = ThresholdPqdga.labEstablish(threshold: 2, totalShares: 3);
      final ok = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.withShareIndices([1, 2]),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      expect(ok.algorithm, 'Threshold');
      expect(ok.secretBound, isTrue);
      expect(ok.metadata['threshold_k'], 2);
      expect(ok.metadata['lab_not_production_tss'], isTrue);
      expect(ok.domains, hasLength(3));

      // Same first-k set after sort should match binding from labEstablish.
      final direct = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      expect(direct.domains, ok.domains);

      await expectLater(
        PQDGAGenerator(
          PQDGAConfig(algorithm: session.withShareIndices([1])),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('R9g AuthenticatedContext auth-only vs secret-bound', () async {
      final sigSeed =
          Uint8List.fromList(List<int>.generate(32, (i) => 50 + i));
      final session = AuthenticatedContextPqdga.labEstablish(
        sigSeed: sigSeed,
      );
      final authOnly = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.asAuthOnlyConfig,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 2);

      expect(authOnly.algorithm, 'AuthenticatedContext');
      expect(authOnly.predictable, isTrue);
      expect(authOnly.secretBound, isFalse);
      expect(authOnly.signatures, isNotNull);
      expect(authOnly.signatures!, hasLength(2));
      expect(authOnly.metadata['authenticity'], isTrue);
      expect(authOnly.metadata['confidentiality'], isFalse);
      expect(authOnly.pubkeyFingerprint, isNotNull);

      final secret =
          Uint8List.fromList(List<int>.generate(32, (i) => 0x30 + i));
      final bound = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.withSecret(secret),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 2);
      expect(bound.predictable, isFalse);
      expect(bound.secretBound, isTrue);
      expect(bound.metadata['confidentiality'], isTrue);
      expect(bound.domains, isNot(equals(authOnly.domains)));
    });

    test('R9 registry contains all binding ladder families', () {
      expect(PQDGAGenerator.registry.containsKey(KmacSharedSecretPqdga), isTrue);
      expect(PQDGAGenerator.registry.containsKey(HybridKmacPqdga), isTrue);
      expect(PQDGAGenerator.registry.containsKey(RatchetingPqdga), isTrue);
      expect(PQDGAGenerator.registry.containsKey(HierarchicalPqdga), isTrue);
      expect(PQDGAGenerator.registry.containsKey(MultiPartyPqdga), isTrue);
      expect(PQDGAGenerator.registry.containsKey(ThresholdPqdga), isTrue);
      expect(
        PQDGAGenerator.registry.containsKey(AuthenticatedContextPqdga),
        isTrue,
      );
    });
  });

  group('Classical SOC metadata + IOC polish', () {
    final date = DateTime.utc(2024, 6, 15);

    Future<DGAResult> gen(DGAAlgorithm algo, {int n = 3}) =>
        DGAGenerator(DGAConfig(algorithm: algo)).generateDomains(date, n);

    void expectSocContract(DGAResult r) {
      expect(r.metadata['predictability'], isNotNull);
      expect(r.metadata['predictable'], isA<bool>());
      expect(r.metadata['secret_bound'], isA<bool>());
      expect(r.metadata['playbook_flags'], isA<Map>());
      expect(r.metadata['soc_lesson'], isNotNull);
      final ioc = SocFeatures.iocTemplateFromDga(r);
      expect(ioc['algorithm'], r.algorithm);
      expect(ioc['predictability'], r.metadata['predictability']);
      final hard = HardnessScorecard.fromDgaResult(r);
      expect(hard.scores.keys, containsAll(['H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7']));
    }

    test('baseline malware-style emit full SOC metadata', () async {
      final samples = <DGAResult>[
        await gen(const ConfickerDGA()),
        await gen(const NecursDGA()),
        await gen(const PushdoDGA()),
        await gen(const RovnixDGA()),
        await gen(const CryptoLockerDGA()),
        await gen(BamitalDGA(wordList: const ['alpha', 'bravo', 'charlie'])),
        await gen(const TinbaDGA(botId: 0x11)),
        await gen(const MurofetDGA()),
        await gen(const SimdaDGA()),
        await gen(const MatsnuDGA()),
      ];
      for (final r in samples) {
        expectSocContract(r);
      }
      expect(samples.first.metadata['predictability'], 'trivial');
      expect(
        (samples.first.metadata['playbook_flags'] as Map)['sinkhole_precompute'],
        isTrue,
      );
    });

    test('generics + P0 emit playbook flags and IOC templates', () async {
      final dict = await gen(
        DictionaryBasedDGA(wordList: const ['one', 'two', 'three']),
      );
      expectSocContract(dict);
      expect(dict.metadata['needs_lexical_model'], isTrue);
      expect(
        (dict.metadata['playbook_flags'] as Map)['needs_lexical_model'],
        isTrue,
      );

      final locky = await gen(const LockyDGA());
      expectSocContract(locky);
      expect(locky.metadata['predictability'], 'trivial');

      final qak = await gen(const QakBotDGA(configSeed: 0));
      expectSocContract(qak);
      expect(qak.metadata['predictability'], 'config-seeded');
    });

    test('HardnessScorecard classical vs PQ inference', () async {
      final matsnu = await gen(const MatsnuDGA());
      final c = HardnessScorecard.fromDgaResult(matsnu);
      expect(c.h1, 0);
      expect(c.counters, contains('sinkhole_precompute'));

      final qr = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: const QuantumResistantPqdga(campaignId: 'toy'),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 2);
      final pqCard = HardnessScorecard.fromPqdgaResult(qr);
      expect(pqCard.h1, 0);
      expect(pqCard.summaryLine, contains('H1:'));
      final ioc = SocFeatures.iocTemplateFromPqdga(qr);
      expect(ioc['predictable'], isTrue);
    });
  });

  group('Post-R9 deferred extras (pqforge/pqcrypto hooks)', () {
    final date = DateTime.utc(2024, 6, 15);

    test('LexicalSharedSecret markov secret-bound + H5 lexical', () async {
      final ss = Uint8List.fromList(List<int>.generate(32, (i) => 0x30 + i));
      final ct = Uint8List(1088);
      final r = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: LexicalSharedSecretPqdga(
            sharedSecret: ss,
            kemCiphertext: ct,
            campaignId: 'lex-lab',
            lexicalMode: 'markov',
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      expect(r.algorithm, 'LexicalSharedSecret');
      expect(r.secretBound, isTrue);
      expect(r.predictable, isFalse);
      expect(r.domains, hasLength(3));
      expect(r.metadata['needs_lexical_model'], isTrue);
      expect(r.metadata['lexical_mode'], 'markov');
      final hard = HardnessScorecard.fromPqdgaResult(r);
      expect(hard.h1, 2);
      expect(hard.h5, 2);
      expect(hard.counters, contains('lexical_model'));

      // Deterministic with fixed ss.
      final r2 = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: LexicalSharedSecretPqdga(
            sharedSecret: ss,
            kemCiphertext: ct,
            campaignId: 'lex-lab',
            lexicalMode: 'markov',
          ),
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 3);
      expect(r2.domains, r.domains);
    });

    test('LexicalSharedSecret labEstablish decaps path', () async {
      final session = LexicalSharedSecretPqdga.labEstablish(
        encapsNonce: Uint8List.fromList(List<int>.filled(32, 7)),
        kemSeed: Uint8List.fromList(List<int>.generate(64, (i) => i + 1)),
        lexicalMode: 'pronounceable',
      );
      final a = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 2);
      final b = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.asDecapsConfig,
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 2);
      expect(b.domains, a.domains);
      expect(a.kemCiphertextLength, greaterThan(0));
    });

    test('LexicalSharedSecret missing material throws', () async {
      expect(
        () => PQDGAGenerator(
          PQDGAConfig(
            algorithm: const LexicalSharedSecretPqdga(),
            minDomainLength: 8,
            maxDomainLength: 12,
          ),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'SlhDsaCheckpoint real pqcrypto FIPS 205 seal + size IOC',
      () async {
        final session = SlhDsaCheckpointPqdga.labEstablish(
          parameterSet: SlhDsaSizes.slhDsaShake_128f,
          campaignId: 'slh-lab',
          checkpointEvery: 1,
        );
        final r = await PQDGAGenerator(
          PQDGAConfig(
            algorithm: session.algorithm,
            minDomainLength: 8,
            maxDomainLength: 12,
          ),
        ).generateDomains(date, 1);
        expect(r.algorithm, 'SlhDsaCheckpoint');
        expect(r.sigAlgorithm, SlhDsaSizes.slhDsaShake_128f.name);
        expect(
          r.signatureLength,
          SlhDsaSizes.slhDsaShake_128f.signatureBytes,
        );
        expect(r.signatures, isNotNull);
        expect(r.signatures!, hasLength(1));
        expect(
          r.signatures!.first.length,
          SlhDsaSizes.slhDsaShake_128f.signatureBytes,
        );
        expect(r.metadata['slh_dsa_crypto'], 'fips-205-pqcrypto');
        expect(r.metadata['primitive'], 'pqcrypto.SlhDsa');
        expect(
          session.verify(
            domain: r.domains.first,
            epoch: r.epoch!,
            counter: 0,
            signature: r.signatures!.first,
          ),
          isTrue,
        );
        final hard = HardnessScorecard.fromPqdgaResult(r);
        expect(hard.h2, 2);
        expect(hard.counters, contains('slh_dsa_size_ioc'));
        final catalog = DetectorNotebook.slhDsaSizeIocs();
        expect(catalog['crypto_status'], 'fips-205-pqcrypto');
        expect(catalog['parameter_sets'], isNotEmpty);
      },
      timeout: Timeout(Duration(minutes: 2)),
    );

    test('SlhDsaCheckpoint missing key throws when required', () async {
      expect(
        () => PQDGAGenerator(
          PQDGAConfig(
            algorithm: const SlhDsaCheckpointPqdga(requireCheckpoint: true),
            minDomainLength: 8,
            maxDomainLength: 12,
          ),
        ).generateDomains(date, 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('HybridAuthenticated dual-sign via PqForgeHybridSigner', () async {
      final pqcSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 3));
      final classicalSeed =
          Uint8List.fromList(List<int>.generate(32, (i) => 0x80 + i));
      final session = await HybridAuthenticatedPqdga.labEstablish(
        pqcSeed: pqcSeed,
        classicalSeed: classicalSeed,
        campaignId: 'hyb-auth',
      );
      final r = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: session.algorithm,
          minDomainLength: 8,
          maxDomainLength: 12,
        ),
      ).generateDomains(date, 2);
      expect(r.algorithm, 'HybridAuthenticated');
      expect(r.signatures, hasLength(2));
      expect(r.metadata['primitive'], 'pqforge.PqForgeHybridSigner');
      expect(r.metadata['dual_policy'], 'requireBoth');
      final classicalB64 = r.metadata['classical_signatures_b64'] as List;
      expect(classicalB64, hasLength(2));
      // Verify first domain dual signature.
      final ok = await session.verify(
        domain: r.domains.first,
        epoch: r.epoch!,
        pqcSignature: r.signatures!.first,
        classicalSignature: base64Decode(classicalB64.first as String),
      );
      expect(ok, isTrue);
      final hard = HardnessScorecard.fromPqdgaResult(r);
      expect(hard.h2, 2);
      expect(hard.h4, 2);
    });

    test('PostRendezvousSession AEAD round-trip via PqForgeSecureSession',
        () async {
      final ss = Uint8List.fromList(List<int>.generate(32, (i) => 0x11 + i));
      final shared = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(
            sharedSecret: ss,
            kemCiphertext: Uint8List(1088),
            campaignId: 'sess',
          ),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 1);
      final session = PostRendezvousSession.fromPqdgaResult(shared, ss);
      final payload = Uint8List.fromList('lab-app-payload'.codeUnits);
      expect(await session.roundTripOk(payload), isTrue);
      final packet = await session.seal(payload);
      final notebook = DetectorNotebook.withPostRendezvous(
        shared,
        session,
        lastPacketLength: packet.length,
      );
      expect(notebook['post_rendezvous']['not_a_dga'], isTrue);
      expect(notebook['post_rendezvous']['cipher_suite'], isNotNull);
      session.dispose();
    });

    test('BindingAnalysis suite + LabHarness + LiteratureCorpus smoke',
        () async {
      final suite = await BindingAnalysis.runAll();
      expect(suite['suite'], 'binding_ladder_analysis');
      final kmac = suite['experiments']['kmac_vs_shake'] as Map;
      expect(kmac['outputs_differ'], isTrue);
      final ratchet = suite['experiments']['ratchet_delete_forward'] as Map;
      expect(ratchet['later_key_reconstructs_earlier_names'], isFalse);
      expect(BindingAnalysis.writeups().keys, contains('R9a_kmac_vs_R4_shake'));

      final buckets = LabHarness.epochBucketsInRange(
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 1, 10),
        rotationDays: 3,
      );
      expect(buckets, isNotEmpty);
      expect(LabHarness.memoizedEntropy('example.com'), greaterThan(0));
      expect(
        LabHarness.dateRangeDayCount(
          DateTime.utc(2024, 1, 1),
          DateTime.utc(2024, 1, 3),
        ),
        3,
      );
      final cronHits = LabHarness.cronMatchesInRange(
        '0 0 * * *',
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 1, 3),
      );
      expect(cronHits, isNotEmpty);

      LabHarness.enableLogCapture();
      LabHarness.logEvent('unit_test_event', fields: {'ok': true});
      expect(LabHarness.logCapture, isNotEmpty);
      LabHarness.disableLogCapture();

      final note = LiteratureCorpus.find('Ramnit');
      expect(note, isNotNull);
      expect(note!.fidelity, 'literature-perfect');
      expect(LiteratureCorpus.rekeyChecklist('Ramnit'), isNotEmpty);
      expect(SlhDsaProvider.pqforgeExposesSlhDsa, isFalse);
      expect(SlhDsaProvider.backendId, 'pqcrypto.SlhDsa');
    });

    test('NotebookConsumer wires DetectorNotebook + hardness + SLH catalog',
        () async {
      final dga = await DGAGenerator(
        DGAConfig(algorithm: const RamnitDGA()),
      ).generateDomains(DateTime.utc(2015, 5, 14), 3);
      final pack = NotebookConsumer.consumeDga(dga);
      expect(pack['consumer'], 'NotebookConsumer.consumeDga');
      expect(pack['notebook']['kind'], 'classical');
      expect(pack['hardness_scorecard']['hardness'], isNotNull);
      expect(pack['literature']['fidelity'], 'literature-perfect');
      expect(pack['codec_pipeline_rows'], hasLength(3));

      final ss = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final pq = await PQDGAGenerator(
        PQDGAConfig(
          algorithm: SharedSecretPqdga(
            sharedSecret: ss,
            kemCiphertext: Uint8List(1088),
          ),
          minDomainLength: 8,
          maxDomainLength: 10,
        ),
      ).generateDomains(date, 2);
      final pqPack = NotebookConsumer.consumePqdga(pq, includeSlhCatalog: true);
      expect(pqPack['notebook']['kind'], 'post_quantum');
      expect(pqPack['slh_dsa_size_iocs']['crypto_status'], 'fips-205-pqcrypto');

      final catalog = NotebookConsumer.consumeSlhSizeCatalog();
      expect(catalog['catalog']['parameter_sets'], isNotEmpty);
      expect(catalog['catalog']['pqforge_exposes_slh_dsa'], isFalse);

      final analysis = await NotebookConsumer.consumeBindingAnalysis();
      expect(analysis['writeups'], isNotEmpty);
      expect(analysis['suite']['experiments'], isNotEmpty);
    });

    test('Registry contains post-R9 extras', () {
      expect(
        PQDGAGenerator.registry.keys,
        containsAll([
          LexicalSharedSecretPqdga,
          SlhDsaCheckpointPqdga,
          HybridAuthenticatedPqdga,
        ]),
      );
    });
  });

  group('P1/P2 literature-perfect goldens (baderj)', () {
    final pin = DateTime.utc(2015, 5, 14);

    Future<List<String>> gen(DGAAlgorithm a, {int n = 5}) async =>
        (await DGAGenerator(DGAConfig(algorithm: a)).generateDomains(pin, n))
            .domains;

    test('Ramnit Park–Miller known seed', () async {
      final d = await gen(const RamnitDGA());
      expect(d.take(5), [
        'prklqkkwhgpshiejk.click',
        'rvcophrldij.com',
        'jwerjdldqihxucyfoh.eu',
        'kihjtklbkgdn.bid',
        'obmyqaflbudqfssibeb.click',
      ]);
      final r = await DGAGenerator(DGAConfig(algorithm: const RamnitDGA()))
          .generateDomains(pin, 1);
      expect(r.metadata['fidelity'], 'literature-perfect');
      expect(r.metadata['literature'], contains('baderj'));
    });

    test('Nymaim date PRNG', () async {
      expect(await gen(const NymaimDGA()), [
        'rjvoupbixei.com',
        'ogqywunvso.net',
        'vfnevybb.com',
        'mwejxrzgip.com',
        'tkufyyjg.org',
      ]);
    });

    test('Shiotob seed-domain mutation (date-independent)', () async {
      final a = await gen(const ShiotobDGA());
      final b = await gen(const ShiotobDGA());
      // same seed domain stream regardless of pin date used above
      expect(a, b);
      expect(a, [
        '4ypv1eehphg3a.com',
        'dduub92cik.net',
        'fzwrzifvtl.com',
        'wnjjsiya5x.net',
        'zyvdupb4uk.com',
      ]);
    });

    test('Vawtrak glibc LCG', () async {
      expect(await gen(const VawtrakDGA()), [
        'detglevgza.top',
        'arcxcps.top',
        'avgjqduxq.top',
        'kjolgrovcf.top',
        'tefsbuv.top',
      ]);
    });

    test('DirCrypt Park–Miller', () async {
      expect(await gen(const DirCryptDGA()), [
        'omihgxsjrjp.com',
        'tdqqrkabur.com',
        'ergxmwbqepucr.com',
        'czmhrhllgzvxzxmwb.com',
        'ibzcbcnbcjqofidoa.com',
      ]);
    });

    test('Corebot NR LCG + ddns.net', () async {
      expect(await gen(const CoreBotDGA()), [
        'vgfofehgj5vchstmla6s.ddns.net',
        '3pqfkxqvy252yxi4uxkjc8a.ddns.net',
        '5junclmlqr5t561.ddns.net',
        'cbwxk0m0mjk25r5luxu.ddns.net',
        'mv3254mxa0uxu4cvkjgdg83.ddns.net',
      ]);
    });

    test('Proslikefan string-hash', () async {
      expect(await gen(const ProslikefanDGA()), [
        'gxguijagrkt.com',
        'megiujkh.net',
        'sxfngve.biz',
        'bnlctch.ru',
        'nlppkpjcss.cc',
      ]);
    });

    test('Kraken v2 seed set a', () async {
      expect(await gen(const KrakenDGA()), [
        'klrbvjtb.com',
        'uaazieqmts.com',
        'zoipmnwr.net',
        'jbtobfdwjfzp.net',
        'smmyuhxlt.tv',
      ]);
    });

    test('Pykspa precursor 2-day bucket', () async {
      expect(await gen(const PykspaDGA()), [
        'ycaywwiugkeq.info',
        'fqouxifox.cc',
        'rktqeifox.com',
        'cyygawiq.info',
        'uismsmiq.biz',
      ]);
    });

    test('Torpig window model stable within week', () async {
      final a = await DGAGenerator(DGAConfig(algorithm: const TorpigDGA()))
          .generateDomains(DateTime.utc(2024, 6, 10), 3);
      final b = await DGAGenerator(DGAConfig(algorithm: const TorpigDGA()))
          .generateDomains(DateTime.utc(2024, 6, 12), 3);
      final c = await DGAGenerator(DGAConfig(algorithm: const TorpigDGA()))
          .generateDomains(DateTime.utc(2024, 6, 17), 3);
      expect(a.domains, b.domains);
      expect(a.domains, isNot(equals(c.domains)));
      expect(a.metadata['fidelity'], 'research-model');
    });

    test('Emotet remains research-model volume family', () async {
      final r = await DGAGenerator(DGAConfig(algorithm: const EmotetDGA()))
          .generateDomains(pin, 5);
      expect(r.domains, hasLength(5));
      expect(r.metadata['fidelity'], 'research-model');
      expect(r.metadata['literature'], contains('research-model'));
    });
  });
}
