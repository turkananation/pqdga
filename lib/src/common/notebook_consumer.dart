import 'dart:convert';

import 'package:pqdga/src/classical/dga_result.dart';
import 'package:pqdga/src/classical/corpus/literature_notes.dart';
import 'package:pqdga/src/common/binding_analysis.dart';
import 'package:pqdga/src/common/detector_notebook.dart';
import 'package:pqdga/src/common/hardness_scorecard.dart';
import 'package:pqdga/src/common/lab_harness.dart';
import 'package:pqdga/src/post_quantum/lab/post_rendezvous_session.dart';
import 'package:pqdga/src/post_quantum/pqdga_result.dart';

/// End-to-end **notebook / detector consumer** of lab surfaces.
///
/// Wires [DetectorNotebook], [HardnessScorecard], SLH size IOC catalog,
/// [LiteratureCorpus], and optional [BindingAnalysis] into a single JSON-ready
/// report for external notebooks and SOC lab tooling.
class NotebookConsumer {
  NotebookConsumer._();

  /// Full classical detector pack + literature note + pipeline rows.
  static Map<String, dynamic> consumeDga(DGAResult result) {
    final notebook = DetectorNotebook.fromDga(result);
    final hard = HardnessScorecard.fromDgaResult(result);
    final lit = LiteratureCorpus.find(result.algorithm);
    final pipeline = LabHarness.codecPipelineBulk(result.domains);
    LabHarness.logDgaResult(result);
    return {
      'consumer': 'NotebookConsumer.consumeDga',
      'notebook': notebook,
      'hardness_scorecard': hard.toJson(),
      'hardness_line': hard.summaryLine,
      'literature': lit?.toJson(),
      'rekey_checklist': lit != null
          ? LiteratureCorpus.rekeyChecklist(lit.familyId)
          : null,
      'codec_pipeline_rows': LabHarness.safeJsonDomainRows(pipeline),
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Full PQ detector pack + optional post-rendezvous + SLH catalog hook.
  static Map<String, dynamic> consumePqdga(
    PQDGAResult result, {
    PostRendezvousSession? postRendezvous,
    int? lastPacketLength,
    bool includeSlhCatalog = false,
  }) {
    final notebook = postRendezvous != null
        ? DetectorNotebook.withPostRendezvous(
            result,
            postRendezvous,
            lastPacketLength: lastPacketLength,
          )
        : DetectorNotebook.fromPqdga(result);
    final hard = HardnessScorecard.fromPqdgaResult(result);
    final pipeline = LabHarness.codecPipelineBulk(result.domains);
    LabHarness.logPqdgaResult(result);
    return {
      'consumer': 'NotebookConsumer.consumePqdga',
      'notebook': notebook,
      'hardness_scorecard': hard.toJson(),
      'hardness_line': hard.summaryLine,
      'codec_pipeline_rows': LabHarness.safeJsonDomainRows(pipeline),
      if (includeSlhCatalog || result.algorithm.toLowerCase().contains('slh'))
        'slh_dsa_size_iocs': DetectorNotebook.slhDsaSizeIocs(),
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Standalone SLH size IOC catalog consumer (multi-KB signature drill).
  static Map<String, dynamic> consumeSlhSizeCatalog() {
    final catalog = DetectorNotebook.slhDsaSizeIocs();
    LabHarness.logEvent(
      'slh_size_catalog',
      fields: {
        'sets': (catalog['parameter_sets'] as List?)?.length ?? 0,
        'crypto_status': catalog['crypto_status'],
      },
    );
    return {
      'consumer': 'NotebookConsumer.consumeSlhSizeCatalog',
      'catalog': catalog,
      'hardness_legend': DetectorNotebook.hardnessLegend(),
      'soc_lesson':
          'SLH-DSA signatures are multi-KB IOCs vs ML-DSA; sinkhole IP still '
          'fails if bots require a valid epoch seal.',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Run binding-ladder analysis suite and package as notebook report.
  static Future<Map<String, dynamic>> consumeBindingAnalysis() async {
    final suite = await BindingAnalysis.runAll();
    final writeups = BindingAnalysis.writeups();
    LabHarness.logEvent(
      'binding_analysis_suite',
      fields: {'experiments': (suite['experiments'] as Map?)?.keys.toList()},
    );
    return {
      'consumer': 'NotebookConsumer.consumeBindingAnalysis',
      'suite': suite,
      'writeups': writeups,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Combined lab briefing: classical + PQ + SLH catalog + optional analysis.
  static Future<Map<String, dynamic>> labBriefing({
    DGAResult? dga,
    PQDGAResult? pqdga,
    PostRendezvousSession? postRendezvous,
    bool runBindingAnalysis = false,
    bool includeSlhCatalog = true,
  }) async {
    final out = <String, dynamic>{
      'consumer': 'NotebookConsumer.labBriefing',
      'hardness_legend': DetectorNotebook.hardnessLegend(),
    };
    if (dga != null) out['classical'] = consumeDga(dga);
    if (pqdga != null) {
      out['post_quantum'] = consumePqdga(
        pqdga,
        postRendezvous: postRendezvous,
        includeSlhCatalog: includeSlhCatalog,
      );
    }
    if (includeSlhCatalog) {
      out['slh_dsa_size_iocs'] = consumeSlhSizeCatalog();
    }
    if (runBindingAnalysis) {
      out['binding_analysis'] = await consumeBindingAnalysis();
    }
    out['generated_at'] = DateTime.now().toUtc().toIso8601String();
    return out;
  }

  /// Pretty JSON for notebook cells.
  static String toPrettyJson(Map<String, dynamic> report) =>
      const JsonEncoder.withIndent('  ').convert(report);
}
