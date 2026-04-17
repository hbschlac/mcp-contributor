# Changelog

All notable changes to this skill are documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/). This skill's synthesis is versioned; MCP itself has its own revision cadence (see SKILL.md §11.6).

## [Unreleased]

## [0.2.0] — 2026-04-16

### Added
- `LICENSE` (Apache 2.0) with explicit note on CC-BY 4.0 provenance of synthesized content.
- `CONTRIBUTING.md` — how to report drift, hallucinations, add coverage.
- `SECURITY.md` — private vuln reporting flow.
- `CHANGELOG.md` (this file).
- `.github/ISSUE_TEMPLATE/` — bug, drift, hallucination, feature templates.
- `.github/pull_request_template.md`.
- `.github/workflows/weekly-refresh.yml` — GitHub Actions running `refresh.sh` weekly so downstream users get drift detection without needing local launchd.
- Shields.io badges on README.

### Changed
- **Skill frontmatter de-personalized.** `description` and user-facing text no longer reference the original author by name. Skill now reads as general-purpose infrastructure.
- Repo now has a description, topic tags, and GitHub Releases with notes (not just git tags).

## [0.1.1] — 2026-04-16

### Changed (dry-run findings)
- **§1.4**: Added SDK-local breaking-change rule. Dry-run on [modelcontextprotocol/php-sdk#263](https://github.com/modelcontextprotocol/php-sdk/issues/263) surfaced that the skill gave contradictory advice for issues labeled both `good first issue` and `breaking change`.
- **§2**: Replaced author-specific prereq snapshot with generic per-SDK toolchain table covering Node, Python, Go, Rust, Java, Kotlin, C#, Swift, Ruby, PHP.
- **§4 + §8.2**: Softened per-language Discord channel names; only `#general-sdk-dev` is verified. Others may exist but require verification.
- **§6.6**: Stripped unverified review specifics (vote counts, named reviewers, specific merge dates) from the SEP-2133 worked example. Points readers to [PR #2133](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2133) for current facts instead of caching them.
- **§7**: Replaced single-repo `gh issue list --repo modelcontextprotocol/modelcontextprotocol` with org-wide `gh search issues org:modelcontextprotocol` as the default, with per-repo examples retained.

### Added
- Local launchd plist (not in repo) firing `./refresh.sh --quiet` Sundays 22:05 local.

## [0.1.0] — 2026-04-16

### Added
- Initial public release.
- `SKILL.md` — 11-section contributor guide covering: triage, prereqs, fork/PR workflow, MDX + Mintlify docs authoring, SDK workflow, full SEP lifecycle, governance model (Contributor Ladder + WG/IG), communication etiquette, roadmap-aligned priorities, licensing / antitrust / trademark, protocol primer, and reference appendix distilled from 28 MCP doc pages.
- `sources.yml` — coverage map of 89 MCP URLs across 5 status tiers.
- `refresh.sh` — SHA-256 drift detector + new-page detector + gap-high counter + sources.yml linter + anchor-validation against SKILL.md.
- `README.md` — install, trigger phrases, refresh workflow.
