# Genome of the Twin Kings — prologue & five chapters

A playable vertical slice of the vision in [VISION.md](VISION.md), built with **Godot 4.4.1**. This is an illustrated 2D teaching prototype with a story ending, not the complete envisioned RPG or a research analysis pipeline.

## What is playable

- A title menu, DNA transition, opening story and six explorable 2D locations: the Dungeon of False Annotations, Sequence Forest, Alignment River, Expression Swamp, the Dungeon of Missing Data and the **Hall of Records**.
- Five puzzles with hints and feedback: compare two short sequences; classify pre-aligned substitutions, insertions and deletions; assemble overlapping reads; select an RNA-seq sample pair and calculate counts per million (CPM); and review a small pileup of aligned, quality-scored reads.
- **The Final Trial:** review the five fragments and their limits, compare the archived prison record and a reread with a reference and a public summary, revise unsupported claims, and present a defensible case at a non-combat public hearing. Princess Lyra and the villagers hear the result.
- Scripted characters including the Genome Sage, River Wisp, Kraken of Noise, Draco Variantus and Princess Lyra; a nine-entry bioinformatics codex; and a journal recording each observation's source and limitations. Encounters are dialogue and investigation, not combat.
- Five recoverable evidence fragments worth 50, 100, 150, 200 and 250 XP, plus a final case record worth 300 XP: **1,050 XP total**, counted once. Settings, reduced-motion mode, local save/continue, a Web export preset and automated tests are included.

## About the science and the story

The observations are **clues, not proof of identity or tampering**. The Forest examples are simplified and already aligned; that challenge is not a general aligner or variant caller. The River model is an exact suffix-to-prefix teaching exercise with oriented, error-free reads. It does not handle reverse complements, sequencing errors, quality, repeat disambiguation or missing coverage and is not a real genome assembler.

The Swamp assay supplies QC labels rather than calculating them and uses one control and one case. CPM here is the target count divided by total mapped reads in millions; it is only a simple library-size scaling exercise. Passing QC and sharing a batch do not guarantee a valid study; CPM does not remove batch effects or replace replication, composition-aware normalization or statistical testing. Equal CPM in one pair does not establish equal expression. The trial is not a differential-expression pipeline.

The dragon's ledger supplies the alignment and base-quality scores. Its **teaching rule** keeps bases with Q ≥ 30, calls sites with fewer than four passing reads a *no call*, and treats an alternate supported by at least two passing reads at sufficient depth as a candidate. A no-call site is not a reference match, and a candidate is not a confirmed variant or evidence of disease. Real variant interpretation also requires checks of mapping, duplicates, strand bias, sample provenance and independent validation. This deliberately small exercise is not a real variant caller.

The Final Trial brings the existing **fictional** archived prison profile together with two additional fictional records: a reread of the *same aliquot* and a public summary. The two readings differ from the reference at positions 6 and 12 while the summary claims zero differences. This is a discrepancy to investigate, not proof of either twin's identity, a particular source of error, or intent. The prior Forest, River, Swamp and dragon exercises are not presented as having come from the prison sample. A reread of the same aliquot can share source or labeling errors; it is not an independently collected sample. The fictional hearing introduces a separately authenticated office order and Varen's admission to explain the story's outcome; the short DNA profiles do not establish his role. The player is asked to preserve originals, audit custody and seek independent review.

## Play

1. Start a new game, investigate the dungeon terminal and compare the sample to its reference. Recover the evidence, then approach the gate and enter Sequence Forest.
2. Speak with the Sage, visit the sprite by the archive and classify the three samples. Approach the forest arch to enter Alignment River.
3. Ask the River Wisp about overlaps, then visit the ledger by the jetty. Select all four reads in order so each join shares **at least three bases**. Restore the skiff and approach the eastern landing.
4. In Expression Swamp, listen to the Kraken and investigate the assay on the stone table. Choose a control and a case that both pass the supplied QC check and share a batch, then choose their CPM values in control/case order. Recover the evidence and reach the marsh arch.
5. In the Dungeon of Missing Data, speak with Draco Variantus and examine the ledger. Use the displayed base-quality and depth cutoffs to classify the sites, then select the candidate's alternate base and its support among passing reads. Recover the fragment and approach the archive door.
6. In the Hall of Records, speak with Lyra and visit the evidence table. Select the defensible statements, compare the toy profiles and choose a supported conclusion and next step. Use **Open Journal** while reviewing to see the earlier sources without losing your current selections. An unsupported case is returned for revision. Once prepared, approach the lectern and address the council.

