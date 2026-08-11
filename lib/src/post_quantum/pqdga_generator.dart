import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pqforge/pqforge.dart';
import 'package:pqdga/src/common/predictability.dart';
import 'package:pqdga/src/post_quantum/algorithms/decentralized_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/envelope_rendezvous_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/hybrid_shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/identity_based_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/multi_recipient_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/quantum_resistant_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/rate_limited_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/signature_authenticated_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/kmac_shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/hybrid_kmac_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/ratcheting_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/hierarchical_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/multi_party_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/threshold_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/authenticated_context_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/lexical_shared_secret_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/slh_dsa_checkpoint_pqdga.dart';
import 'package:pqdga/src/post_quantum/algorithms/hybrid_authenticated_pqdga.dart';
import 'package:pqdga/src/post_quantum/crypto/dns_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/epoch_bucket.dart';
import 'package:pqdga/src/post_quantum/crypto/kmac256.dart';
import 'package:pqdga/src/post_quantum/crypto/lexical_label_codec.dart';
import 'package:pqdga/src/post_quantum/crypto/shake_xof.dart';
import 'package:pqdga/src/post_quantum/pqdga_config.dart';
import 'package:pqdga/src/post_quantum/pqdga_core.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// Handler signature for PQ family generators (registry dispatch).
///
/// May be sync or async (e.g. hybrid Ed25519 signing).
typedef PQDGAHandler = FutureOr<PQDGAResult> Function(
  DateTime date,
  int count,
  PQDGAAlgorithm algorithm,
  PQDGAConfig config,
);

/// Post-quantum DGA generator — registry dispatch + shared SHAKE pipeline.
///
/// Implemented: core PQ + extras + R9 cryptographic binding research ladder.
class PQDGAGenerator {
  final PQDGAConfig config;

  /// Type → handler registry (extend when adding families; no central if-ladder).
  static final Map<Type, PQDGAHandler> registry = {
    QuantumResistantPqdga: (date, count, algo, cfg) =>
        _generateQuantumResistant(date, count, algo as QuantumResistantPqdga, cfg),
    SharedSecretPqdga: (date, count, algo, cfg) =>
        _generateSharedSecret(date, count, algo as SharedSecretPqdga, cfg),
    SignatureAuthenticatedPqdga: (date, count, algo, cfg) =>
        _generateSignatureAuthenticated(
          date,
          count,
          algo as SignatureAuthenticatedPqdga,
          cfg,
        ),
    IdentityBasedPqdga: (date, count, algo, cfg) =>
        _generateIdentityBased(date, count, algo as IdentityBasedPqdga, cfg),
    HybridSharedSecretPqdga: (date, count, algo, cfg) =>
        _generateHybridSharedSecret(
          date,
          count,
          algo as HybridSharedSecretPqdga,
          cfg,
        ),
    DecentralizedPqdga: (date, count, algo, cfg) =>
        _generateDecentralized(date, count, algo as DecentralizedPqdga, cfg),
    EnvelopeRendezvousPqdga: (date, count, algo, cfg) =>
        _generateEnvelopeRendezvous(
          date,
          count,
          algo as EnvelopeRendezvousPqdga,
          cfg,
        ),
    RateLimitedPqdga: (date, count, algo, cfg) =>
        _generateRateLimited(date, count, algo as RateLimitedPqdga, cfg),
    MultiRecipientPqdga: (date, count, algo, cfg) =>
        _generateMultiRecipient(date, count, algo as MultiRecipientPqdga, cfg),
    // R9 binding research ladder
    KmacSharedSecretPqdga: (date, count, algo, cfg) =>
        _generateKmacSharedSecret(
          date,
          count,
          algo as KmacSharedSecretPqdga,
          cfg,
        ),
    HybridKmacPqdga: (date, count, algo, cfg) =>
        _generateHybridKmac(date, count, algo as HybridKmacPqdga, cfg),
    RatchetingPqdga: (date, count, algo, cfg) =>
        _generateRatcheting(date, count, algo as RatchetingPqdga, cfg),
    HierarchicalPqdga: (date, count, algo, cfg) =>
        _generateHierarchical(date, count, algo as HierarchicalPqdga, cfg),
    MultiPartyPqdga: (date, count, algo, cfg) =>
        _generateMultiParty(date, count, algo as MultiPartyPqdga, cfg),
    ThresholdPqdga: (date, count, algo, cfg) =>
        _generateThreshold(date, count, algo as ThresholdPqdga, cfg),
    AuthenticatedContextPqdga: (date, count, algo, cfg) =>
        _generateAuthenticatedContext(
          date,
          count,
          algo as AuthenticatedContextPqdga,
          cfg,
        ),
    // Post-R9 deferred extras
    LexicalSharedSecretPqdga: (date, count, algo, cfg) =>
        _generateLexicalSharedSecret(
          date,
          count,
          algo as LexicalSharedSecretPqdga,
          cfg,
        ),
    SlhDsaCheckpointPqdga: (date, count, algo, cfg) =>
        _generateSlhDsaCheckpoint(
          date,
          count,
          algo as SlhDsaCheckpointPqdga,
          cfg,
        ),
    HybridAuthenticatedPqdga: (date, count, algo, cfg) =>
        _generateHybridAuthenticated(
          date,
          count,
          algo as HybridAuthenticatedPqdga,
          cfg,
        ),
  };

  PQDGAGenerator(this.config);

