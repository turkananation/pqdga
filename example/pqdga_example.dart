import 'dart:typed_data';

import 'package:pqdga/pqdga.dart';

void main() async {
  print("════════════════════════════════════════════════════════════");
  print("   PGDGA RESEARCH SUITE - VERIFICATION TESTS");
  print("════════════════════════════════════════════════════════════");

  final now = DateTime.now();
  print("Reference Date: $now\n");

  // 1. NECURS (Complex PRNG + Pronounceability)
  await _runTest("Necurs", () async {
    final config = DGAConfig(
      algorithm: NecursDGA(usePronounceablePattern: true),
    );
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 2. MATSNU (MD5 Hashing)
  await _runTest("Matsnu", () async {
    final config = DGAConfig(algorithm: MatsnuDGA());
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 3. PUSHDO (LCG + Numbers)
  await _runTest("Pushdo", () async {
    final config = DGAConfig(algorithm: PushdoDGA(includeNumbers: true));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 4. CONFICKER (MD5 Seed + High Volume)
  await _runTest("Conficker (Variant C)", () async {
    final config = DGAConfig(algorithm: ConfickerDGA(variant: 'C'));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 5. ROVNIX (CRC32 Checksums)
  await _runTest("Rovnix (v3)", () async {
    final config = DGAConfig(algorithm: RovnixDGA());
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 6. CRYPTOLOCKER (Ransomware Logic)
  await _runTest("CryptoLocker", () async {
    final config = DGAConfig(algorithm: CryptoLockerDGA());
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 7. BAMITAL (Dictionary Composition)
  await _runTest("Bamital", () async {
    // Requires a dictionary source
    final dummyDict = [
      "alpha",
      "bravo",
      "charlie",
      "delta",
      "echo",
      "foxtrot",
      "golf",
      "hotel",
    ];
    final config = DGAConfig(algorithm: BamitalDGA(wordList: dummyDict));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 8. TINBA (Bot-ID Specific)
  await _runTest("Tinba (Tiny Banker)", () async {
    final config = DGAConfig(algorithm: TinbaDGA(botId: 0xDEADBEEF));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 9. MUROFET (Hourly Generation)
  await _runTest("Murofet (Licat)", () async {
    final config = DGAConfig(algorithm: MurofetDGA(useHourlySeed: true));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 10. SIMDA (Simple XOR)
  await _runTest("Simda", () async {
    final config = DGAConfig(algorithm: SimdaDGA());
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  print("════════════════════════════════════════════════════════════");
  print("   GENERIC / HYPOTHETICAL ALGORITHMS");
  print("════════════════════════════════════════════════════════════");

  // 11. PERMUTATION
  await _runTest("Permutation (Base: 'google')", () async {
    final config = DGAConfig(algorithm: PermutationDGA(baseDomain: "google"));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 12. ARITHMETIC
  await _runTest("Arithmetic LCG", () async {
    final config = DGAConfig(algorithm: ArithmeticDGA(seed: 12345));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 13. DICTIONARY
  await _runTest("Dictionary Based", () async {
    final config = DGAConfig(
      algorithm: DictionaryBasedDGA(
        wordList: ["kibaki", "tosha", "kazi", "pamoja"],
      ),
    );
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  // 14. TIME BASED
  await _runTest("Time-Based", () async {
    final config = DGAConfig(algorithm: TimeBasedDGA(seed: "July-30th-2026"));
    return await DGAGenerator(config).generateDomains(now, 20);
  });

  print("════════════════════════════════════════════════════════════");
  print("   CLASSICAL P0 FAMILIES");
  print("════════════════════════════════════════════════════════════");

  // 15. LOCKY
  await _runTest("Locky (v2)", () async {
    final config = DGAConfig(algorithm: const LockyDGA());
    return await DGAGenerator(config).generateDomains(DateTime.utc(2016, 2, 24), 8);
  });

  // 16. QAKBOT
  await _runTest("QakBot", () async {
    final config = DGAConfig(algorithm: const QakBotDGA(configSeed: 0));
    return await DGAGenerator(config).generateDomains(DateTime.utc(2016, 7, 11), 10);
  });

  // 17. BANJORI
  await _runTest("Banjori", () async {
    final config = DGAConfig(algorithm: const BanjoriDGA());
    return await DGAGenerator(config).generateDomains(now, 10);
  });

  // 18. RANBYUS
  await _runTest("Ranbyus (May)", () async {
    final config = DGAConfig(algorithm: const RanbyusDGA());
    return await DGAGenerator(config).generateDomains(DateTime.utc(2015, 5, 14), 8);
  });

  // 19. SUPPOBOX-style (toy wordlist padded for lab demo — use full lists in research)
  await _runTest("Suppobox-style (toy list)", () async {
    final toy = List<String>.generate(256, (i) => 'w${i.toString().padLeft(3, '0')}');
    final config = DGAConfig(
      algorithm: SuppoboxDGA(wordList: toy, unixSeconds: 1451606400),
    );
    return await DGAGenerator(config).generateDomains(DateTime.utc(2016, 1, 1), 5);
  });

  print("════════════════════════════════════════════════════════════");
  print("   POST-QUANTUM (R3 QuantumResistant SHAKE)");
  print("════════════════════════════════════════════════════════════");
  print(
    "SOC lesson: PQ hash ≠ secret — public-seed SHAKE is still precomputable.\n",
  );

  await _runPqTest("QuantumResistant (public seed)", () async {
    final config = PQDGAConfig(
      algorithm: const QuantumResistantPqdga(campaignId: 'toy-campaign'),
      minDomainLength: 8,
      maxDomainLength: 12,
    );
    return await PQDGAGenerator(config)
        .generateDomains(DateTime.utc(2024, 6, 15), 5);
  });

  print("════════════════════════════════════════════════════════════");
  print("   POST-QUANTUM (R4 SharedSecret ML-KEM)");
  print("════════════════════════════════════════════════════════════");
  print(
    "SOC lesson: without ML-KEM shared secret, offline precompute fails — "
    "shift to behavior / registration / first-observe sinkhole.\n",
  );

  await _runPqTest("SharedSecret (labEstablish ML-KEM-768)", () async {
    final session = SharedSecretPqdga.labEstablish(
      campaignId: 'toy-campaign',
    );
    final config = PQDGAConfig(
      algorithm: session.algorithm,
      minDomainLength: 8,
      maxDomainLength: 12,
      includeSubdomains: true,
    );
    return await PQDGAGenerator(config)
        .generateDomains(DateTime.utc(2024, 6, 15), 5);
  });

  print("════════════════════════════════════════════════════════════");
  print("   POST-QUANTUM (R5 SignatureAuthenticated ML-DSA)");
  print("════════════════════════════════════════════════════════════");
  print(
    "SOC lesson: sinkhole IP alone fails if bot requires valid ML-DSA — "
    "hunt sig size + pubkey fingerprint; need key compromise / rewrite.\n",
  );

  await _runPqTest("SignatureAuthenticated (labEstablish ML-DSA-65)", () async {
    final session = SignatureAuthenticatedPqdga.labEstablish(
      campaignId: 'toy-campaign',
    );
    final config = PQDGAConfig(
      algorithm: session.algorithm,
      minDomainLength: 8,
      maxDomainLength: 12,
    );
    final result = await PQDGAGenerator(config)
        .generateDomains(DateTime.utc(2024, 6, 15), 3);
    // Lab verify drill (bot gate before C2 trust).
    for (var i = 0; i < result.domains.length; i++) {
      final ok = session.algorithm.verify(
        domain: result.domains[i],
        epoch: result.epoch!,
        signature: result.signatures![i],
      );
      print(
        "  ├── verify ${result.domains[i]} → $ok "
        "(sig_len=${result.signatures![i].length})",
      );
    }
    print("  ├── pubkey_fp=${result.pubkeyFingerprint}");
    return result;
  });

  print("════════════════════════════════════════════════════════════");
  print("   POST-QUANTUM (R6 Identity / Hybrid / Decentralized)");
  print("════════════════════════════════════════════════════════════");

  await _runPqTest("IdentityBased (vk namespace)", () async {
    final session = IdentityBasedPqdga.labEstablish(campaignId: 'toy-campaign');
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("HybridSharedSecret (combiner)", () async {
    final session = HybridSharedSecretPqdga.labEstablish(
      campaignId: 'toy-campaign',
    );
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("Decentralized (base32 DNS + abstract)", () async {
    final session = DecentralizedPqdga.labEstablish(campaignId: 'toy-campaign');
    final dns = await PQDGAGenerator(
      PQDGAConfig(algorithm: session.algorithm),
    ).generateDomains(DateTime.utc(2024, 6, 15), 2);
    final abs = await PQDGAGenerator(
      PQDGAConfig(algorithm: session.asAbstractConfig),
    ).generateDomains(DateTime.utc(2024, 6, 15), 2);
    print("  ├── abstract ids: ${abs.domains}");
    return dns;
  });

  print("════════════════════════════════════════════════════════════");
  print("   R8 RESEARCH GENERICS + PQ EXTRAS");
  print("════════════════════════════════════════════════════════════");

  await _runTest("Markov (lexical LM)", () async {
    return await DGAGenerator(
      DGAConfig(algorithm: const MarkovDGA()),
    ).generateDomains(DateTime.utc(2024, 6, 15), 5);
  });

  await _runTest("Idn / punycode", () async {
    return await DGAGenerator(
      DGAConfig(algorithm: const IdnDGA(baseWord: 'paypal')),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runTest("Oracle-seeded", () async {
    return await DGAGenerator(
      DGAConfig(
        algorithm: OracleSeedDGA(
          oracleMaterial: Uint8List.fromList(
            List<int>.generate(32, (i) => i + 1),
          ),
          oracleId: 'lab-btc-tip',
        ),
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("EnvelopeRendezvous (decoy + KEM-DEM)", () async {
    final session = EnvelopeRendezvousPqdga.labEstablish();
    return await PQDGAGenerator(
      PQDGAConfig(algorithm: session.algorithm),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("RateLimited (cap 2/hour)", () async {
    return await PQDGAGenerator(
      PQDGAConfig(algorithm: const RateLimitedPqdga(maxNamesPerHour: 2)),
    ).generateDomains(DateTime.utc(2024, 6, 15), 10);
  });

  await _runPqTest("MultiRecipient (wrap compartmentation)", () async {
    final session = MultiRecipientPqdga.labEstablish(additionalRecipients: 2);
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  print("════════════════════════════════════════════════════════════");
  print("   R9 BINDING RESEARCH LADDER");
  print("════════════════════════════════════════════════════════════");

  await _runPqTest("R9a KmacSharedSecret", () async {
    final session = KmacSharedSecretPqdga.labEstablish(
      campaignId: 'toy-campaign',
    );
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("R9b HybridKmac", () async {
    final session = HybridKmacPqdga.labEstablish(campaignId: 'toy-campaign');
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("R9c Ratcheting (epoch 0)", () async {
    final session = RatchetingPqdga.labEstablish(epochIndex: 0);
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.asEpochOnlyConfig,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("R9d Hierarchical (region-a/team-1)", () async {
    final session = HierarchicalPqdga.labEstablish();
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.asLeafOnlyConfig,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("R9e MultiParty (2 parties)", () async {
    final session = MultiPartyPqdga.labEstablish(partyCount: 2);
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("R9f Threshold (2-of-3)", () async {
    final session = ThresholdPqdga.labEstablish(threshold: 2, totalShares: 3);
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.algorithm,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 3);
  });

  await _runPqTest("R9g AuthenticatedContext (auth-only)", () async {
    final session = AuthenticatedContextPqdga.labEstablish();
    return await PQDGAGenerator(
      PQDGAConfig(
        algorithm: session.asAuthOnlyConfig,
        minDomainLength: 8,
        maxDomainLength: 12,
      ),
    ).generateDomains(DateTime.utc(2024, 6, 15), 2);
  });
}

// Helper to format classical test output
Future<void> _runTest(String name, Future<DGAResult> Function() testFn) async {
  try {
    print("[$name] Generating...");
    final result = await testFn();
    for (var d in result.domains) {
      final feat = SocFeatures.forDomain(d);
      print(
        "  ├── $d  "
        "(len=${feat.labelLength} ent=${feat.entropy.toStringAsFixed(2)} "
        "dig=${feat.digitRatio.toStringAsFixed(2)} tld=${feat.tld})",
      );
    }
    final batch = SocFeatures.fromDgaResult(result);
    final hard = HardnessScorecard.fromDgaResult(result);
    print(
      "  ├── predictability=${result.metadata['predictability']} "
      "predictable=${result.metadata['predictable']} "
      "batch_count=${batch.domainCount} tld_div=${batch.tldDiversity}",
    );
    print("  ├── ${hard.summaryLine}");
    print("  ├── IOC: ${SocFeatures.iocTemplateFromDga(result)}");
    if (result.metadata['soc_lesson'] != null) {
      print("  └── lesson: ${result.metadata['soc_lesson']}");
    } else if (result.metadata.isNotEmpty) {
      print("  └── Meta keys: ${result.metadata.keys.join(', ')}");
    }
    print("");
  } catch (e) {
    print("  ❌ FAILED: $e\n");
  }
}

Future<void> _runPqTest(
  String name,
  Future<PQDGAResult> Function() testFn,
) async {
  try {
    print("[$name] Generating...");
    final result = await testFn();
    for (var d in result.domains) {
      final feat = SocFeatures.forDomain(d);
      print(
        "  ├── $d  "
        "(len=${feat.labelLength} ent=${feat.entropy.toStringAsFixed(2)} "
        "dig=${feat.digitRatio.toStringAsFixed(2)} tld=${feat.tld})",
      );
    }
    final batch = SocFeatures.fromPqdgaResult(result);
    print(
      "  ├── predictable=${result.predictable} "
      "secretBound=${result.secretBound} xof=${result.xof} "
      "predictability=${batch.predictability}",
    );
    print("  ├── epoch=${result.epoch}");
    if (result.kemAlgorithm != null) {
      print(
        "  ├── kem=${result.kemAlgorithm} "
        "ct_len=${result.kemCiphertextLength}",
      );
    }
    if (result.sigAlgorithm != null) {
      print(
        "  ├── sig=${result.sigAlgorithm} "
        "sig_len=${result.signatureLength} "
        "fp=${result.pubkeyFingerprint}",
      );
    }
    print(
      "  ├── batch: count=${batch.domainCount} "
      "tld_div=${batch.tldDiversity} "
      "mean_ent=${batch.meanEntropy.toStringAsFixed(2)}",
    );
    final hard = HardnessScorecard.fromPqdgaResult(result);
    print("  ├── ${hard.summaryLine}");
    print("  └── IOC: ${SocFeatures.iocTemplateFromPqdga(result)}");
    print("  └── lesson: ${result.metadata['soc_lesson']}");
    print("");
  } catch (e) {
    print("  ❌ FAILED: $e\n");
  }
}