Each puzzle includes a hint. The journal preserves evidence from earlier regions. You can revisit a region when its completion screen appears; after entering the next region, traveling back is not yet implemented. In-progress case selections remain while using the journal or revising a dismissed case, but are reset if you close the table or reload before preparing the case.

| Action | Controls |
| --- | --- |
| Move | A/D or left/right arrows; hold the on-screen arrows; or click in the scene |
| Approach an object | Click its diamond marker |
| Interact nearby | E, Space, or the on-screen interact button |
| Evidence journal | J, the JOURNAL button, the pause menu, or Open Journal at the final table |
| Codex | Title screen, CODEX button, or pause menu |
| Pause / close | Escape or the in-game MENU button |

The interface is designed for desktop or a landscape screen. The Web build needs a modern browser with WebGL 2; the first download includes the Godot engine and can take a moment. The Web page shows an orientation reminder in portrait mode.

## Open and run the source

1. Install [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/) (the standard, non-.NET editor).
2. Extract this project and import its `project.godot` using the Godot Project Manager.
3. Let Godot import the assets, then press **F5** to run the project.

Alternatively, from the project directory:

```sh
godot --headless --editor --path . --quit   # Import assets and register script classes
godot --path .                              # Use your Godot executable name
```

The project uses the `gl_compatibility` renderer and has no plugin or Python runtime dependency.

## Save data and upgrades

The game writes versioned JSON under Godot's `user://` directory:

- `twin_kings_save_v6.json` — the active journey, including current region, puzzle, case and story progress.
- `twin_kings_save_v5.json`, `twin_kings_save_v4.json`, `twin_kings_save_v3.json`, `twin_kings_save_v2.json`, `twin_kings_save_v1.json` — previous builds' saves, if present; migration leaves them unchanged.
- `twin_kings_settings_v1.json` — local accessibility settings shared with previous builds.

If no V6 exists, the game migrates the newest existing prior save, provided it is valid. A completed V5 Dungeon of Missing Data journey resumes at the beginning of the Final Trial; an unfinished V5 journey stays in its region with its position and progress. A completed V4 Swamp journey begins at the Dungeon of Missing Data; a completed V3 River journey begins at Expression Swamp; a completed V2 Forest journey begins at Alignment River; a completed V1 prologue begins at Sequence Forest. Unfinished older journeys remain where they were. Existing evidence and settings are preserved.

The newest existing save always takes precedence. An unreadable V6 (or the newest earlier version when V6 is absent) is **not** silently replaced with older progress: Continue is disabled, a warning is shown, and starting a new game requires confirmation. Starting over replaces the active V6 journey; make a backup of local save files first if you may need to recover them. Older V1–V5 files are not deleted.

Progress is saved at important events, when pausing or returning to the title, and periodically during exploration. In a Web build, Godot persists `user://` in the browser's IndexedDB for **that site's origin**. An upgrade served at a different origin (including a different host or port) will not automatically find an old Web save. If an upgrade still displays the old version, hard-refresh without clearing site data. Clearing site data, private browsing, or storage restrictions can remove or prevent saves. There is no cloud account or server-side save.

## Tests