  /// Generate [count] domains for [date] using [config.algorithm].
  Future<PQDGAResult> generateDomains(DateTime date, int count) async {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must be >= 0');
    }
    final algo = config.algorithm;
    final handler = registry[algo.runtimeType];
    if (handler == null) {
      throw UnimplementedError(
        'PQ algorithm not registered: ${algo.runtimeType}',
      );
    }
    return await handler(date, count, algo, config);
  }

  // ---------------------------------------------------------------------------
  // R3: QuantumResistant — SHAKE over public (or optional secret) seed material
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateQuantumResistant(
    DateTime date,
    int count,
    QuantumResistantPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('QuantumResistantPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('QuantumResistantPqdga.tld must be non-empty');
    }
    if (!algo.seedPublic &&
        (algo.secretMaterial == null || algo.secretMaterial!.isEmpty)) {
      throw ArgumentError(
        'secretMaterial required when seedPublic is false '
        '(lab secret-bound mode)',
      );
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];

    for (var i = 0; i < count; i++) {
      final material = _buildSeedMaterial(
        domainSeparator: algo.domainSeparator,
        secret: algo.seedPublic ? null : algo.secretMaterial,
        epoch: epoch,
        campaignId: algo.campaignId,
        counter: i,
      );
      // length byte + max label + tld index byte
      final need = 1 + maxLen + 1;
      final stream = xofName == 'SHAKE128'
          ? ShakeXof.shake128(material, need)
          : ShakeXof.shake256(material, need);

      final span = maxLen - minLen + 1;
      final length = minLen + (stream[0] % span);
      final labelBytes = Uint8List.sublistView(stream, 1, 1 + length);
      final label =
          DnsLabelCodec.mapBytesToCharset(labelBytes, algo.charset, length);

      final labelCheck = DnsLabelCodec.validateLabel(label);
      if (labelCheck.isFailure) {
        throw StateError(
          'generated invalid DNS label "$label": ${labelCheck.errorOrNull}',
        );
      }

      final tld =
          DnsLabelCodec.normalizeTld(algo.tld[stream[1 + length] % algo.tld.length]);
      final fqdn = '$label$tld';
      final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
      if (fqdnCheck.isFailure) {
        throw StateError(
          'generated invalid FQDN "$fqdn": ${fqdnCheck.errorOrNull}',
        );
      }

      domains.add(fqdnCheck.valueOrNull!);
      lengths.add(length);
    }

    final predictable = algo.seedPublic;
    final secretBound = !algo.seedPublic;
    final predictability = secretBound
        ? PredictabilityClass.secretSeeded
        : PredictabilityClass.trivial;

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'QuantumResistant',
      seed: 'epoch=$epoch,campaign=${algo.campaignId},public=${algo.seedPublic}',
      predictable: predictable,
      secretBound: secretBound,
      epoch: epoch,
      xof: xofName,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || [secret] || epoch || campaign || counter_be32',
        'seed_public': algo.seedPublic,
        'predictability': predictability.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'soc_lesson': 'PQ hash ≠ secret — public-seed SHAKE remains precomputable',
        'playbook_flags': {
          'sinkhole_precompute': predictable,
          'needs_secret_extraction': secretBound,
        },
        'ioc_template': {
          'xof': xofName,
          'label_charset': algo.charset,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R4: SharedSecret — ML-KEM ss → SHAKE → labels (main hardness jump)
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateSharedSecret(
    DateTime date,
    int count,
    SharedSecretPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('SharedSecretPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('SharedSecretPqdga.tld must be non-empty');
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }

    final resolved = _resolveSharedSecret(algo);
    final ss = resolved.sharedSecret;
    final ct = resolved.kemCiphertext;
    final resolvePath = resolved.resolvePath;

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: ss,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);

        final span = maxLen - minLen + 1;
        final length = minLen + (stream[0] % span);
        final labelBytes = Uint8List.sublistView(stream, 1, 1 + length);
        final label =
            DnsLabelCodec.mapBytesToCharset(labelBytes, algo.charset, length);

        final labelCheck = DnsLabelCodec.validateLabel(label);
        if (labelCheck.isFailure) {
          throw StateError(
            'generated invalid DNS label "$label": ${labelCheck.errorOrNull}',
          );
        }

        final tld = DnsLabelCodec.normalizeTld(
          algo.tld[stream[1 + length] % algo.tld.length],
        );
        final fqdn = '$label$tld';
        final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
        if (fqdnCheck.isFailure) {
          throw StateError(
            'generated invalid FQDN "$fqdn": ${fqdnCheck.errorOrNull}',
          );
        }

        domains.add(fqdnCheck.valueOrNull!);
        lengths.add(length);
      }
    } catch (_) {
      // Fail-closed: never return a partial domain list on error.
      domains.clear();
      rethrow;
    }

    final ctLen = ct?.length ?? algo.kemAlgorithm.ciphertextBytes;

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'SharedSecret',
      // Non-secret explainability only — never embed ss hex.
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},kem=${algo.kemAlgorithm.name},'
          'ss_bound=true,resolve=$resolvePath',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: xofName,
      kemAlgorithm: algo.kemAlgorithm.name,
      kemCiphertextLength: ctLen,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || ss || epoch || campaign || counter_be32',
        'seed_public': false,
        'predictability': PredictabilityClass.secretSeeded.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'seed_rotation_days': config.seedRotationDays,
        'ss_resolve_path': resolvePath,
        'ss_length': ss.length,
        'soc_lesson':
            'Offline generation fails without ML-KEM shared secret — '
            'shift to behavior, registration telemetry, first-observe sinkhole',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'needs_behavioral_detection': true,
        },
        'ioc_template': {
          'xof': xofName,
          'kem_algorithm': algo.kemAlgorithm.name,
          'kem_algorithm_id': algo.kemAlgorithm.id,
          'kem_ciphertext_length': ctLen,
          'shared_secret_length': algo.kemAlgorithm.sharedSecretBytes,
          'label_charset': algo.charset,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R5: SignatureAuthenticated — SHAKE labels + ML-DSA detached sigs (P5)
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateSignatureAuthenticated(
    DateTime date,
    int count,
    SignatureAuthenticatedPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError(
        'SignatureAuthenticatedPqdga.charset must be non-empty',
      );
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('SignatureAuthenticatedPqdga.tld must be non-empty');
    }
    if (!algo.seedPublic &&
        (algo.secretMaterial == null || algo.secretMaterial!.isEmpty)) {
      throw ArgumentError(
        'secretMaterial required when seedPublic is false '
        '(lab secret-bound mode)',
      );
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }

    final sk = algo.signatureSecretKey;
    if (algo.requireSignature && (sk == null || sk.isEmpty)) {
      throw ArgumentError(
        'signatureSecretKey required when requireSignature is true '
        '(see SignatureAuthenticatedPqdga.labEstablish)',
      );
    }

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final signatures = <Uint8List>[];
    final forge = const PqForge();

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: algo.seedPublic ? null : algo.secretMaterial,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);

        final span = maxLen - minLen + 1;
        final length = minLen + (stream[0] % span);
        final labelBytes = Uint8List.sublistView(stream, 1, 1 + length);
        final label =
            DnsLabelCodec.mapBytesToCharset(labelBytes, algo.charset, length);

        final labelCheck = DnsLabelCodec.validateLabel(label);
        if (labelCheck.isFailure) {
          throw StateError(
            'generated invalid DNS label "$label": ${labelCheck.errorOrNull}',
          );
        }

        final tld = DnsLabelCodec.normalizeTld(
          algo.tld[stream[1 + length] % algo.tld.length],
        );
        final fqdn = '$label$tld';
        final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
        if (fqdnCheck.isFailure) {
          throw StateError(
            'generated invalid FQDN "$fqdn": ${fqdnCheck.errorOrNull}',
          );
        }

        final domain = fqdnCheck.valueOrNull!;
        domains.add(domain);
        lengths.add(length);

        if (algo.requireSignature) {
          final message = SignatureAuthenticatedPqdga.canonicalMessage(
            signatureDomainSeparator: algo.signatureDomainSeparator,
            domain: domain,
            epoch: epoch,
            campaignId: algo.campaignId,
          );
          final sig = forge.sign(
            sk!,
            message,
            algorithm: algo.signatureAlgorithm,
            context: algo.signContext,
          );
          if (sig.isEmpty) {
            throw StateError('ML-DSA sign returned empty signature');
          }
          if (sig.length != algo.signatureAlgorithm.signatureBytes) {
            throw StateError(
              'ML-DSA signature length ${sig.length} != '
              '${algo.signatureAlgorithm.signatureBytes} '
              '(${algo.signatureAlgorithm.name})',
            );
          }
          signatures.add(sig);
        }
      }
    } catch (_) {
      // Fail-closed: never return a partial domain/signature list on error.
      domains.clear();
      signatures.clear();
      rethrow;
    }

    final predictable = algo.seedPublic;
    final secretBound = !algo.seedPublic;
    final predictability = secretBound
        ? PredictabilityClass.secretSeeded
        : PredictabilityClass.trivial;
    final pk = algo.signaturePublicKey;
    final fp = pk == null || pk.isEmpty
        ? null
        : SignatureAuthenticatedPqdga.pubkeyFingerprintOf(pk);
    final sigLen = algo.requireSignature
        ? algo.signatureAlgorithm.signatureBytes
        : null;

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'SignatureAuthenticated',
      // Non-secret explainability only — never embed sk hex.
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},'
          'sig=${algo.signatureAlgorithm.name},'
          'public=${algo.seedPublic},require_sig=${algo.requireSignature}',
      predictable: predictable,
      secretBound: secretBound,
      epoch: epoch,
      xof: xofName,
      sigAlgorithm: algo.signatureAlgorithm.name,
      signatureLength: sigLen,
      signatures: algo.requireSignature ? signatures : null,
      pubkeyFingerprint: fp,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || [secret] || epoch || campaign || counter_be32',
        'sig_message_packing':
            'sig_domain_sep || domain || epoch || campaign',
        'seed_public': algo.seedPublic,
        'predictability': predictability.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'signature_domain_separator': algo.signatureDomainSeparator,
        'seed_rotation_days': config.seedRotationDays,
        'requires_signature': algo.requireSignature,
        'soc_lesson':
            'Sinkhole IP alone fails if bot requires valid ML-DSA — '
            'need key compromise, binary rewrite, or block before verify; '
            'hunt sig size + pubkey fingerprint IOCs',
        'playbook_flags': {
          'sinkhole_precompute': predictable,
          'requires_signature': algo.requireSignature,
          'needs_key_compromise': algo.requireSignature,
          'needs_secret_extraction': secretBound,
        },
        'ioc_template': {
          'xof': xofName,
          'sig_algorithm': algo.signatureAlgorithm.name,
          'sig_algorithm_id': algo.signatureAlgorithm.id,
          'signature_length': sigLen,
          'pubkey_fingerprint': fp,
          'label_charset': algo.charset,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R6.1: IdentityBased — SHAKE(vk ‖ epoch ‖ i) namespace (± optional ML-DSA)
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateIdentityBased(
    DateTime date,
    int count,
    IdentityBasedPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('IdentityBasedPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('IdentityBasedPqdga.tld must be non-empty');
    }
    final vk = algo.identityPublicKey;
    if (vk == null || vk.isEmpty) {
      throw ArgumentError(
        'identityPublicKey required '
        '(see IdentityBasedPqdga.labEstablish)',
      );
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }
    final sk = algo.signatureSecretKey;
    if (algo.requireSignature && (sk == null || sk.isEmpty)) {
      throw ArgumentError(
        'signatureSecretKey required when requireSignature is true',
      );
    }

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final signatures = <Uint8List>[];
    final forge = const PqForge();
    final fp = SignatureAuthenticatedPqdga.pubkeyFingerprintOf(vk);

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: vk,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);

        final span = maxLen - minLen + 1;
        final length = minLen + (stream[0] % span);
        final labelBytes = Uint8List.sublistView(stream, 1, 1 + length);
        final label =
            DnsLabelCodec.mapBytesToCharset(labelBytes, algo.charset, length);
        final labelCheck = DnsLabelCodec.validateLabel(label);
        if (labelCheck.isFailure) {
          throw StateError(
            'generated invalid DNS label "$label": ${labelCheck.errorOrNull}',
          );
        }
        final tld = DnsLabelCodec.normalizeTld(
          algo.tld[stream[1 + length] % algo.tld.length],
        );
        final fqdn = '$label$tld';
        final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
        if (fqdnCheck.isFailure) {
          throw StateError(
            'generated invalid FQDN "$fqdn": ${fqdnCheck.errorOrNull}',
          );
        }
        final domain = fqdnCheck.valueOrNull!;
        domains.add(domain);
        lengths.add(length);

        if (algo.requireSignature) {
          final message = SignatureAuthenticatedPqdga.canonicalMessage(
            signatureDomainSeparator: algo.signatureDomainSeparator,
            domain: domain,
            epoch: epoch,
            campaignId: algo.campaignId,
          );
          final sig = forge.sign(
            sk!,
            message,
            algorithm: algo.signatureAlgorithm,
            context: algo.signContext,
          );
          if (sig.length != algo.signatureAlgorithm.signatureBytes) {
            throw StateError(
              'ML-DSA signature length ${sig.length} != '
              '${algo.signatureAlgorithm.signatureBytes}',
            );
          }
          signatures.add(sig);
        }
      }
    } catch (_) {
      domains.clear();
      signatures.clear();
      rethrow;
    }

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'IdentityBased',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},'
          'identity=${algo.identityKind},fp=$fp,'
          'require_sig=${algo.requireSignature}',
      predictable: true,
      secretBound: false,
      epoch: epoch,
      xof: xofName,
      sigAlgorithm:
          algo.requireSignature ? algo.signatureAlgorithm.name : null,
      signatureLength: algo.requireSignature
          ? algo.signatureAlgorithm.signatureBytes
          : null,
      signatures: algo.requireSignature ? signatures : null,
      pubkeyFingerprint: fp,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || identity_pk || epoch || campaign || counter_be32',
        'seed_public': true,
        'predictability': PredictabilityClass.configSeeded.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'identity_kind': algo.identityKind,
        'identity_public_key_length': vk.length,
        'requires_signature': algo.requireSignature,
        'soc_lesson':
            'Embedded PQ vk is a config-extraction target — '
            'once recovered, names precompute like classical seeds; '
            'optional ML-DSA still gates trust (P5)',
        'playbook_flags': {
          'sinkhole_precompute': true,
          'needs_config_extract': true,
          'requires_signature': algo.requireSignature,
        },
        'ioc_template': {
          'xof': xofName,
          'identity_kind': algo.identityKind,
          'pubkey_fingerprint': fp,
          'identity_public_key_length': vk.length,
          if (algo.requireSignature) ...{
            'sig_algorithm': algo.signatureAlgorithm.name,
            'signature_length': algo.signatureAlgorithm.signatureBytes,
          },
          'label_charset': algo.charset,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R6.2: HybridSharedSecret — classical ‖ ML-KEM combiner → SHAKE
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateHybridSharedSecret(
    DateTime date,
    int count,
    HybridSharedSecretPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('HybridSharedSecretPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('HybridSharedSecretPqdga.tld must be non-empty');
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }

    final sessionKey = _resolveHybridSessionKey(algo);
    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: sessionKey,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);

        final span = maxLen - minLen + 1;
        final length = minLen + (stream[0] % span);
        final labelBytes = Uint8List.sublistView(stream, 1, 1 + length);
        final label =
            DnsLabelCodec.mapBytesToCharset(labelBytes, algo.charset, length);
        final labelCheck = DnsLabelCodec.validateLabel(label);
        if (labelCheck.isFailure) {
          throw StateError(
            'generated invalid DNS label "$label": ${labelCheck.errorOrNull}',
          );
        }
        final tld = DnsLabelCodec.normalizeTld(
          algo.tld[stream[1 + length] % algo.tld.length],
        );
        final fqdn = '$label$tld';
        final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
        if (fqdnCheck.isFailure) {
          throw StateError(
            'generated invalid FQDN "$fqdn": ${fqdnCheck.errorOrNull}',
          );
        }
        domains.add(fqdnCheck.valueOrNull!);
        lengths.add(length);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    final ctLen =
        algo.kemCiphertext?.length ?? algo.kemAlgorithm.ciphertextBytes;

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'HybridSharedSecret',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},'
          'kem=${algo.kemAlgorithm.name},classical=${algo.classicalAlgorithm},'
          'combiner=${algo.combinerProfile},hybrid_bound=true',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: xofName,
      kemAlgorithm: algo.kemAlgorithm.name,
      kemCiphertextLength: ctLen,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || hybrid_session_key || epoch || campaign || counter_be32',
        'seed_public': false,
        'predictability': PredictabilityClass.secretSeeded.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'seed_rotation_days': config.seedRotationDays,
        'classical_algorithm': algo.classicalAlgorithm,
        'combiner_profile': algo.combinerProfile,
        'combiner_info': algo.combinerInfo,
        'hybrid_session_key_length': sessionKey.length,
        'soc_lesson':
            'Hybrid classical‖ML-KEM session key — break one leg alone is '
            'insufficient; same P4 shift as SharedSecret plus hybrid IOC notes',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'needs_behavioral_detection': true,
          'hybrid_kem': true,
        },
        'ioc_template': {
          'xof': xofName,
          'kem_algorithm': algo.kemAlgorithm.name,
          'kem_algorithm_id': algo.kemAlgorithm.id,
          'kem_ciphertext_length': ctLen,
          'classical_algorithm': algo.classicalAlgorithm,
          'combiner_profile': algo.combinerProfile,
          'hybrid_session_key_length': sessionKey.length,
          'label_charset': algo.charset,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  static Uint8List _resolveHybridSessionKey(HybridSharedSecretPqdga algo) {
    final direct = algo.hybridSessionKey;
    if (direct != null && direct.isNotEmpty) {
      return Uint8List.fromList(direct);
    }
    final classical = algo.classicalSharedSecret;
    final pq = algo.postQuantumSharedSecret;
    if (classical != null &&
        classical.isNotEmpty &&
        pq != null &&
        pq.isNotEmpty) {
      final combiner = algo.combinerProfile == 'heavy'
          ? const PqForgeCombiner.heavy()
          : const PqForgeCombiner.balanced();
      return combiner.combine(
        classicalSharedSecret: classical,
        postQuantumSharedSecret: pq,
        info: Uint8List.fromList(utf8.encode(algo.combinerInfo)),
        salt: algo.combinerSalt,
      );
    }
    throw ArgumentError(
      'HybridSharedSecretPqdga requires hybridSessionKey or '
      'classicalSharedSecret+postQuantumSharedSecret '
      '(see HybridSharedSecretPqdga.labEstablish)',
    );
  }

  // ---------------------------------------------------------------------------
  // R6.3: Decentralized — content-addressed base32/hex/abstract ids
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateDecentralized(
    DateTime date,
    int count,
    DecentralizedPqdga algo,
    PQDGAConfig config,
  ) {
    final ns = algo.namespaceKey;
    if (ns == null || ns.isEmpty) {
      throw ArgumentError(
        'namespaceKey required (see DecentralizedPqdga.labEstablish)',
      );
    }
    if (algo.dnsMode && algo.tld.isEmpty) {
      throw ArgumentError('DecentralizedPqdga.tld must be non-empty in dnsMode');
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }
    final encoding = algo.encoding.toLowerCase();
    if (encoding != 'base32' && encoding != 'hex' && encoding != 'ldh') {
      throw ArgumentError(
        'unsupported encoding "${algo.encoding}"; use base32, hex, or ldh',
      );
    }

    final idBytes = algo.idByteLength.clamp(4, 32);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final fp = SignatureAuthenticatedPqdga.pubkeyFingerprintOf(ns);

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: ns,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        // id entropy + optional tld picker
        final need = idBytes + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);
        final raw = Uint8List.sublistView(stream, 0, idBytes);

        final String idBody;
        if (encoding == 'hex') {
          idBody = Base32Codec.encodeHex(raw);
        } else if (encoding == 'ldh') {
          idBody = DnsLabelCodec.mapBytesToCharset(
            raw,
            DnsLabelCodec.defaultCharset,
            idBytes,
          );
        } else {
          idBody = Base32Codec.encode(raw);
        }

        if (algo.dnsMode) {
          var label = idBody;
          if (label.length > 63) {
            label = label.substring(0, 63);
          }
          // Avoid leading/trailing hyphen edge from ldh mapping.
          if (label.startsWith('-')) {
            label = 'a${label.substring(1)}';
          }
          if (label.endsWith('-')) {
            label = '${label.substring(0, label.length - 1)}a';
          }
          final labelCheck = DnsLabelCodec.validateLabel(label);
          if (labelCheck.isFailure) {
            throw StateError(
              'generated invalid DNS label "$label": ${labelCheck.errorOrNull}',
            );
          }
          final tld = DnsLabelCodec.normalizeTld(
            algo.tld[stream[idBytes] % algo.tld.length],
          );
          final fqdn = '$label$tld';
          final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
          if (fqdnCheck.isFailure) {
            throw StateError(
              'generated invalid FQDN "$fqdn": ${fqdnCheck.errorOrNull}',
            );
          }
          domains.add(fqdnCheck.valueOrNull!);
        } else {
          // Abstract non-DNS handle for channel-agility labs.
          domains.add('pqdga:$encoding:$idBody');
        }
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Decentralized',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},'
          'encoding=$encoding,dns=${algo.dnsMode},fp=$fp',
      predictable: true,
      secretBound: false,
      epoch: epoch,
      xof: xofName,
      pubkeyFingerprint: fp,
      metadata: {
        'encoding': encoding,
        'dns_mode': algo.dnsMode,
        'id_byte_length': idBytes,
        'tld_set': algo.dnsMode
            ? algo.tld.map(DnsLabelCodec.normalizeTld).toList()
            : const <String>[],
        'seed_packing':
            'domain_sep || namespace_key || epoch || campaign || counter_be32',
        'seed_public': true,
        'predictability': PredictabilityClass.configSeeded.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'namespace_kind': algo.namespaceKind,
        'namespace_key_length': ns.length,
        'soc_lesson':
            'Content-addressed rendezvous — RPZ-only is incomplete; '
            'monitor abstract ids / alternate channels (P7) and extract vk (P2)',
        'playbook_flags': {
          'sinkhole_precompute': algo.dnsMode,
          'needs_config_extract': true,
          'needs_channel_agility_monitoring': true,
          'dns_only_insufficient': true,
        },
        'ioc_template': {
          'xof': xofName,
          'encoding': encoding,
          'dns_mode': algo.dnsMode,
          'pubkey_fingerprint': fp,
          'namespace_kind': algo.namespaceKind,
          'id_byte_length': idBytes,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PQ extra: EnvelopeRendezvous — short decoy id + KEM-DEM sealed config
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateEnvelopeRendezvous(
    DateTime date,
    int count,
    EnvelopeRendezvousPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('EnvelopeRendezvousPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('EnvelopeRendezvousPqdga.tld must be non-empty');
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }
    final shortLen = algo.shortIdLength.clamp(1, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);

    Uint8List ss;
    Uint8List? ct;
    int? envelopePayloadLen;
    String resolvePath;

    try {
      if (algo.sharedSecret != null && algo.sharedSecret!.isNotEmpty) {
        ss = Uint8List.fromList(algo.sharedSecret!);
        ct = algo.kemCiphertext == null
            ? null
            : Uint8List.fromList(algo.kemCiphertext!);
        resolvePath = 'direct';
      } else if (algo.kemPublicKey != null && algo.kemPublicKey!.isNotEmpty) {
        final forge = const PqForge();
        final enc = forge.encapsulate(
          algo.kemPublicKey!,
          algorithm: algo.kemAlgorithm,
          nonce: algo.encapsNonce,
        );
        ss = enc.sharedSecret;
        ct = enc.ciphertext;
        resolvePath = 'encapsulate';
      } else if (algo.kemSecretKey != null &&
          algo.kemSecretKey!.isNotEmpty &&
          algo.kemCiphertext != null &&
          algo.kemCiphertext!.isNotEmpty) {
        final forge = const PqForge();
        ss = forge.decapsulate(
          algo.kemSecretKey!,
          algo.kemCiphertext!,
          algorithm: algo.kemAlgorithm,
        );
        ct = Uint8List.fromList(algo.kemCiphertext!);
        resolvePath = 'decapsulate';
      } else {
        throw ArgumentError(
          'EnvelopeRendezvousPqdga requires sharedSecret, kemPublicKey, or '
          'kemSecretKey+kemCiphertext (see labEstablish)',
        );
      }

      // Seal toy config with KEM-DEM when plaintext + pk available.
      if (algo.configPlaintext != null &&
          algo.configPlaintext!.isNotEmpty &&
          algo.kemPublicKey != null &&
          algo.kemPublicKey!.isNotEmpty) {
        final envelope = const PqForge().encrypt(
          algo.kemPublicKey!,
          algo.configPlaintext!,
          metadata: {
            'pqdga_family': 'EnvelopeRendezvous',
            'campaign_id': algo.campaignId,
            'epoch': epoch,
          },
        );
        envelopePayloadLen = envelope.payload.length;
        // Prefer envelope CT as wire IOC when encrypt path used.
        ct = envelope.kemCiphertext;
      }
    } catch (_) {
      rethrow;
    }

    final domains = <String>[];
    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: ss,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = shortLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);
        final label = DnsLabelCodec.mapBytesToCharset(
          Uint8List.sublistView(stream, 0, shortLen),
          algo.charset,
          shortLen,
        );
        final tld = DnsLabelCodec.normalizeTld(
          algo.tld[stream[shortLen] % algo.tld.length],
        );
        final fqdn = '$label$tld';
        final check = DnsLabelCodec.validateFqdn(fqdn);
        if (check.isFailure) {
          throw StateError('invalid envelope decoy FQDN: ${check.errorOrNull}');
        }
        domains.add(check.valueOrNull!);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    final ctLen = ct?.length ?? algo.kemAlgorithm.ciphertextBytes;
    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'EnvelopeRendezvous',
      seed: 'epoch=$epoch;campaign=${algo.campaignId};path=$resolvePath',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: xofName,
      kemAlgorithm: algo.kemAlgorithm.name,
      kemCiphertextLength: ctLen,
      metadata: {
        'campaign_id': algo.campaignId,
        'charset': algo.charset,
        'short_id_length': shortLen,
        'resolve_path': resolvePath,
        'envelope_payload_length': envelopePayloadLen,
        'decoy_domain': true,
        'predictability': PredictabilityClass.secretSeeded.wireName,
        'soc_lesson':
            'FQDN is a decoy handle; real config is KEM-DEM envelope — '
            'hunt CT/payload sizes, not names alone',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'inspect_payload_crypto': true,
          'name_is_decoy': true,
        },
        'ioc_template': {
          'kem': algo.kemAlgorithm.name,
          'kem_ct_len': ctLen,
          'envelope_payload_len': envelopePayloadLen,
          'short_id_len': shortLen,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PQ extra: RateLimited adaptive (low-volume training)
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateRateLimited(
    DateTime date,
    int count,
    RateLimitedPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('RateLimitedPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('RateLimitedPqdga.tld must be non-empty');
    }
    if (!algo.seedPublic &&
        (algo.secretMaterial == null || algo.secretMaterial!.isEmpty)) {
      throw ArgumentError(
        'secretMaterial required when seedPublic is false',
      );
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }

    final cap = algo.effectiveCap;
    final emit = count > cap ? cap : count;
    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];

    try {
      for (var i = 0; i < emit; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: algo.seedPublic ? null : algo.secretMaterial,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);
        final span = maxLen - minLen + 1;
        final length = minLen + (stream[0] % span);
        final label = DnsLabelCodec.mapBytesToCharset(
          Uint8List.sublistView(stream, 1, 1 + length),
          algo.charset,
          length,
        );
        final tld = DnsLabelCodec.normalizeTld(
          algo.tld[stream[1 + length] % algo.tld.length],
        );
        final fqdn = '$label$tld';
        final check = DnsLabelCodec.validateFqdn(fqdn);
        if (check.isFailure) {
          throw StateError('invalid rate-limited FQDN: ${check.errorOrNull}');
        }
        domains.add(check.valueOrNull!);
        lengths.add(length);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    final secretBound = !algo.seedPublic;
    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'RateLimited',
      seed: 'epoch=$epoch;campaign=${algo.campaignId};cap=$cap',
      predictable: !secretBound,
      secretBound: secretBound,
      epoch: epoch,
      xof: xofName,
      metadata: {
        'campaign_id': algo.campaignId,
        'charset': algo.charset,
        'max_names_per_hour': algo.maxNamesPerHour,
        'adaptive_factor': algo.adaptiveFactor,
        'effective_cap': cap,
        'requested_count': count,
        'emitted_count': domains.length,
        'capped': count > cap,
        'seed_public': algo.seedPublic,
        'length_histogram': lengths,
        'predictability': secretBound
            ? PredictabilityClass.secretSeeded.wireName
            : PredictabilityClass.trivial.wireName,
        'soc_lesson':
            'Low-volume adaptive emission evades burst sinkhole racing — '
            'use longer observation windows',
        'playbook_flags': {
          'sinkhole_precompute': !secretBound,
          'needs_long_observation_window': true,
          'rate_limited': true,
        },
        'ioc_template': {
          'xof': xofName,
          'max_names_per_hour': algo.maxNamesPerHour,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PQ extra: Multi-recipient compartmentation
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateMultiRecipient(
    DateTime date,
    int count,
    MultiRecipientPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('MultiRecipientPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('MultiRecipientPqdga.tld must be non-empty');
    }
    final session = algo.sessionKey;
    if (session == null || session.isEmpty) {
      throw ArgumentError(
        'MultiRecipientPqdga.sessionKey required (see labEstablish)',
      );
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: session,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);
        final span = maxLen - minLen + 1;
        final length = minLen + (stream[0] % span);
        final label = DnsLabelCodec.mapBytesToCharset(
          Uint8List.sublistView(stream, 1, 1 + length),
          algo.charset,
          length,
        );
        final tld = DnsLabelCodec.normalizeTld(
          algo.tld[stream[1 + length] % algo.tld.length],
        );
        final fqdn = '$label$tld';
        final check = DnsLabelCodec.validateFqdn(fqdn);
        if (check.isFailure) {
          throw StateError(
            'invalid multi-recipient FQDN: ${check.errorOrNull}',
          );
        }
        domains.add(check.valueOrNull!);
        lengths.add(length);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    final ctLen = algo.primaryKemCiphertext?.length ??
        algo.kemAlgorithm.ciphertextBytes;

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'MultiRecipient',
      seed:
          'epoch=$epoch;campaign=${algo.campaignId};extra=${algo.additionalRecipientCount}',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: xofName,
      kemAlgorithm: algo.kemAlgorithm.name,
      kemCiphertextLength: ctLen,
      metadata: {
        'campaign_id': algo.campaignId,
        'charset': algo.charset,
        'additional_recipient_count': algo.additionalRecipientCount,
        'additional_wrap_entry_sizes': algo.additionalWrapEntrySizes,
        'length_histogram': lengths,
        'predictability': PredictabilityClass.secretSeeded.wireName,
        'soc_lesson':
            'Compartmented multi-recipient wraps: partial takedown does not '
            'yield session key for other bot cohorts',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'compartmentation': true,
          'partial_takedown_resilient': true,
        },
        'ioc_template': {
          'kem': algo.kemAlgorithm.name,
          'primary_kem_ct_len': ctLen,
          'additional_recipients': algo.additionalRecipientCount,
          'wrap_entry_sizes': algo.additionalWrapEntrySizes,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  /// Resolve ML-KEM ss without ever placing it into result metadata/logs.

  // ---------------------------------------------------------------------------
  // R9a: KmacSharedSecret — ML-KEM ss → KMAC256 → labels
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateKmacSharedSecret(
    DateTime date,
    int count,
    KmacSharedSecretPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('KmacSharedSecretPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('KmacSharedSecretPqdga.tld must be non-empty');
    }
    final kdf = algo.kdf.toUpperCase();
    if (kdf != 'KMAC256') {
      throw ArgumentError('unsupported kdf "${algo.kdf}"; use KMAC256');
    }

    final resolved = _resolveSharedSecret(
      SharedSecretPqdga(
        sharedSecret: algo.sharedSecret,
        kemAlgorithm: algo.kemAlgorithm,
        kemCiphertext: algo.kemCiphertext,
        kemSecretKey: algo.kemSecretKey,
        kemPublicKey: algo.kemPublicKey,
        encapsNonce: algo.encapsNonce,
      ),
    );
    final ss = resolved.sharedSecret;
    final ct = resolved.kemCiphertext;
    final resolvePath = resolved.resolvePath;

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];

    try {
      for (var i = 0; i < count; i++) {
        final ctx = _buildKmacContext(
          domainSeparator: algo.domainSeparator,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = Kmac256.macUtf8(
          key: ss,
          data: ctx,
          outputLengthBytes: need,
          customization: algo.kmacCustomization,
        );
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    final ctLen = ct?.length ?? algo.kemAlgorithm.ciphertextBytes;
    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'KmacSharedSecret',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},kem=${algo.kemAlgorithm.name},'
          'kdf=$kdf,ss_bound=true,resolve=$resolvePath',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: kdf,
      kemAlgorithm: algo.kemAlgorithm.name,
      kemCiphertextLength: ctLen,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing': 'KMAC256(key=ss, data=sep||epoch||campaign||counter, S)',
        'binding_mode': 'kmac-shared-secret',
        'kmac_customization': algo.kmacCustomization,
        'domain_separator': algo.domainSeparator,
        'soc_lesson':
            'KMAC domain-separated expand vs raw SHAKE absorb — still secret-bound',
        'binding_ladder': 'R9a',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'binding_ladder': 'R9a',
        },
        'ioc_template': {
          'kdf': kdf,
          'kem': algo.kemAlgorithm.name,
          'kem_ciphertext_length': ctLen,
          'epoch_bucket': epoch,
          'binding_ladder': 'R9a',
        },
        'resolve_path': resolvePath,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R9b: HybridKmac — classical‖PQ combiner → KMAC256 labels
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateHybridKmac(
    DateTime date,
    int count,
    HybridKmacPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('HybridKmacPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('HybridKmacPqdga.tld must be non-empty');
    }
    final kdf = algo.kdf.toUpperCase();
    if (kdf != 'KMAC256') {
      throw ArgumentError('unsupported kdf "${algo.kdf}"; use KMAC256');
    }

    final sessionKey = _resolveHybridSessionKey(
      HybridSharedSecretPqdga(
        hybridSessionKey: algo.hybridSessionKey,
        classicalSharedSecret: algo.classicalSharedSecret,
        postQuantumSharedSecret: algo.postQuantumSharedSecret,
        kemAlgorithm: algo.kemAlgorithm,
        kemCiphertext: algo.kemCiphertext,
        classicalAlgorithm: algo.classicalAlgorithm,
        combinerInfo: algo.combinerInfo,
        combinerSalt: algo.combinerSalt,
        combinerProfile: algo.combinerProfile,
      ),
    );

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];

    try {
      for (var i = 0; i < count; i++) {
        final ctx = _buildKmacContext(
          domainSeparator: algo.domainSeparator,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = Kmac256.macUtf8(
          key: sessionKey,
          data: ctx,
          outputLengthBytes: need,
          customization: algo.kmacCustomization,
        );
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    final ctLen = algo.kemCiphertext?.length ?? algo.kemAlgorithm.ciphertextBytes;
    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'HybridKmac',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},hybrid=true,'
          'classical=${algo.classicalAlgorithm},kem=${algo.kemAlgorithm.name},kdf=$kdf',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: kdf,
      kemAlgorithm: algo.kemAlgorithm.name,
      kemCiphertextLength: ctLen,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'KMAC256(key=hybrid_session, data=sep||epoch||campaign||counter, S)',
        'binding_mode': 'hybrid-kmac',
        'classical_algorithm': algo.classicalAlgorithm,
        'combiner_profile': algo.combinerProfile,
        'kmac_customization': algo.kmacCustomization,
        'domain_separator': algo.domainSeparator,
        'soc_lesson':
            'Hybrid classical+PQ session required; KMAC expands domain-separated names',
        'binding_ladder': 'R9b',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'needs_classical_and_pq_break': true,
          'binding_ladder': 'R9b',
        },
        'ioc_template': {
          'kdf': kdf,
          'kem': algo.kemAlgorithm.name,
          'classical': algo.classicalAlgorithm,
          'epoch_bucket': epoch,
          'binding_ladder': 'R9b',
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R9c: Ratcheting — chained epoch keys → labels
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateRatcheting(
    DateTime date,
    int count,
    RatchetingPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('RatchetingPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('RatchetingPqdga.tld must be non-empty');
    }
    if (algo.epochIndex < 0) {
      throw ArgumentError.value(algo.epochIndex, 'epochIndex', 'must be >= 0');
    }

    final epochKey = _resolveRatchetEpochKey(algo);
    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    // Calendar bucket still recorded for notebooks; crypto epoch is ratchet index.
    final calendarEpoch = EpochBucket.idFor(date, config.seedRotationDays);
    final epochLabel = 'ratchet-${algo.epochIndex}';
    final domains = <String>[];
    final lengths = <int>[];
    final kdf = algo.kdf.toUpperCase();

    try {
      for (var i = 0; i < count; i++) {
        final stream = _expandWithKdf(
          key: epochKey,
          domainSeparator: algo.domainSeparator,
          epoch: epochLabel,
          campaignId: algo.campaignId,
          counter: i,
          need: 1 + maxLen + 1,
          kdf: kdf,
          kmacCustomization: algo.kmacCustomization,
        );
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Ratcheting',
      seed:
          'ratchet_id=${algo.ratchetId},epoch_index=${algo.epochIndex},'
          'campaign=${algo.campaignId},kdf=$kdf,calendar=$calendarEpoch',
      predictable: false,
      secretBound: true,
      epoch: epochLabel,
      xof: kdf,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing': 'expand(epoch_key_i, sep||ratchet-i||campaign||counter)',
        'binding_mode': 'ratcheting',
        'ratchet_id': algo.ratchetId,
        'epoch_index': algo.epochIndex,
        'calendar_epoch': calendarEpoch,
        'forward_evolution_experiment': true,
        'claims_forward_secrecy': false,
        'soc_lesson':
            'Later epoch key alone should not reconstruct earlier names if prior keys deleted',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'binding_ladder': 'R9c',
        },
        'ioc_template': {
          'kdf': kdf,
          'ratchet_id': algo.ratchetId,
          'epoch_index': algo.epochIndex,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R9d: Hierarchical — path-derived leaf key → labels
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateHierarchical(
    DateTime date,
    int count,
    HierarchicalPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('HierarchicalPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('HierarchicalPqdga.tld must be non-empty');
    }
    if (algo.hierarchyPath.isEmpty) {
      throw ArgumentError('hierarchyPath must be non-empty');
    }

    final leaf = _resolveHierarchicalLeaf(algo);
    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final pathStr = algo.hierarchyPath.join('/');
    final domains = <String>[];
    final lengths = <int>[];
    final kdf = algo.kdf.toUpperCase();

    try {
      for (var i = 0; i < count; i++) {
        final stream = _expandWithKdf(
          key: leaf,
          domainSeparator: algo.domainSeparator,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
          need: 1 + maxLen + 1,
          kdf: kdf,
          kmacCustomization: algo.kmacCustomization,
          extra: utf8.encode(pathStr),
        );
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Hierarchical',
      seed:
          'hierarchy=${algo.hierarchyId},path=$pathStr,epoch=$epoch,'
          'campaign=${algo.campaignId},kdf=$kdf',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: kdf,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing': 'expand(leaf_key(path), sep||epoch||campaign||counter||path)',
        'binding_mode': 'hierarchical',
        'hierarchy_id': algo.hierarchyId,
        'hierarchy_path': List<String>.from(algo.hierarchyPath),
        'soc_lesson':
            'Leaf compartment isolation — sibling paths must not share namespaces',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'binding_ladder': 'R9d',
        },
        'ioc_template': {
          'kdf': kdf,
          'hierarchy_id': algo.hierarchyId,
          'path': pathStr,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R9e: MultiParty — all participant secrets → binding key → labels
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateMultiParty(
    DateTime date,
    int count,
    MultiPartyPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('MultiPartyPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('MultiPartyPqdga.tld must be non-empty');
    }
    if (algo.minParties < 2) {
      throw ArgumentError('minParties must be >= 2');
    }

    final binding = _resolveMultiPartyBinding(algo);
    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final kdf = algo.kdf.toUpperCase();
    final partyCount = algo.bindingKey != null && algo.bindingKey!.isNotEmpty
        ? (algo.partySecrets.isEmpty ? algo.minParties : algo.partySecrets.length)
        : algo.partySecrets.length;

    try {
      for (var i = 0; i < count; i++) {
        final stream = _expandWithKdf(
          key: binding,
          domainSeparator: algo.domainSeparator,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
          need: 1 + maxLen + 1,
          kdf: kdf,
          kmacCustomization: algo.kmacCustomization,
        );
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'MultiParty',
      seed:
          'group=${algo.groupId},parties=$partyCount,min=${algo.minParties},'
          'epoch=$epoch,campaign=${algo.campaignId},kdf=$kdf',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: kdf,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing': 'expand(combine(all_party_secrets), context)',
        'binding_mode': 'multi-party',
        'group_id': algo.groupId,
        'party_count': partyCount,
        'min_parties': algo.minParties,
        'distinct_from_multi_recipient': true,
        'soc_lesson':
            'Group-bound generation — missing any required party blocks namespace',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'needs_all_parties': true,
          'binding_ladder': 'R9e',
        },
        'ioc_template': {
          'kdf': kdf,
          'group_id': algo.groupId,
          'min_parties': algo.minParties,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R9f: Threshold — k-of-n shares → binding key → labels
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateThreshold(
    DateTime date,
    int count,
    ThresholdPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('ThresholdPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('ThresholdPqdga.tld must be non-empty');
    }
    if (algo.threshold < 1) {
      throw ArgumentError('threshold must be >= 1');
    }

    final binding = _resolveThresholdBinding(algo);
    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final kdf = algo.kdf.toUpperCase();
    final presented = algo.shares.map((s) => s.index).toList()..sort();

    try {
      for (var i = 0; i < count; i++) {
        final stream = _expandWithKdf(
          key: binding,
          domainSeparator: algo.domainSeparator,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
          need: 1 + maxLen + 1,
          kdf: kdf,
          kmacCustomization: algo.kmacCustomization,
        );
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'Threshold',
      seed:
          'group=${algo.groupId},k=${algo.threshold},n=${algo.totalShares},'
          'shares=${presented.join("+")},epoch=$epoch,campaign=${algo.campaignId}',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: kdf,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing': 'expand(combine(k_of_n_shares), context)',
        'binding_mode': 'threshold',
        'group_id': algo.groupId,
        'threshold_k': algo.threshold,
        'total_shares_n': algo.totalShares,
        'presented_share_indices': presented,
        'distinct_from_multi_recipient': true,
        'lab_not_production_tss': true,
        'soc_lesson':
            'k-of-n participation — below threshold generation fails; ops cost rises with k',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'needs_threshold_quorum': true,
          'binding_ladder': 'R9f',
        },
        'ioc_template': {
          'kdf': kdf,
          'group_id': algo.groupId,
          'threshold_k': algo.threshold,
          'total_n': algo.totalShares,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R9g: AuthenticatedContext — sign context → derive from sig (± secret)
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateAuthenticatedContext(
    DateTime date,
    int count,
    AuthenticatedContextPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('AuthenticatedContextPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('AuthenticatedContextPqdga.tld must be non-empty');
    }
    final sk = algo.signatureSecretKey;
    if (algo.requireSignature && (sk == null || sk.isEmpty)) {
      throw ArgumentError(
        'signatureSecretKey required when requireSignature is true '
        '(see AuthenticatedContextPqdga.labEstablish)',
      );
    }

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final signatures = <Uint8List>[];
    final kdf = algo.kdf.toUpperCase();
    final secretBound = algo.secretBound;
    final forge = const PqForge();
    final pk = algo.signaturePublicKey;
    final fp = pk == null || pk.isEmpty
        ? null
        : SignatureAuthenticatedPqdga.pubkeyFingerprintOf(pk);

    try {
      for (var i = 0; i < count; i++) {
        final context = _buildKmacContext(
          domainSeparator: algo.domainSeparator,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        late final Uint8List sig;
        if (algo.requireSignature) {
          sig = forge.sign(
            sk!,
            context,
            algorithm: algo.signatureAlgorithm,
            context: algo.signContext,
          );
          if (pk != null && pk.isNotEmpty) {
            final ok = forge.verify(
              pk,
              context,
              sig,
              algorithm: algo.signatureAlgorithm,
              context: algo.signContext,
            );
            if (!ok) {
              throw StateError('context signature failed self-verify');
            }
          }
          signatures.add(sig);
        } else {
          sig = Uint8List(0);
        }

        final need = 1 + maxLen + 1;
        late final Uint8List stream;
        if (secretBound) {
          // Confidentiality + authenticity: keyed expand over context||sig.
          final data = Uint8List.fromList([...context, 0x00, ...sig]);
          if (kdf == 'KMAC256') {
            stream = Kmac256.macUtf8(
              key: algo.secretMaterial!,
              data: data,
              outputLengthBytes: need,
              customization: algo.kmacCustomization,
            );
          } else if (kdf == 'SHAKE256' || kdf == 'SHAKE128') {
            final material = Uint8List.fromList([
              ...algo.secretMaterial!,
              0x00,
              ...data,
            ]);
            stream = kdf == 'SHAKE128'
                ? ShakeXof.shake128(material, need)
                : ShakeXof.shake256(material, need);
          } else {
            throw ArgumentError(
              'unsupported kdf "$kdf"; use KMAC256, SHAKE256, or SHAKE128',
            );
          }
        } else {
          // Authenticity-only: derive from signature bytes (not secret).
          final material = Uint8List.fromList([
            ...utf8.encode(algo.domainSeparator),
            0x00,
            ...sig,
            0x00,
            ...context,
          ]);
          if (kdf == 'KMAC256') {
            // Key = first 32 bytes of sig (or padded) — still not a secret.
            final key = Uint8List(32);
            final n = sig.length < 32 ? sig.length : 32;
            key.setRange(0, n, sig);
            stream = Kmac256.macUtf8(
              key: key,
              data: context,
              outputLengthBytes: need,
              customization: algo.kmacCustomization,
            );
          } else if (kdf == 'SHAKE256') {
            stream = ShakeXof.shake256(material, need);
          } else if (kdf == 'SHAKE128') {
            stream = ShakeXof.shake128(material, need);
          } else {
            throw ArgumentError(
              'unsupported kdf "$kdf"; use KMAC256, SHAKE256, or SHAKE128',
            );
          }
        }

        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      signatures.clear();
      rethrow;
    }

    final sigLen = signatures.isEmpty ? null : signatures.first.length;
    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'AuthenticatedContext',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},'
          'sig=${algo.signatureAlgorithm.name},kdf=$kdf,'
          'auth=true,secret_bound=$secretBound',
      predictable: !secretBound,
      secretBound: secretBound,
      epoch: epoch,
      xof: kdf,
      sigAlgorithm: algo.signatureAlgorithm.name,
      signatureLength: sigLen ?? algo.signatureAlgorithm.signatureBytes,
      signatures: signatures.isEmpty ? null : signatures,
      pubkeyFingerprint: fp,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing': secretBound
            ? 'expand(secret, context||ml-dsa-sig)'
            : 'expand(ml-dsa-sig||context) — authenticity without confidentiality',
        'binding_mode': 'authenticated-context',
        'authenticity': true,
        'confidentiality': secretBound,
        'domain_separator': algo.domainSeparator,
        'requires_signature': algo.requireSignature,
        'soc_lesson':
            'Authenticity ≠ secrecy — ML-DSA authenticates context; secret optional',
        'playbook_flags': {
          'sinkhole_precompute': !secretBound,
          'needs_secret_extraction': secretBound,
          'needs_signature_verify': algo.requireSignature,
          'binding_ladder': 'R9g',
        },
        'ioc_template': {
          'kdf': kdf,
          'sig_algorithm': algo.signatureAlgorithm.name,
          'signature_length': sigLen,
          'pubkey_fingerprint': fp,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Post-R9: LexicalSharedSecret — ML-KEM ss → SHAKE/KMAC → lexical labels
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateLexicalSharedSecret(
    DateTime date,
    int count,
    LexicalSharedSecretPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.tld.isEmpty) {
      throw ArgumentError('LexicalSharedSecretPqdga.tld must be non-empty');
    }
    final mode = algo.lexicalMode.toLowerCase();
    if (mode != 'markov' &&
        mode != 'dictionary' &&
        mode != 'pronounceable' &&
        mode != 'charset') {
      throw ArgumentError(
        'unsupported lexicalMode "$mode"; use markov, dictionary, '
        'pronounceable, or charset',
      );
    }
    if (mode == 'dictionary' && algo.wordlist.isEmpty) {
      throw ArgumentError('wordlist required for dictionary lexical mode');
    }
    if ((mode == 'markov' || mode == 'charset') && algo.charset.isEmpty) {
      throw ArgumentError('charset required for markov/charset lexical mode');
    }

    final resolved = _resolveLexicalSharedSecret(algo);
    final ss = resolved.sharedSecret;
    final ct = resolved.kemCiphertext;
    final resolvePath = resolved.resolvePath;

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final kdf = algo.kdf.toUpperCase();

    try {
      for (var i = 0; i < count; i++) {
        // Extra entropy for lexical walks (bigrams / multi-word concat).
        final need = 64 + maxLen;
        late final Uint8List stream;
        if (kdf == 'KMAC256') {
          final ctx = _buildKmacContext(
            domainSeparator: algo.domainSeparator,
            epoch: epoch,
            campaignId: algo.campaignId,
            counter: i,
          );
          stream = Kmac256.macUtf8(
            key: ss,
            data: ctx,
            outputLengthBytes: need,
            customization: algo.kmacCustomization,
          );
        } else if (kdf == 'SHAKE256' || kdf == 'SHAKE128') {
          final material = _buildSeedMaterial(
            domainSeparator: algo.domainSeparator,
            secret: ss,
            epoch: epoch,
            campaignId: algo.campaignId,
            counter: i,
          );
          stream = kdf == 'SHAKE128'
              ? ShakeXof.shake128(material, need)
              : ShakeXof.shake256(material, need);
        } else {
          throw ArgumentError(
            'unsupported kdf "$kdf"; use KMAC256, SHAKE256, or SHAKE128',
          );
        }

        final pair = LexicalLabelCodec.encodeFqdn(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          mode: mode,
          tlds: algo.tld,
          charset: algo.charset,
          wordlist: algo.wordlist,
        );
        domains.add(pair.$1);
        lengths.add(pair.$2);
      }
    } catch (_) {
      domains.clear();
      rethrow;
    }

    final ctLen = ct?.length ?? algo.kemAlgorithm.ciphertextBytes;

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'LexicalSharedSecret',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},kem=${algo.kemAlgorithm.name},'
          'lexical=$mode,kdf=$kdf,ss_bound=true,resolve=$resolvePath',
      predictable: false,
      secretBound: true,
      epoch: epoch,
      xof: kdf,
      kemAlgorithm: algo.kemAlgorithm.name,
      kemCiphertextLength: ctLen,
      metadata: {
        'charset': algo.charset,
        'lexical_mode': mode,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || ss || epoch || campaign || counter → lexical codec',
        'seed_public': false,
        'predictability': PredictabilityClass.secretSeeded.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'seed_rotation_days': config.seedRotationDays,
        'ss_resolve_path': resolvePath,
        'ss_length': ss.length,
        'binding_mode': 'lexical-shared-secret',
        'needs_lexical_model': true,
        'soc_lesson':
            'Secret-bound labels can still look English-ish — pair behavior '
            'detection with lexical/LM models (H5), not entropy alone',
        'playbook_flags': {
          'sinkhole_precompute': false,
          'needs_secret_extraction': true,
          'needs_behavioral_detection': true,
          'needs_lexical_model': true,
        },
        'ioc_template': {
          'kdf': kdf,
          'lexical_mode': mode,
          'kem_algorithm': algo.kemAlgorithm.name,
          'kem_algorithm_id': algo.kemAlgorithm.id,
          'kem_ciphertext_length': ctLen,
          'shared_secret_length': algo.kemAlgorithm.sharedSecretBytes,
          'epoch_bucket': epoch,
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Post-R9: SlhDsaCheckpoint — SHAKE labels + real FIPS 205 SLH-DSA (pqcrypto)
  // ---------------------------------------------------------------------------
  static PQDGAResult _generateSlhDsaCheckpoint(
    DateTime date,
    int count,
    SlhDsaCheckpointPqdga algo,
    PQDGAConfig config,
  ) {
    if (algo.charset.isEmpty) {
      throw ArgumentError('SlhDsaCheckpointPqdga.charset must be non-empty');
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('SlhDsaCheckpointPqdga.tld must be non-empty');
    }
    if (!algo.seedPublic &&
        (algo.secretMaterial == null || algo.secretMaterial!.isEmpty)) {
      throw ArgumentError(
        'secretMaterial required when seedPublic is false '
        '(lab secret-bound mode)',
      );
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }
    final every = algo.checkpointEvery < 1 ? 1 : algo.checkpointEvery;
    final sk = algo.secretKey;
    if (algo.requireCheckpoint && (sk == null || sk.isEmpty)) {
      throw ArgumentError(
        'secretKey required when requireCheckpoint is true '
        '(see SlhDsaCheckpointPqdga.labEstablish — uses pqcrypto SlhDsa)',
      );
    }

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final signatures = <Uint8List>[];
    final checkpointIndices = <int>[];
    final params = algo.parameterSet.params;
    final pk = algo.publicKey;
    final fp = pk == null || pk.isEmpty
        ? null
        : SlhDsaCheckpointPqdga.pubkeyFingerprintOf(pk);
    final secretBound = !algo.seedPublic;
    final predictable = algo.seedPublic;

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: algo.seedPublic ? null : algo.secretMaterial,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        final domain = pair.$1;
        domains.add(domain);
        lengths.add(pair.$2);

        final attach = algo.requireCheckpoint && (i % every == 0);
        if (attach) {
          final message = SlhDsaCheckpointPqdga.canonicalMessage(
            signatureDomainSeparator: algo.signatureDomainSeparator,
            domain: domain,
            epoch: epoch,
            campaignId: algo.campaignId,
            counter: i,
          );
          // Real FIPS 205 signature via pqcrypto — do not reimplement SLH-DSA.
          final sig = SlhDsa.sign(
            sk!,
            message,
            params,
            context: algo.signContext ?? Uint8List(0),
            allowSlowSigning: algo.allowSlowSigning || !algo.parameterSet.isFast,
            verifyAfterSign: true,
          );
          if (sig.length != algo.parameterSet.signatureBytes) {
            throw StateError(
              'SLH-DSA signature length ${sig.length} != '
              '${algo.parameterSet.signatureBytes} (${algo.parameterSet.name})',
            );
          }
          if (pk != null && pk.isNotEmpty) {
            final ok = SlhDsa.verify(
              pk,
              message,
              sig,
              params,
              context: algo.signContext ?? Uint8List(0),
            );
            if (!ok) {
              throw StateError('SLH-DSA checkpoint failed self-verify');
            }
          }
          signatures.add(sig);
          checkpointIndices.add(i);
        }
      }
    } catch (_) {
      domains.clear();
      signatures.clear();
      rethrow;
    }

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'SlhDsaCheckpoint',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},slh=${algo.parameterSet.id},'
          'seed_public=${algo.seedPublic},checkpoints=${signatures.length}',
      predictable: predictable,
      secretBound: secretBound,
      epoch: epoch,
      xof: xofName,
      sigAlgorithm: algo.parameterSet.name,
      signatureLength: algo.parameterSet.signatureBytes,
      signatures: signatures.isEmpty ? null : signatures,
      pubkeyFingerprint: fp,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || [secret] || epoch || campaign || counter_be32',
        'seed_public': algo.seedPublic,
        'predictability': secretBound
            ? PredictabilityClass.secretSeeded.wireName
            : PredictabilityClass.trivial.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'signature_domain_separator': algo.signatureDomainSeparator,
        'seed_rotation_days': config.seedRotationDays,
        'requires_signature': algo.requireCheckpoint,
        'checkpoint_every': every,
        'checkpoint_indices': checkpointIndices,
        'checkpoint_count': signatures.length,
        'slh_dsa_crypto': 'fips-205-pqcrypto',
        'slh_dsa_id': algo.parameterSet.id,
        'slh_dsa_pk_bytes': algo.parameterSet.publicKeyBytes,
        'slh_dsa_sk_bytes': algo.parameterSet.secretKeyBytes,
        'slh_dsa_sig_bytes': algo.parameterSet.signatureBytes,
        'primitive': 'pqcrypto.SlhDsa',
        'binding_mode': 'slh-dsa-checkpoint',
        'soc_lesson':
            'Multi-KB SLH-DSA checkpoints are passive size IOCs vs ML-DSA; '
            'sinkhole IP fails if bot requires valid FIPS 205 epoch seal',
        'playbook_flags': {
          'sinkhole_precompute': predictable,
          'needs_signature_verify': algo.requireCheckpoint,
          'requires_signature': algo.requireCheckpoint,
          'slh_dsa_size_ioc': true,
        },
        'ioc_template': {
          'xof': xofName,
          'sig_algorithm': algo.parameterSet.name,
          'signature_length': algo.parameterSet.signatureBytes,
          'pubkey_fingerprint': fp,
          'slh_dsa_id': algo.parameterSet.id,
          'epoch_bucket': epoch,
          'primitive': 'pqcrypto.SlhDsa',
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Post-R9: HybridAuthenticated — ML-DSA + Ed25519 via PqForgeHybridSigner
  // ---------------------------------------------------------------------------
  static Future<PQDGAResult> _generateHybridAuthenticated(
    DateTime date,
    int count,
    HybridAuthenticatedPqdga algo,
    PQDGAConfig config,
  ) async {
    if (algo.charset.isEmpty) {
      throw ArgumentError(
        'HybridAuthenticatedPqdga.charset must be non-empty',
      );
    }
    if (algo.tld.isEmpty) {
      throw ArgumentError('HybridAuthenticatedPqdga.tld must be non-empty');
    }
    if (!algo.seedPublic &&
        (algo.secretMaterial == null || algo.secretMaterial!.isEmpty)) {
      throw ArgumentError(
        'secretMaterial required when seedPublic is false '
        '(lab secret-bound mode)',
      );
    }
    final xofName = algo.xof.toUpperCase();
    if (xofName != 'SHAKE256' && xofName != 'SHAKE128') {
      throw ArgumentError(
        'unsupported xof "${algo.xof}"; use SHAKE256 or SHAKE128',
      );
    }

    final pqcSk = algo.pqcSecretKey;
    final classicalSk = algo.classicalSecretKey;
    final classicalPk = algo.classicalPublicKey;
    if (algo.requireSignature) {
      if (pqcSk == null || pqcSk.isEmpty) {
        throw ArgumentError(
          'pqcSecretKey required when requireSignature is true '
          '(see HybridAuthenticatedPqdga.labEstablish)',
        );
      }
      if (classicalSk == null ||
          classicalSk.isEmpty ||
          classicalPk == null ||
          classicalPk.isEmpty) {
        throw ArgumentError(
          'classicalSecretKey + classicalPublicKey required when '
          'requireSignature is true (see HybridAuthenticatedPqdga.labEstablish)',
        );
      }
    }

    final minLen = config.minDomainLength.clamp(1, 63);
    final maxLen = config.maxDomainLength.clamp(minLen, 63);
    final epoch = EpochBucket.idFor(date, config.seedRotationDays);
    final domains = <String>[];
    final lengths = <int>[];
    final pqcSignatures = <Uint8List>[];
    final classicalSignatures = <Uint8List>[];
    final secretBound = !algo.seedPublic;
    final predictable = algo.seedPublic;

    final signer = PqForgeHybridSigner(
      profile: PqForgeProfile(
        name: 'pqdga-hybrid-auth',
        kem: PqKemAlgorithm.mlKem768,
        signature: algo.pqcSignatureAlgorithm,
      ),
      classicalAlgorithm: algo.classicalAlgorithm,
    );

    PqClassicalSignatureKeyPair? classicalKp;
    if (algo.requireSignature) {
      classicalKp = PqClassicalSignatureKeyPair(
        algorithm: algo.classicalAlgorithm,
        publicKey: classicalPk!,
        secretKey: classicalSk!,
      );
    }

    final pqcPk = algo.pqcPublicKey;
    final pqcFp = pqcPk == null || pqcPk.isEmpty
        ? null
        : HybridAuthenticatedPqdga.pubkeyFingerprintOf(pqcPk);
    final classicalFp = classicalPk == null || classicalPk.isEmpty
        ? null
        : HybridAuthenticatedPqdga.pubkeyFingerprintOf(classicalPk);

    try {
      for (var i = 0; i < count; i++) {
        final material = _buildSeedMaterial(
          domainSeparator: algo.domainSeparator,
          secret: algo.seedPublic ? null : algo.secretMaterial,
          epoch: epoch,
          campaignId: algo.campaignId,
          counter: i,
        );
        final need = 1 + maxLen + 1;
        final stream = xofName == 'SHAKE128'
            ? ShakeXof.shake128(material, need)
            : ShakeXof.shake256(material, need);
        final pair = _labelFromStream(
          stream: stream,
          minLen: minLen,
          maxLen: maxLen,
          charset: algo.charset,
          tlds: algo.tld,
        );
        final domain = pair.$1;
        domains.add(domain);
        lengths.add(pair.$2);

        if (algo.requireSignature) {
          final message = HybridAuthenticatedPqdga.canonicalMessage(
            signatureDomainSeparator: algo.signatureDomainSeparator,
            domain: domain,
            epoch: epoch,
            campaignId: algo.campaignId,
          );
          final hybrid = await signer.sign(
            pqcSecretKey: pqcSk!,
            classicalKeyPair: classicalKp!,
            message: message,
            context: algo.signContext,
            pqcAlgorithm: algo.pqcSignatureAlgorithm,
            policy: algo.dualPolicy,
          );
          if (hybrid.pqcSignature.length !=
              algo.pqcSignatureAlgorithm.signatureBytes) {
            throw StateError(
              'hybrid ML-DSA sig length ${hybrid.pqcSignature.length} != '
              '${algo.pqcSignatureAlgorithm.signatureBytes}',
            );
          }
          if (pqcPk != null && pqcPk.isNotEmpty) {
            final ok = await signer.verify(
              pqcPublicKey: pqcPk,
              classicalPublicKey: classicalPk!,
              message: message,
              signature: hybrid,
              context: algo.signContext,
            );
            if (!ok) {
              throw StateError('hybrid dual signature failed self-verify');
            }
          }
          pqcSignatures.add(hybrid.pqcSignature);
          classicalSignatures.add(hybrid.classicalSignature);
        }
      }
    } catch (_) {
      domains.clear();
      pqcSignatures.clear();
      classicalSignatures.clear();
      rethrow;
    }

    final classicalSigLen = algo.classicalAlgorithm.signatureBytes;
    final pqcSigLen = algo.pqcSignatureAlgorithm.signatureBytes;

    return PQDGAResult(
      domains: domains,
      generationDate: date,
      algorithm: 'HybridAuthenticated',
      seed:
          'epoch=$epoch,campaign=${algo.campaignId},'
          'pqc=${algo.pqcSignatureAlgorithm.name},'
          'classical=${algo.classicalAlgorithm.id},'
          'policy=${algo.dualPolicy.name},seed_public=${algo.seedPublic}',
      predictable: predictable,
      secretBound: secretBound,
      epoch: epoch,
      xof: xofName,
      sigAlgorithm:
          '${algo.pqcSignatureAlgorithm.name}+${algo.classicalAlgorithm.id}',
      signatureLength: pqcSigLen + classicalSigLen,
      signatures: pqcSignatures.isEmpty ? null : pqcSignatures,
      pubkeyFingerprint: pqcFp,
      metadata: {
        'charset': algo.charset,
        'length_min': minLen,
        'length_max': maxLen,
        'length_samples': lengths,
        'tld_set': algo.tld.map(DnsLabelCodec.normalizeTld).toList(),
        'seed_packing':
            'domain_sep || [secret] || epoch || campaign || counter_be32',
        'seed_public': algo.seedPublic,
        'predictability': secretBound
            ? PredictabilityClass.secretSeeded.wireName
            : PredictabilityClass.trivial.wireName,
        'campaign_id': algo.campaignId,
        'domain_separator': algo.domainSeparator,
        'signature_domain_separator': algo.signatureDomainSeparator,
        'seed_rotation_days': config.seedRotationDays,
        'requires_signature': algo.requireSignature,
        'dual_policy': algo.dualPolicy.name,
        'pqc_signature_algorithm': algo.pqcSignatureAlgorithm.name,
        'pqc_signature_length': pqcSigLen,
        'classical_signature_algorithm': algo.classicalAlgorithm.id,
        'classical_signature_length': classicalSigLen,
        'classical_pubkey_fingerprint': classicalFp,
        'classical_signatures_b64': [
          for (final s in classicalSignatures)
            base64Encode(s),
        ],
        'binding_mode': 'hybrid-authenticated',
        'primitive': 'pqforge.PqForgeHybridSigner',
        'soc_lesson':
            'Hybrid dual-sign (ML-DSA + Ed25519) raises break cost under '
            'requireBoth; IOC sizes = ML-DSA + classical; sinkhole still fails '
            'without valid dual verify',
        'playbook_flags': {
          'sinkhole_precompute': predictable,
          'needs_signature_verify': algo.requireSignature,
          'requires_signature': algo.requireSignature,
          'hybrid_config_ioc': true,
        },
        'ioc_template': {
          'xof': xofName,
          'sig_algorithm':
              '${algo.pqcSignatureAlgorithm.name}+${algo.classicalAlgorithm.id}',
          'pqc_signature_length': pqcSigLen,
          'classical_signature_length': classicalSigLen,
          'total_signature_length': pqcSigLen + classicalSigLen,
          'pubkey_fingerprint': pqcFp,
          'classical_pubkey_fingerprint': classicalFp,
          'dual_policy': algo.dualPolicy.name,
          'epoch_bucket': epoch,
          'primitive': 'pqforge.PqForgeHybridSigner',
        },
      },
    );
  }

  // ---------------------------------------------------------------------------
  // R9 shared helpers
  // ---------------------------------------------------------------------------
  static Uint8List _buildKmacContext({
    required String domainSeparator,
    required String epoch,
    required String campaignId,
    required int counter,
    List<int>? extra,
  }) {
    final parts = <int>[
      ...utf8.encode(domainSeparator),
      0x00,
      ...utf8.encode(epoch),
      0x00,
      ...utf8.encode(campaignId),
      0x00,
      ..._be32(counter),
    ];
    if (extra != null && extra.isNotEmpty) {
      parts.add(0x00);
      parts.addAll(extra);
    }
    return Uint8List.fromList(parts);
  }

  static Uint8List _expandWithKdf({
    required Uint8List key,
    required String domainSeparator,
    required String epoch,
    required String campaignId,
    required int counter,
    required int need,
    required String kdf,
    required String kmacCustomization,
    List<int>? extra,
  }) {
    final ctx = _buildKmacContext(
      domainSeparator: domainSeparator,
      epoch: epoch,
      campaignId: campaignId,
      counter: counter,
      extra: extra,
    );
    final k = kdf.toUpperCase();
    if (k == 'KMAC256') {
      return Kmac256.macUtf8(
        key: key,
        data: ctx,
        outputLengthBytes: need,
        customization: kmacCustomization,
      );
    }
    if (k == 'SHAKE256') {
      return ShakeXof.shake256(
        Uint8List.fromList([...key, 0x00, ...ctx]),
        need,
      );
    }
    if (k == 'SHAKE128') {
      return ShakeXof.shake128(
        Uint8List.fromList([...key, 0x00, ...ctx]),
        need,
      );
    }
    throw ArgumentError(
      'unsupported kdf "$kdf"; use KMAC256, SHAKE256, or SHAKE128',
    );
  }

  static (String, int) _labelFromStream({
    required Uint8List stream,
    required int minLen,
    required int maxLen,
    required String charset,
    required List<String> tlds,
  }) {
    final need = 1 + maxLen + 1;
    if (stream.length < need) {
      throw StateError(
        'expander returned ${stream.length} bytes, need $need',
      );
    }
    final span = maxLen - minLen + 1;
    final length = minLen + (stream[0] % span);
    final labelBytes = Uint8List.sublistView(stream, 1, 1 + length);
    final label =
        DnsLabelCodec.mapBytesToCharset(labelBytes, charset, length);
    final labelCheck = DnsLabelCodec.validateLabel(label);
    if (labelCheck.isFailure) {
      throw StateError(
        'generated invalid DNS label "$label": ${labelCheck.errorOrNull}',
      );
    }
    final tld = DnsLabelCodec.normalizeTld(
      tlds[stream[1 + length] % tlds.length],
    );
    final fqdn = '$label$tld';
    final fqdnCheck = DnsLabelCodec.validateFqdn(fqdn);
    if (fqdnCheck.isFailure) {
      throw StateError(
        'generated invalid FQDN "$fqdn": ${fqdnCheck.errorOrNull}',
      );
    }
    return (fqdnCheck.valueOrNull!, length);
  }

  static Uint8List _resolveRatchetEpochKey(RatchetingPqdga algo) {
    final direct = algo.epochKey;
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final root = algo.rootSecret;
    if (root == null || root.isEmpty) {
      throw ArgumentError(
        'epochKey or rootSecret required '
        '(see RatchetingPqdga.labEstablish)',
      );
    }
    return RatchetingPqdga.deriveEpochKey(
      root: root,
      epochIndex: algo.epochIndex,
      kdf: algo.kdf,
      kmacCustomization: algo.kmacCustomization,
      domainSeparator: algo.domainSeparator,
    );
  }

  static Uint8List _resolveHierarchicalLeaf(HierarchicalPqdga algo) {
    final direct = algo.leafKey;
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final root = algo.rootSecret;
    if (root == null || root.isEmpty) {
      throw ArgumentError(
        'leafKey or rootSecret+hierarchyPath required '
        '(see HierarchicalPqdga.labEstablish)',
      );
    }
    return HierarchicalPqdga.deriveLeaf(
      root: root,
      path: algo.hierarchyPath,
      kdf: algo.kdf,
      kmacCustomization: algo.kmacCustomization,
      domainSeparator: algo.domainSeparator,
    );
  }

  static Uint8List _resolveMultiPartyBinding(MultiPartyPqdga algo) {
    final direct = algo.bindingKey;
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    if (algo.partySecrets.length < algo.minParties) {
      throw ArgumentError(
        'need at least ${algo.minParties} party secrets, '
        'got ${algo.partySecrets.length}',
      );
    }
    return MultiPartyPqdga.combineSecrets(
      secrets: algo.partySecrets,
      kdf: algo.kdf,
      kmacCustomization: algo.kmacCustomization,
      domainSeparator: algo.domainSeparator,
    );
  }

  static Uint8List _resolveThresholdBinding(ThresholdPqdga algo) {
    final direct = algo.bindingKey;
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    return ThresholdPqdga.combineShares(
      shares: algo.shares,
      threshold: algo.threshold,
      kdf: algo.kdf,
      kmacCustomization: algo.kmacCustomization,
      domainSeparator: algo.domainSeparator,
    );
  }

  static _ResolvedSharedSecret _resolveSharedSecret(SharedSecretPqdga algo) {
    return _resolveKemSharedSecret(
      sharedSecret: algo.sharedSecret,
      kemAlgorithm: algo.kemAlgorithm,
      kemCiphertext: algo.kemCiphertext,
      kemSecretKey: algo.kemSecretKey,
      kemPublicKey: algo.kemPublicKey,
      encapsNonce: algo.encapsNonce,
      owner: 'SharedSecretPqdga',
    );
  }

  static _ResolvedSharedSecret _resolveLexicalSharedSecret(
    LexicalSharedSecretPqdga algo,
  ) {
    return _resolveKemSharedSecret(
      sharedSecret: algo.sharedSecret,
      kemAlgorithm: algo.kemAlgorithm,
      kemCiphertext: algo.kemCiphertext,
      kemSecretKey: algo.kemSecretKey,
      kemPublicKey: algo.kemPublicKey,
      encapsNonce: algo.encapsNonce,
      owner: 'LexicalSharedSecretPqdga',
    );
  }

  /// Shared ML-KEM ss resolve path used by secret-bound families (pqforge).
  static _ResolvedSharedSecret _resolveKemSharedSecret({
    required Uint8List? sharedSecret,
    required PqKemAlgorithm kemAlgorithm,
    required Uint8List? kemCiphertext,
    required Uint8List? kemSecretKey,
    required Uint8List? kemPublicKey,
    required Uint8List? encapsNonce,
    required String owner,
  }) {
    final direct = sharedSecret;
    if (direct != null && direct.isNotEmpty) {
      return _ResolvedSharedSecret(
        sharedSecret: Uint8List.fromList(direct),
        kemCiphertext: kemCiphertext == null
            ? null
            : Uint8List.fromList(kemCiphertext),
        resolvePath: 'direct',
      );
    }

    final forge = const PqForge();
    final sk = kemSecretKey;
    final ct = kemCiphertext;
    if (sk != null && sk.isNotEmpty && ct != null && ct.isNotEmpty) {
      final ss = forge.decapsulate(
        sk,
        ct,
        algorithm: kemAlgorithm,
      );
      if (ss.isEmpty) {
        throw StateError('ML-KEM decapsulate returned empty shared secret');
      }
      return _ResolvedSharedSecret(
        sharedSecret: ss,
        kemCiphertext: Uint8List.fromList(ct),
        resolvePath: 'decapsulate',
      );
    }

    final pk = kemPublicKey;
    if (pk != null && pk.isNotEmpty) {
      final enc = forge.encapsulate(
        pk,
        algorithm: kemAlgorithm,
        nonce: encapsNonce,
      );
      if (enc.sharedSecret.isEmpty) {
        throw StateError('ML-KEM encapsulate returned empty shared secret');
      }
      return _ResolvedSharedSecret(
        sharedSecret: enc.sharedSecret,
        kemCiphertext: enc.ciphertext,
        resolvePath: 'encapsulate',
      );
    }

    throw ArgumentError(
      '$owner requires sharedSecret, or '
      'kemSecretKey+kemCiphertext, or kemPublicKey '
      '(see $owner.labEstablish)',
    );
  }

  /// Domain-separated seed material for the shared PQ pipeline.
  static Uint8List _buildSeedMaterial({
    required String domainSeparator,
    required Uint8List? secret,
    required String epoch,
    required String campaignId,
    required int counter,
  }) {
    final parts = <int>[
      ...utf8.encode(domainSeparator),
      0x00,
      ...?secret,
      if (secret != null) 0x00,
      ...utf8.encode(epoch),
      0x00,
      ...utf8.encode(campaignId),
      0x00,
      ..._be32(counter),
    ];
    return Uint8List.fromList(parts);
  }

  static List<int> _be32(int value) {
    final v = value & 0xFFFFFFFF;
    return [
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ];
  }
}

/// Internal ss + optional CT from encaps/decaps/direct (never logged).
class _ResolvedSharedSecret {
  final Uint8List sharedSecret;
  final Uint8List? kemCiphertext;
  final String resolvePath;

  const _ResolvedSharedSecret({
    required this.sharedSecret,
    required this.kemCiphertext,
    required this.resolvePath,
  });
}
