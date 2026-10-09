/// Literature notes + re-key status for classical DGA families.
///
/// Primary open corpus: Johannes Bader
/// (`baderj/domain_generation_algorithms`). Lab-only — no live malware samples.
library;

/// One family's literature pin and re-key fidelity status.
class LiteratureNote {
  final String familyId;
  final String displayName;
  final String tier; // P0 | P1 | P2 | baseline | research
  final String fidelity; // literature-perfect | research-model | pedagogical
  final String source;
  final String prng;
  final String seedModel;
  final String notes;
  final List<String> knownSeeds;
  final List<String> checklist;

  const LiteratureNote({
    required this.familyId,
    required this.displayName,
    required this.tier,
    required this.fidelity,
    required this.source,
    required this.prng,
    required this.seedModel,
    required this.notes,
    this.knownSeeds = const [],
    this.checklist = const [],
  });

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'display_name': displayName,
    'tier': tier,
    'fidelity': fidelity,
    'source': source,
    'prng': prng,
    'seed_model': seedModel,
    'notes': notes,
    'known_seeds': knownSeeds,
    'checklist': checklist,
  };
}

/// Catalog of classical family literature pins (P1/P2 re-key table).
class LiteratureCorpus {
  LiteratureCorpus._();

  static const notes = <LiteratureNote>[
    LiteratureNote(
      familyId: 'ramnit',
      displayName: 'Ramnit',
      tier: 'P1',
      fidelity: 'literature-perfect',
      source: 'baderj/ramnit (Park–Miller LCG; known seed 0x16647BB4)',
      prng: 'park_miller_lcg',
      seedModel: 'config-hex-dword',
      notes:
          'Labels a–y (mod 25); TLD rotation click/com/eu/bid; reseed folds '
          'first×second seed. Goldens pin baderj get_domains.',
      knownSeeds: ['16647bb4', '5f5e0a4b'],
      checklist: [
        'Park–Miller step + reseed fold',
        'charset a–y only',
        'TLD rotation order',
      ],
    ),
    LiteratureNote(
      familyId: 'nymaim',
      displayName: 'Nymaim',
      tier: 'P1',
      fidelity: 'literature-perfect',
      source: 'baderj/nymaim (date PRNG REVA/IHOL/YUH /MAV )',
      prng: 'nymaim_4word',
      seedModel: 'date-calendar',
      notes:
          'ISO weekday % 7 + year/month/day mix; TLD from last-but-one letter. '
          'Goldens pin 2015-05-14 and 2024-01-01 streams.',
      checklist: [
        'isoweekday % 7 seed mix',
        'TLD letter ranges',
        'length 6–12',
      ],
    ),
    LiteratureNote(
      familyId: 'shiotob',
      displayName: 'Shiotob/Urlzone',
      tier: 'P1',
      fidelity: 'literature-perfect',
      source: 'baderj/shiotob (seed-domain mutation; date-independent)',
      prng: 'shiotob_domain_mutate',
      seedModel: 'seed-domain',
      notes:
          'Pure domain walk from seed FQDN; alternates .com/.net. Seed domain '
          'is the extract IOC. Goldens pin 4ypv1eehphg3a.com stream.',
      knownSeeds: ['4ypv1eehphg3a.com'],
      checklist: ['date independence', 'odd-index .net swap', 'charset 0-9a-z'],
    ),
    LiteratureNote(
      familyId: 'pykspa',
      displayName: 'Pykspa (precursor)',
      tier: 'P1',
      fidelity: 'literature-perfect',
      source: 'baderj/pykspa/precursor (2-day unix bucket LCG)',
      prng: 'pykspa_precursor_lcg',
      seedModel: 'unix-2day-bucket',
      notes:
          'Improved Pykspa needs MD6 fixtures (not bundled). Precursor is the '
          'pinned literature path. Seed = unix//(2*86400).',
      checklist: ['2-day unix bucket', 'mixed TLD table', 'length 6–12'],
    ),
    LiteratureNote(
      familyId: 'vawtrak',
      displayName: 'Vawtrak',
      tier: 'P1',
      fidelity: 'literature-perfect',
      source: 'baderj/vawtrak (glibc LCG → .top)',
      prng: 'glibc_lcg_31bit',
      seedModel: 'config-dword',
      notes:
          'Config seed (not pure date). Goldens pin seed 0xDEADBEEF. '
          'campaignId/tier are notebook metadata only.',
      knownSeeds: ['deadbeef'],
      checklist: ['31-bit mask after step', '.top TLD', 'length 5–10'],
    ),
    LiteratureNote(
      familyId: 'emotet',
      displayName: 'Emotet (volume model)',
      tier: 'P1',
      fidelity: 'research-model',
      source: 'no single baderj pin; Geodo-era volume/TLD lesson',
      prng: 'lcg',
      seedModel: 'config+date',
      notes:
          'Pedagogical high-volume multi-TLD model — not bit-exact Emotet. '
          'SOC lesson: volume + TLD diversity overwhelm pure blocklists.',
      checklist: [
        'broad TLD set',
        'high domains_per_day',
        'document non-bit-exact status',
      ],
    ),
    LiteratureNote(
      familyId: 'kraken',
      displayName: 'Kraken',
      tier: 'P2',
      fidelity: 'literature-perfect',
      source: 'baderj/kraken v2 (seed sets a/b; tld_set 1/2)',
      prng: 'kraken_lcg',
      seedModel: 'date-discards+seed-set',
      notes:
          'get_domains emits temp_file 0 then 1 (nex then ex label paths). '
          'Goldens pin seed_set a, tld_set 1 on 2015-05-14.',
      checklist: [
        'discard weeks formula',
        'seed set a/b constants',
        'tld_set 1 vs 2',
      ],
    ),
    LiteratureNote(
      familyId: 'torpig',
      displayName: 'Torpig (window model)',
      tier: 'P2',
      fidelity: 'research-model',
      source: 'time-window seed rotation pedagogy (no baderj module)',
      prng: 'lcg',
      seedModel: 'window-days',
      notes:
          'Models weekly (windowDays=7) seed rotation lesson — not a single '
          'bit-exact Torpig pin. Same domain stream inside a window.',
      checklist: [
        'windowDays rotation',
        'stable within window',
        'document research-model',
      ],
    ),
    LiteratureNote(
      familyId: 'corebot',
      displayName: 'Corebot',
      tier: 'P2',
      fidelity: 'literature-perfect',
      source: 'baderj/corebot (NR LCG + .ddns.net)',
      prng: 'nr_lcg',
      seedModel: 'date+nr_b+init',
      notes:
          'Charset a–y + 0–8; length 12–23; suffix .ddns.net. Goldens pin '
          'seed=0, nr_b=8 on 2015-05-14.',
      checklist: [
        'NR LCG constants',
        'charset without z/9',
        '.ddns.net suffix',
      ],
    ),
    LiteratureNote(
      familyId: 'dircrypt',
      displayName: 'DirCrypt',
      tier: 'P2',
      fidelity: 'literature-perfect',
      source: 'baderj/dircrypt (Park–Miller → .com)',
      prng: 'park_miller_lcg',
      seedModel: 'config-hex-dword',
      notes:
          'Goldens pin seed 0x8EB35B15. Length 8–20; a–z labels; fixed .com.',
      knownSeeds: ['8eb35b15'],
      checklist: ['Park–Miller shared with Ramnit', 'length 8–20', '.com only'],
    ),
    LiteratureNote(
      familyId: 'proslikefan',
      displayName: 'Proslikefan',
      tier: 'P2',
      fidelity: 'literature-perfect',
      source: 'baderj/proslikefan (Java string hash / c_int)',
      prng: 'java_string_hash',
      seedModel: 'magic+date+tld',
      notes:
          'Magic prospect/OK; while-condition re-evaluates r%7+6 as r mutates. '
          'Goldens pin prospect on 2015-05-14.',
      knownSeeds: ['prospect', 'OK'],
      checklist: [
        'c_int wrap each hash step',
        'mutating length condition',
        'TLD wave order',
      ],
    ),
  ];

  static LiteratureNote? find(String familyOrAlgorithm) {
    final key = familyOrAlgorithm.toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    for (final n in notes) {
      final id = n.familyId.replaceAll(RegExp(r'[^a-z]'), '');
      final name = n.displayName.toLowerCase().replaceAll(
        RegExp(r'[^a-z]'),
        '',
      );
      if (key == id || key == name || key.contains(id) || id.contains(key)) {
        return n;
      }
    }
    return null;
  }

  static List<String> rekeyChecklist(String familyId) {
    final n = find(familyId);
    return n?.checklist ?? const [];
  }

  static Map<String, dynamic> summaryTable() => {
    'kind': 'literature_corpus',
    'source_primary': 'https://github.com/baderj/domain_generation_algorithms',
    'families': [for (final n in notes) n.toJson()],
    'literature_perfect_count': notes
        .where((n) => n.fidelity == 'literature-perfect')
        .length,
    'research_model_count': notes
        .where((n) => n.fidelity == 'research-model')
        .length,
  };
}