First let the Godot editor import the project (or run the first command below). Then, from the project directory:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_logic.gd
godot --headless --path . --script res://tests/test_variant_trial.gd
godot --headless --path . --script res://tests/test_assembly.gd
godot --headless --path . --script res://tests/test_expression.gd
godot --headless --path . --script res://tests/test_pileup.gd
godot --headless --path . --script res://tests/test_final_case.gd
godot --headless --path . --script res://tests/test_layout.gd
godot --headless --path . --script res://tests/test_migration.gd
godot --headless --path . --script res://tests/test_flow.gd
```

These cover comparison and grading, exact overlaps and contigs, CPM and QC/batch checks, quality and depth filtering, the final case and unsupported claims, fixed-size text budgets, invalid answers, evidence totals, V1–V5 migration, corrupt-save handling, and the six-location story flow with hints, rewards, journal, hearing and Continue. Some tests temporarily exercise local save files and restore prior bytes when they finish; back up valuable saves first.

After making a Web export, also test the **converted binary** trial resource (the generated file's directory/hash may vary). On a Unix-like system:

```sh
converted=$(find .godot/exported -name '*-missing_pileup.res' -print -quit)
godot --headless --path . --script res://tests/test_pileup_export.gd -- "$converted"
```

This catches export-time loss of the packed read/quality arrays that a source-only test would miss. `PileupSite` is an `@tool` resource so Godot 4.4's text-to-binary export conversion retains those values. A browser playtest of the exported build remains important.

## Web export

Install Godot 4.4.1 export templates and use **Project → Export → Web**. The included preset uses the single-threaded Web template and `web_shell.html`; adjust the output path to suit your machine. Serve the exported files over HTTP(S), with `.wasm` served as `application/wasm`; opening the HTML using `file://` will not work reliably. For a local test from the project directory, after exporting to `../twin-kings-preview`:

```sh
python3 tools/serve_web.py --directory ../twin-kings-preview --port 8000
# Open http://localhost:8000 in your browser.
```

The development server requests cache revalidation, so updated builds can be fetched at the same origin without changing where saves live. A standard `python3 -m http.server 8000` from the export directory also works. The supplied Web build is an export of this Godot project, not a separate browser implementation.

## Project map and extension points

- `scenes/main.tscn`, `scripts/main.gd` — entry scene, menus, prologue, shared HUD and transitions.
- `scripts/forest_region.gd`, `scripts/river_region.gd`, `scripts/swamp_region.gd`, `scripts/missing_data_region.gd`, `scripts/final_trial_region.gd` — exploration, interactions, chapter transitions and hearing.
- `scripts/forest_challenge_screen.gd`, `scripts/variant_classifier.gd` — Forest trial UI and pre-aligned classification rules.
- `scripts/assembly_challenge_screen.gd`, `scripts/read_assembly.gd` — River trial UI and exact-overlap rules.
- `scripts/expression_challenge_screen.gd`, `scripts/expression_analysis.gd` — Swamp trial UI, pair checks and CPM arithmetic.
- `scripts/pileup_challenge_screen.gd`, `scripts/pileup_analysis.gd` — dragon's ledger UI, quality/depth filtering and candidate classification.
- `scripts/final_case_screen.gd`, `scripts/case_analysis.gd` — final review and profile UI, authored claim checks and toy-profile comparison.
- `scripts/evidence_journal.gd`, `scripts/game_progress.gd` — journal and reward totals.
- `scripts/resources/`, `data/` — authored evidence, quests and puzzle resources. Current layouts support three short Forest pairs, four short River reads, four Swamp samples with three CPM choices, three short pileup sites with three support choices, and the fixed Final Trial case. Expand the interfaces before adding longer or additional examples. Add completion flags to the save schema and migration before using them.
- `scripts/sequence_puzzle.gd`, `scripts/save_data.gd` — prologue rules and versioned JSON persistence.
- `scripts/atmosphere.gd`, `scripts/dna_transition.gd` — ambient effects and transition.
- `tests/`, `assets/`, `tools/serve_web.py`, `VISION.md` — checks, prototype art, a local Web server and the original project vision.

## Not built yet / suggested next steps

The title is **2D concept art with ambient effects**, not the envisioned 3D cinematic. The prototype reaches a scripted story ending, but backtracking between completed regions, hostile encounters, combat and bosses, later regions, audio, SQLite and an embedded Python sandbox are not implemented. Guides and characters use scripted dialogue, not AI tutoring.

Further work could split the large prototype controller into dedicated scenes and input actions, deepen the hearing and its choices, and extend save migrations as the world grows. If executable coding challenges are added, design a separately isolated, resource-limited sandbox first; never run untrusted player code directly in the game process.

## Credits and notices

The background and character concept art were AI-generated for this prototype and are intended as replaceable development assets. Cinzel, Cormorant Garamond and DM Sans are included with their SIL Open Font License texts in `assets/fonts/`. Godot and bundled third-party notices are in `licenses/`; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
