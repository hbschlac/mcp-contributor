# Contributing to mcp-contributor

Thanks for considering a contribution. This skill is an LLM-ingestible synthesis of the Model Context Protocol governance docs, and like any synthesis it rots — help is welcome.

## What contributions are most useful

Ranked by value:

1. **Drift reports with links** — `refresh.sh` flagged a change and the skill content is now stale; open an issue with the URL + what's different.
2. **Hallucination reports** — a specific claim in `SKILL.md` doesn't match the MCP source docs. Cite the file+line in the skill and the authoritative URL.
3. **New gap-high coverage** — a page in `sources.yml` marked `gap-high`/`gap-med` that you've synthesized for the skill.
4. **Real-usage session logs** — you used the skill on an actual MCP contribution; add a one-liner to the session log at the bottom of `SKILL.md` with the SHA / PR URL / what worked or didn't.
5. **Bug fixes** to `refresh.sh` or `sources.yml` schema.

## What's out of scope

- Editorial style preferences without content impact
- Expanding the skill to cover non-MCP orgs (fork instead)
- Adding trigger phrases that aren't demonstrated to improve activation

## How to submit

1. Fork → branch → edit.
2. Run `./refresh.sh` locally and confirm it still exits clean (or that any new errors you introduce are intentional, e.g. new `gap-high` entries).
3. If you added content to `SKILL.md`, add or update the matching entry in `sources.yml` with `status: covered`, an `anchor` pointing to your §, and today's date in `fetched`.
4. Open a PR explaining what changed and why. Reference the authoritative MCP source URL.

## Keeping the synthesis honest

- **Don't hardcode names, vote counts, or dates that will rot.** Point to the source; the skill is infrastructure, not a snapshot.
- **No hallucinated trigger phrases.** Only add triggers you've observed or that map directly to an MCP term.
- **Prefer shrinking to expanding.** The skill is already large. Before adding, consider whether an existing section can absorb it.
- **Attribution:** MCP docs are CC-BY 4.0. Preserve source URLs inline (§ headers + `sources.yml`).

## Code of Conduct

Be kind. Assume good faith. Bad-faith conduct (harassment, hostility, personal attacks) will get you removed. For MCP-project-specific conduct issues, follow the [MCP Code of Conduct](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/CODE_OF_CONDUCT.md).

## License

By contributing, you agree your contribution is licensed under the Apache License 2.0 (see `LICENSE`). No CLA required.
