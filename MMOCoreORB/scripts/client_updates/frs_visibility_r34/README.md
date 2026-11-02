# R34 FRS visibility source patch

This bundle records a small fix to the local Pre-CU client content builder. R33 accidentally included active Force Ranking trees in its retired-tree visibility filter. R34 preserves the exact stock flags for all 27 FRS rows and leaves the retired sensitive, discipline and title trees hidden.

Commit only these text files: `builder-r33-to-r34.patch`, `test_frs_visibility.py`, `bundle-hashes.json`, this README, and optionally `documentation-after-publish.patch`. Do not commit the staged TRE, stock IFF donors, extracted assets, or copied build directory.

## Apply and test

Use the existing R33 `pre9-jedi` content workspace with its legally available local Pre-CU `stock_skills.iff` donor and installed `~/.claude/skills/swgemu-developer/scripts/swgtool.py`. The full builder also requires the existing schematic/STF/species donors and previously prepared custom asset source directories; this bundle does not redistribute them. It is not a standalone client asset build.

From that content workspace, set `BUNDLE` to this bundle's absolute directory:

```sh
patch --dry-run --forward -p1 < "$BUNDLE/builder-r33-to-r34.patch"
patch --forward -p1 < "$BUNDLE/builder-r33-to-r34.patch"
cp "$BUNDLE/test_frs_visibility.py" ./test_frs_visibility.py
python3 -B test_frs_visibility.py
```

The current local builder already contains the fix; do not apply it twice. Two regressions execute the actual builder visibility block against the full stock table. Both failed before the fix and pass afterward. The packed builder additionally checks every full FRS row against stock.

Run the existing `build_tre.py` in a copied staging workspace, then run `swgtool.py tre-verify` on the candidate. Compare archive names and decompressed payloads against R33: all 35 paths must remain; only `datatables/skill/skills.iff` may change. Its 1,156 rows and all non-visibility cells must remain identical. Expected delta: 53 flags across 27 FRS rows. The root retains GOD_ONLY=1, IS_HIDDEN=0; the 26 branch rows restore 0/0. Jedi-state requirements remain 4/8.

The staged full build passed these checks. Candidate SHA256: `5627e6145cd25b7d97290ad1bc8c2755c803d189c55ddd015c3524a11a0e072d`. `bundle-hashes.json` records source and archive pins. Its R33 source hash is an explicit reconstruction by reversing this task's exact edits; no independent pre-edit whole-file hash was captured. Applying the patch to that reconstruction was tested and produced byte-identical current source.

## Publication

Follow the local `pre9-jedi/PUBLISHING.md` runbook for matching server and launcher activation. Retain client priority 38 and maxSearchPriority 40. Players must exit the game, sync through the launcher, and relaunch. No council membership, rank, XP, or Jedi-state change is required.

`documentation-after-publish.patch` records the accompanying player guide, release notes, internal ledger, and client-handout updates. Apply it only with matching R34 server and launcher activation: these documents are served directly from disk, so its LIVE entry must not be published early.

R34 was published on Ninja Fun and Dev through the launcher on 2026-11-01. Both galaxies reached READY; all 9,759 supported factory-catalog entries matched the accepted build, and existing account, character and structure metadata was preserved. The live launcher API and its actual configuration/obsolete-file code passed targeted checks, including an unchanged second pass. In-game rendering remains a player check after updating and relaunching.
