---
name: mcp-contributor
description: Skill for contributing upstream to the Model Context Protocol (MCP) governance org — the spec, official SDKs, and docs at github.com/modelcontextprotocol. Triggers on any of: "contribute to MCP", "contribute upstream to MCP", "MCP spec PR", "MCP PR", "open a PR to modelcontextprotocol", "submit to modelcontextprotocol", "MCP good first issue", "find an MCP maintainer", "MCP working group", "MCP interest group", "MCP sponsor", "write an SEP", "draft an SEP", "submit an SEP", "SEP for MCP", "I want to do an SEP", "propose a change to MCP", "propose an MCP spec change", "MCP specification enhancement proposal", "change the MCP spec", "add a feature to MCP", "new MCP RPC method", "MCP schema change", "edit MCP docs", "fix MCP typo", "contribute to MCP SDK", "MCP TypeScript SDK PR", "MCP Python SDK PR", "MCP Go/Rust/Java/Kotlin/C#/Swift/Ruby/PHP SDK PR", "modelcontextprotocol org", "MCP governance contribution". Covers triage (small change vs SEP), env setup, fork/branch/PR workflow, schema changes, docs changes, full SEP lifecycle (types, statuses, prototype, sponsor, review meetings), and AI-contribution disclosure. NOT for building your own MCP servers — that's mcp-builder.
---

# MCP Contributor

End-to-end guide for contributing to the **Model Context Protocol** governance org (`github.com/modelcontextprotocol`). Covers the spec repo, all 10 official SDKs, and docs.

**Not for:** building your own MCP servers/clients. Use `mcp-builder` for that.

---

## Step 0: Announce activation

Announce: `🔧 mcp-contributor activated — [triage | spec PR | SDK PR | SEP draft]. [one-line reason]`

---

## Step 0.5: Protocol primer (read once, then you can reason about spec PRs)

Before touching schema or spec, know these. Full detail: https://modelcontextprotocol.io/docs/learn/architecture

**Three participants (client-server architecture):**
- **MCP Host** — the AI app (Claude Desktop, VS Code, Cursor…) that orchestrates one or more clients
- **MCP Client** — lives inside the host, maintains one dedicated connection per server
- **MCP Server** — program that provides context/tools to a client. Local (STDIO) usually 1 client; remote (HTTP) usually many.

**Two layers:**
- **Data layer** — JSON-RPC 2.0 protocol. Lifecycle management, capability negotiation, primitives, notifications.
- **Transport layer** — *stdio* (local, process pipes) or *Streamable HTTP* (remote, HTTP POST + optional SSE). Transport is swappable; JSON-RPC messages identical across transports.

**Server primitives** (what servers expose):
- **Tools** — executable functions the LLM can call (`tools/list`, `tools/call`)
- **Resources** — context data the LLM can read (`resources/list`, `resources/read`)
- **Prompts** — reusable interaction templates (`prompts/list`, `prompts/get`)

**Client primitives** (what clients expose back to servers):
- **Sampling** — server asks client's LLM for a completion (`sampling/complete`). Keeps servers model-independent.
- **Elicitation** — server asks user for input/confirmation (`elicitation/request`)
- **Logging** — server sends log messages to client
- **Roots** — client tells server which filesystem paths are in scope

**Cross-cutting utility primitive:**
- **Tasks (experimental, [SEP-1686](https://modelcontextprotocol.io/seps/1686-tasks))** — durable execution wrappers for deferred result retrieval

**Lifecycle (every connection):**
1. Client sends `initialize` with `protocolVersion` + `capabilities` + `clientInfo`
2. Server responds with its `protocolVersion` + `capabilities` + `serverInfo`. Incompatible versions → terminate.
3. Client sends `notifications/initialized`
4. Normal request/response flow begins
5. Either side may send notifications (no `id`, no response expected) — e.g. `notifications/tools/list_changed` when server's tool set changes. Only sent if capability declared `"listChanged": true`.

**Versioning:** current spec rev is **`2025-11-25`** (source: https://modelcontextprotocol.io/specification/2025-11-25). Protocol version strings are date-based (`YYYY-MM-DD`).

**What MCP is NOT:** MCP defines *how context is exchanged*, not how LLMs use that context. Don't propose SEPs that reach into LLM behavior itself.

When your PR touches any of the concepts above → read the matching subpage of `/specification/<rev>/` first.

---

## Step 1: Triage the contribution type

Before any code, classify the contribution. The process diverges sharply — get this wrong and the PR gets closed or the SEP gets parked.

### 1.1 The core decision

**Rule of thumb:** if it changes the protocol spec or schema semantics → SEP (§5). If it's a bug, typo, doc, example, or SDK implementation quality improvement → direct PR (§3 or §4).

### 1.2 Small changes — Direct PR (no SEP, no pre-discussion needed)

Submit directly per §3. Appropriate for:

- **Bug fixes and typo corrections** — anywhere in the org
- **Documentation improvements** — clarity fixes, broken links, incomplete examples, improving a confusing section
- **Adding examples to existing features** — JSON schema examples in `schema/draft/examples/[TypeName]/`, code samples in docs
- **Minor schema fixes that don't materially change the specification or SDK behavior** — e.g. tightening a JSDoc, fixing a cross-reference, correcting an example
- **Test improvements** — more coverage, better assertions, flakiness fixes

### 1.3 Major changes — SEP required (§5)

Anything below triggers the SEP process. Do NOT open a direct PR; it will be redirected.

- **New protocol features or API methods** — e.g. adding `tools/execute`
- **Breaking changes to existing behavior** — any backwards-incompatible change, no matter how small
- **Changes to the message format or schema structure** — e.g. restructuring request/response envelopes, renaming fields
- **New interoperability standards** — anything meant to be adopted across clients/servers
- **Governance or process changes** — altering decision-making, contribution guidelines, or the SEP process itself
- **Complex or controversial topics** — changes with multiple valid designs or likely to generate debate

**Concrete examples that require SEP:**
- Adding a new RPC method like `tools/execute`
- Changing how authentication and authorization work
- Adding a new capability negotiation field
- Modifying the transport layer specification

### 1.4 SDK-specific PRs — including "breaking" labels

Bug fixes in an SDK go through §4 (open issue first, then PR). If the SDK bug is actually a spec ambiguity, escalate to SEP instead.

**SDK-local breaking changes** (e.g. dropping a dep, renaming a public API, raising a language minimum version): these are breaking at the SDK level but do NOT change the MCP wire protocol. They do NOT require an SEP — stay in §4. Look at what actually changes:
- Wire-protocol change (JSON-RPC method/field/capability) → SEP
- SDK package metadata / public API surface / composer / npm / pip-only change → §4 SDK PR, even if labeled `breaking change`

If in doubt, the issue labels tell you who's authoritative: issue labeled by maintainers with both `good first issue` + `breaking change` = maintainers already decided this is a §4 PR-scale change. Trust the label.

### 1.5 Gray-zone decision tree

Ask these in order:

1. **Does this change what's on the wire between client and server?** → SEP.
2. **Does this add, rename, or remove a field, method, or capability?** → SEP.
3. **Could a conformant existing implementation break after this change?** → SEP (breaking change).
4. **Is this a new interop standard?** → SEP.
5. **Does this change how maintainers make decisions, how PRs are reviewed, or the SEP process itself?** → SEP (Process type).
6. **None of the above, and it's ≤~200 lines of clearly-scoped change?** → Direct PR.
7. **Still unsure?** → Post a one-paragraph description in [Discord](https://discord.gg/6CSzBmMkjX) `#general` or [GitHub Discussions](https://github.com/modelcontextprotocol/modelcontextprotocol/discussions) BEFORE writing code. A 3-sentence check saves a week of wasted effort.

### 1.6 Quick reference

| Signal | Type | Path |
|---|---|---|
| Typo, broken link, docs clarity | **Small** | Direct PR (§3) |
| Adding example to existing feature | **Small** | Direct PR (§3) |
| Test improvement, fix flaky test | **Small** | Direct PR (§3) |
| Minor schema fix (no behavior change) | **Small** | Direct PR (§3) |
| Bug fix in SDK | **SDK PR** | Issue first, then §4 |
| New RPC method | **Major** | SEP §5 |
| Any breaking change | **Major** | SEP §5 |
| Schema structure / message format change | **Major** | SEP §5 |
| Auth / transport layer change | **Major** | SEP §5 |
| New capability negotiation field | **Major** | SEP §5 |
| Governance / process change | **Major** | SEP §5 (Process type) |
| Not sure | Discuss first | Discord `#general` or Discussions |

---

## Step 2: Verify prerequisites

**Required for any contribution:**
- Git (any recent version)
- GitHub account with 2FA enabled (Contributor Ladder requires 2FA at Member and above)

**Required for the spec repo (`modelcontextprotocol/modelcontextprotocol`):**
- Node.js **24+**
- npm **11+**
- Verify: `node --version && npm --version && git --version`

**Required for SDK contributions — install per-language toolchain first:**

| SDK repo | Toolchain |
|---|---|
| `typescript-sdk` | Node 20+, npm or pnpm |
| `python-sdk` | Python 3.10+, uv or pip, pytest |
| `go-sdk` | Go 1.22+ |
| `java-sdk` | JDK 17+, Maven or Gradle |
| `kotlin-sdk` | JDK 17+, Gradle |
| `csharp-sdk` | .NET 8+ SDK |
| `swift-sdk` | Xcode 15+ / Swift 5.9+ |
| `rust-sdk` | Rust stable (cargo) |
| `ruby-sdk` | Ruby 3.1+, bundler |
| `php-sdk` | PHP 8.2+, composer |

**Rule:** always check the target repo's `README.md` + `CONTRIBUTING.md` for the exact version floor — this table is a starting point, not authoritative. If the repo uses a specific `.tool-versions`, `mise.toml`, or `asdf` file, follow it.

If Node gets downgraded on your machine (Homebrew keg-linking can drift), re-pin:
```bash
brew unlink node@20 && brew link --overwrite --force node@24
```

---

## Step 3: Small-change workflow (spec repo or any SDK)

The spec repo is `modelcontextprotocol/modelcontextprotocol`. SDK repos listed in §6.

```bash
# 1. Fork via GitHub UI (or gh)
gh repo fork modelcontextprotocol/modelcontextprotocol --clone=false

# 2. Clone YOUR fork
git clone https://github.com/YOUR-USERNAME/modelcontextprotocol.git
cd modelcontextprotocol

# 3. Install deps
npm install

# 4. Verify clean baseline
npm run check

# 5. Branch
git checkout -b fix/<short-description>   # or feat/<desc>, docs/<desc>

# 6. Make changes. If schema changed:
npm run generate:schema

# 7. Re-check
npm run check
npm run format   # auto-fix formatting

# 8. Commit (descriptive, reference issue #s)
git commit -m "Fix typo in tools documentation (#123)"

# 9. Push + PR
git push origin fix/<short-description>
gh pr create --fill
```

**Schema source of truth:** `schema/draft/schema.ts`. After editing, always `npm run generate:schema` (regenerates JSON schema + docs).

**Docs live preview:** `npm run serve:docs` → `http://localhost:3000` with hot reload. Validate with `npm run check:docs`.

**Schema examples:** drop JSON into `schema/draft/examples/[TypeName]/` (e.g. `Tool/my-example.json`) and reference via `@example` + `@includeCode` JSDoc tags.

---

## Step 3.5: Docs authoring — MDX + Mintlify cheat sheet

MCP docs are written in **MDX** (Markdown + JSX components) and rendered by **Mintlify**. Knowing this stack = cleaner docs PRs, zero rejected formatting.

### MDX basics (https://mdxjs.com/)

MDX = Markdown + embedded JSX. Rules:
- Standard Markdown still works (headings, lists, links, code fences, tables).
- You can drop in JSX components inline: `<Note>Body</Note>`.
- **File extension `.mdx`** — not `.md` — for files using components.
- **Indentation matters inside JSX.** Leave blank lines between Markdown blocks and JSX blocks, or Markdown inside the component may not render.
- HTML tags work but prefer Mintlify components for consistency.
- No front-matter? MDX itself is agnostic; Mintlify uses YAML front-matter for page metadata (see below).
- Escape `{` and `}` as `\{` `\}` when you need literal braces (they're JSX expressions otherwise).

### Mintlify components (https://www.mintlify.com/docs/components)

The MCP docs page uses these most:

| Component | Use for |
|---|---|
| `<Note>...</Note>` | Neutral side info, "heads up" |
| `<Tip>...</Tip>` | Best practice, optional helper |
| `<Warning>...</Warning>` | Something that can break or surprise the reader |
| `<Info>...</Info>` | Background context |
| `<Check>...</Check>` | Positive confirmation / success state |
| `<Steps>` + `<Step title="...">` | Numbered procedures (used heavily in contributing guide) |
| `<Card title="..." href="..." icon="...">` | Link tile to another page |
| `<CardGroup cols={2}>` | Grid of cards |
| `<Accordion title="...">` | Collapsible section |
| `<AccordionGroup>` | Multiple accordions together |
| `<Tabs>` + `<Tab title="...">` | Tabbed content (e.g. per-language examples) |
| `<CodeGroup>` | Multiple named code blocks side-by-side |
| `<Frame>` | Wraps + styles images/screenshots |
| `<Expandable title="...">` | Show/hide detail blob |
| `<Icon icon="..." />` | Inline icon (FontAwesome set) |

**Page front-matter (Mintlify expects at top of `.mdx`):**
```yaml
---
title: "Page Title"
description: "One-line description shown in previews and search"
icon: "book"              # optional, FontAwesome name
sidebarTitle: "Short"     # optional override for nav
---
```

**Code blocks:** use triple-backtick with language. Mintlify supports `theme={null}` (seen in the contributing guide) to disable per-block themeing; you usually don't need it.

**Links:** relative paths work — `/community/governance` resolves against the docs root. Don't hardcode the `modelcontextprotocol.io` domain.

**Navigation:** adding a new page means also updating `docs.json` (Mintlify's config) in the repo root — add the page path to the appropriate sidebar group. `npm run check:docs` will flag orphans.

### Common MDX/Mintlify gotchas

1. **Blank lines around components.** Markdown inside `<Steps>` or `<Tabs>` needs surrounding blank lines or content silently doesn't render.
2. **Component imports.** MCP docs use Mintlify's globally-registered components — don't add `import` statements. If you need a custom React component, that's an SEP-scale change.
3. **Escaping `<` in prose.** Use `&lt;` or wrap in backticks. Bare `<` starts a JSX tag.
4. **MDX ≠ GitHub README rendering.** GitHub shows `.mdx` as raw-ish; the real preview is `npm run serve:docs`.
5. **Images** go in `docs/images/` (or subfolder); reference with absolute path from docs root: `/images/foo.png`.

### Validating docs changes

```bash
npm run serve:docs     # live local preview on :3000
npm run check:docs     # link-check + formatting
npm run check          # full pre-PR validation
npm run format         # auto-fix formatting
```

---

## Step 4: SDK workflow

Each SDK repo has its own maintainers, CONTRIBUTING.md, and Discord channel. Don't assume spec-repo patterns apply.

**Before code:**
1. **Open an issue first** describing the approach. Avoids duplicate work, aligns with SDK direction.
2. Join the SDK's Discord channel. Naming isn't uniform — the verified channel for SDK coordination is `#general-sdk-dev` (§5.5.4). Per-language channels may exist (e.g. a `#<lang>-sdk-dev` pattern was observed for some SDKs) but verify in Discord before assuming one exists for your target language. If unsure, ask in `#general-sdk-dev`.
3. Read that repo's `CONTRIBUTING.md` — setup, style, commit conventions vary.
4. Write tests. Bug fix → test that reproduces. New feature → coverage for expected behavior.

Some SDKs are co-maintained with partners (Google, Microsoft, JetBrains) — process may differ slightly.

---

## Step 5: SEP (Specification Enhancement Proposal) workflow

The slow, social path — weeks to months, not hours. SEP files live in [`seps/`](https://github.com/modelcontextprotocol/modelcontextprotocol/tree/main/seps) in the spec repo; their PR history = the historical record.

### 5.1 When an SEP is required vs not

**SEP required:**
- New feature / protocol change (new RPC method, message format change, interop standard)
- Any backwards-incompatible change
- Governance or process change
- Complex/controversial topic with multiple valid solutions

**Skip the SEP (direct PR instead):**
- Bug fixes, typos
- Docs clarifications
- Examples for existing features
- Minor schema fixes that don't change behavior

### 5.2 SEP types (declare in preamble)

| Type | Purpose |
|---|---|
| **Standards Track** | New feature / implementation / interop standard |
| **Informational** | Design issue or guideline; no new feature |
| **Process** | Change to MCP process itself (like the SEP guidelines doc) |

### 5.3 Pre-draft checklist (do this BEFORE writing markdown)

1. **Validate the idea** — post in the relevant [Working/Interest Group](https://modelcontextprotocol.io/community/working-interest-groups) Discord channel (`#auth-wg`, `#server-identity-wg`, etc.). If no relevant group: post in GitHub Discussions or Discord `#general`. Cold submissions face far more friction. If the topic deserves a new WG/IG, that's often a better first step — the effort of finding co-facilitators is itself a signal.
2. **Check alignment** with the [project roadmap](https://modelcontextprotocol.io/development/roadmap) and [design principles](https://modelcontextprotocol.io/community/design-principles). Proposals that conflict with current priorities face extra friction.
3. **Build a prototype** (see §5.5 — required before acceptance).
4. **Identify candidate sponsors** from [MAINTAINERS.md](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/MAINTAINERS.md) — pick 1–2 whose area overlaps, not a broadcast tag.

### 5.4 Lifecycle + status flow

```
Idea → (PR with SEP file) → Awaiting Sponsor (up to 6mo)
                                ↓         ↓           ↓
                              Draft    Dormant    Withdrawn
                                ↓
                       (Sponsor reviews informally)
                                ↓
                             In-Review
                                ↓
                   (Core Maintainer meeting — biweekly)
                           ↓          ↓
                       Accepted    Rejected
                           ↓
                 (Reference implementation complete)
                           ↓
                         Final
```

| Status | Meaning |
|---|---|
| `draft` | Has a sponsor; informal review |
| `in-review` | Ready for formal Core Maintainer review |
| `accepted` | Approved; awaiting reference implementation |
| `rejected` | Declined by Core Maintainers |
| `withdrawn` | Author pulled it |
| `final` | Reference impl merged into spec |
| `superseded` | Replaced by newer SEP |
| `dormant` | No sponsor within 6 months — NOT rejected; revivable |

**Key rule:** the **sponsor** updates status (both the markdown `Status:` field AND the matching PR label — keep in sync). The author does NOT edit status directly — request changes through the sponsor.

### 5.5 Prototype requirement

A prototype is **mandatory before acceptance**. What counts:

- ✅ Working branch/fork in one of the official SDKs
- ✅ Standalone proof-of-concept demonstrating key mechanics
- ✅ Integration tests showing the proposed behavior
- ✅ Reference server or client implementing the feature

Must: demonstrate core functionality, show API ergonomics, surface edge cases, be runnable by reviewers (include setup instructions). Does NOT need to be production-ready.

Not sufficient: pseudocode alone, design doc with no code, "trust me."

### 5.6 SEP file structure

Filename: `0000-your-feature-title.md` initially; after PR opened, rename using the PR number (e.g. `1850-your-feature-title.md`) and update the header.

Required sections:

1. **Preamble** — title, authors + contact, status, type, PR number
2. **Abstract** — ~200 words on the technical issue
3. **Motivation** — **why the current spec is inadequate. Weak motivation = auto-reject.**
4. **Specification** — syntax + semantics, detailed enough for independent interoperable implementations
5. **Rationale** — design decisions, alternatives considered, related work, evidence of community consensus, responses to objections raised in discussion
6. **Backward Compatibility** — describe any incompatibilities, severity, migration path
7. **Reference Implementation** — required for `final`, not for `accepted`
8. **Security Implications** — explicit; don't hand-wave

Full template: https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/seps/README.md#sep-file-structure

### 5.7 Step-by-step submission

1. Draft markdown file `0000-<title>.md` following §5.6 structure.
2. Open PR adding it to `seps/`.
3. Rename file using assigned PR number; update header.
4. Tag 1–2 relevant maintainers as sponsor candidates; cross-post in relevant Discord channel.
5. If no sponsor response after 2 weeks → ask in `#general`.
6. Sponsor assigns themselves + sets status to `draft`.
7. Informal review in PR comments; iterate.
8. When ready, sponsor flips to `in-review` → goes to biweekly Core Maintainer meeting.
9. Resolution: `accepted` / `rejected` / returned for revision.
10. If accepted: complete reference implementation → sponsor flips to `final`.

### 5.8 Acceptance criteria (what Core Maintainers evaluate)

- Prototype implementation demonstrating the proposal
- Clear benefit to the MCP ecosystem
- Community support / consensus (shown via discussion history, WG engagement)

### 5.9 After rejection

Not permanent. Options:
1. Address specific concerns → resubmit
2. Ask in Discord to understand the reasoning
3. Submit a competing SEP with a different approach
4. Wait — community needs evolve

### 5.10 Maintenance after merge

- Pre-`final` bugs/updates → comment on the SEP's PR
- Post-`final` → open a new PR modifying the SEP file

### 5.11 Ownership transfer

OK to transfer if original author is unreachable or out of time (retain as co-author when possible). NOT a vehicle for "I disagree with the direction" — submit a competing SEP instead.

### 5.12 License

SEPs themselves: public domain / CC0-1.0-Universal (whichever more permissive).

---

## Step 5.5: Governance model + Working/Interest Groups

Understanding who decides what saves weeks. MCP is **Model Context Protocol a Series of LF Projects, LLC** (under Linux Foundation); governance changes must also be approved by LF Projects.

### 5.5.1 Role hierarchy (the Steering Group)

| Role | Scope | Authority |
|---|---|---|
| **Lead Maintainers (BDFL)** | Final decision authority | Can veto any Core/Maintainer decision; appoint/remove Core Maintainers; admins on all infra |
| **Core Maintainers** | Overall project direction + spec stewardship | Veto Maintainer decisions by majority vote; resolve disputes; appoint/remove Maintainers; admin access to all repos (but use PR workflow) |
| **Maintainers** | A specific area (an SDK, docs, a Working Group) | Write access to their repo(s); decide for their area, escalate when needed |
| **Contributors** | Anyone filing issues / PRs / joining discussions | That's you by default |

Outside the Steering Group (but on the [Contributor Ladder](https://modelcontextprotocol.io/community/contributor-ladder)): **Member** and **Community Moderator**. Memberships are individual, not corporate — no reserved seats by employer, no term limits.

**Current maintainers:** always read [MAINTAINERS.md](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/MAINTAINERS.md) directly — do NOT hardcode names in the skill. The roster shifts. Lead Maintainer is the BDFL/founder role; Core Maintainers are the steering group; look for an "Emeritus" section for past contributors.

### 5.5.2 How decisions get made

- **Core Maintainer meetings:** biweekly. This is where SEPs go for formal review (§5.7). Notes are public.
- **In-person:** Leads + Cores + Maintainers aim to meet every 3–6 months.
- **Small proposals:** can be decided async in the maintainers' Discord server.
- **PR workflow:** Maintainers use the same PR + review flow as external contributors — they don't push direct to main.

### 5.5.3 The Contributor Ladder (canonical: [SEP-2148](https://modelcontextprotocol.io/seps/2148-contributor-ladder))

Full role ladder with timelines, sponsorship, and inactivity rules:

| Role | Min timeline | Sponsorship | Key privileges | Inactivity → emeritus |
|---|---|---|---|---|
| **Contributor** | Immediate | None | Open issues/PRs, join discussions | — |
| **Member** | 2–3 months active | 2 Members+ from different orgs **OR** 1 Core/Lead | GitHub org membership, triage rights, `/lgtm`, eligible for WG Lead/IG Facilitator | 3 mo no contribution |
| **Maintainer** | 6+ months as Member | 1 Maintainer/Core sponsor + Core Maintainer approval | Merge rights in their area, sponsor new Maintainers, listed in `MAINTAINERS.md` | 6 mo, CM review, merge rights revoked |
| **Core Maintainer** | 6+ months as Maintainer | Majority Core nomination + Lead approval, **OR** direct Lead appointment | Final approval on breaking changes, SEP voting, admin access all repos | 6 mo, Lead review |
| **Lead Maintainer** | Succession only | Existing Leads appoint; if none remain → Core Maintainers majority within 30 days | Veto, appoint/remove Core Maintainers, act alone | Lifetime appointment; succession per §5.5.9 |
| **Community Moderator** | Parallel track; Member min | 1 Core/Lead | Moderation on Discord + Discussions, CoC enforcement | Removable by Core for cause |

**Advancement process (any rung):**
1. Nomination (self-nom OK) via issue template, with linked contributions + sponsor confirmations
2. 7-day community review window
3. Approving authority decides
4. Onboarding

**Timelines are minimums, not guarantees.** Exceptions require Core Maintainer approval with documented rationale. 2FA required at all non-Contributor levels.

**Delegation principle:** decisions made at the lowest appropriate level. Escalate only when blocked, project-wide, or required by process.

### 5.5.3a Escalation matrix (SEP-2148)

| Issue | First escalation | Second escalation | Timeline |
|---|---|---|---|
| Technical disagreement in PR | Maintainer in scope | Core Maintainer | 5 biz days |
| Technical disagreement in WG | WG Lead | Core Maintainer | 5 biz days |
| Technical disagreement in IG | IG Facilitator | Core Maintainer | 5 biz days |
| Dispute with WG Lead / IG Facilitator | Core Maintainer | Lead Maintainer | 7 biz days |
| Dispute with Maintainer decision | Core Maintainer | Lead Maintainer | 7 biz days |
| Core Maintainer disagreement | Lead Maintainer | — | 10 biz days |
| Code of Conduct violation | Community Moderator | Core Maintainer | Immediate |
| Security issue | Core Maintainer | Lead Maintainer | Immediate |

When escalating: (1) document options + points of disagreement, (2) present with clear ask, (3) authority provides binding guidance / requests info / escalates.

### 5.5.3b Contribution pathways (all lead to Maintainer)

- **Code** — SDK dev, testing infra, tooling, DX
- **Specification** — SEP authorship, spec refinement, protocol design, compatibility analysis
- **Documentation** — user guides, API docs, architecture docs
- **Community building** — onboarding, WG facilitation, community support, events
- **Quality & security** — bug triage, security review, test coverage, release validation

Moderator experience counts toward any role, especially community-judgment ones.

### 5.5.3c Stepping down + involuntary removal

- Voluntary: notify leadership → transition work → emeritus (can return w/ abbreviated re-onboarding)
- Involuntary: CoC violations or sustained non-participation, following review process

### 5.5.9 Lead Maintainer succession (from Contributor Ladder §Succession)

- Begins on written notice. If a Lead can't give notice, remaining Leads or Cores can determine they're unable to continue.
- **If Leads remain:** they appoint a successor; if >1 remain, majority vote.
- **If no Leads remain:** Cores appoint a successor by majority vote within 30 days. Until then, project runs by **2/3 Core vote**.

### 5.5.3d Key cross-reference

All WG/IG governance (tiers, decision process, lifecycle, charter template) is **canonically defined in [SEP-2149: MCP Group Governance and Charter Template](https://modelcontextprotocol.io/seps/2149-working-group-charter-template)** — Status: Final, Type: Process, Authors: David Soria Parra + Sarah Novotny. The `/community/working-interest-groups` page and `/community/charter-template` page are the rendered docs of this SEP.

**Transition rule (from SEP-2149):** existing WGs/IGs at time of SEP acceptance are grandfathered but must publish a conforming charter within **8 weeks** or be considered inactive and subject to retirement. Good signal that any WG without a visible charter at `docs/community/<name>/charter.mdx` may be on notice.

### 5.5.4 Interest Groups (IGs) vs Working Groups (WGs)

The two collaboration structures. **Pick the right one** — asking to form a WG when an IG fits is a common newcomer mistake.

| | Interest Group (IG) | Working Group (WG) |
|---|---|---|
| **Purpose** | Identify + discuss problems | Build concrete solutions |
| **Output** | Problem statements, use cases, recommendations | SEPs, implementations, code |
| **Duration** | Ongoing while topic relevant | Until deliverables done |
| **Leadership** | Facilitator(s) | Lead(s) (commit ~2–3 hrs/week) |
| **Decisions** | Rough consensus, non-binding | Binding (lazy consensus → formal vote → escalation) |
| **Example** | "Security in MCP" | "Server Identity" implementation |

**Typical flow:** problem → IG discussion → validated → form/join WG → SEP → implementation.

**Current active groups** (snapshot from [meet.modelcontextprotocol.io](https://meet.modelcontextprotocol.io) fetched 2026-04-16 — verify freshness before citing):

| Group | Type | Cadence | Discord |
|---|---|---|---|
| Registry WG | WG | Weekly | `#registry-dev` |
| Triggers & Events WG | WG | Weekly | `#triggers-events-wg` |
| Server Identity WG | WG | Weekly | `#server-identity-wg` |
| Agents WG | WG | Biweekly | `#agents-wg` |
| Inspector V2 WG | WG | Weekly | `#inspector-v2-wg` |
| MCP Apps WG | WG | Weekly | `#mcp-apps-wg` |
| Fine-Grained Auth WG | WG | Weekly | `#auth-wg-fine-grained-authz` |
| Transports WG | WG | Weekly | `#transports-wg` |
| Mixup Protection WG | WG | Weekly | `#auth-wg-mixup-protection` |
| SDKs WG | WG | Biweekly | `#sdk-wg`, `#general-sdk-dev` |
| Primitive Grouping IG | IG | Varies | `#primitive-grouping-ig` |
| Skills Over MCP IG | IG | Weekly (office hours) | `#skills-over-mcp-ig` |
| Gateways IG | IG | Weekly | `#gateways-ig` |
| Financial Services IG (FSIG) | IG | Biweekly | `#fsig` |

Charter (required for every group): template at [/community/charter-template](https://modelcontextprotocol.io/community/charter-template) — required sections include Group Type, Mission Statement, Scope (in/out/related), Leadership table, Authority & Decision Rights (WG only), Membership roster, Operations (meeting schedule), Deliverables + Success Metrics (WG), Changelog. Charter files live at `docs/community/<group-name>/charter.mdx` and get added to `docs/docs.json`.

**Typical WG meeting structure** (verified on Agents WG biweekly page):
- Hosted on Google Meet (link appears 15 min before)
- 30 min default duration
- Shared Google Doc for agenda + running notes
- Coordination in that group's Discord channel
- iCal / Google Calendar export available
- Notes posted to GitHub Discussions within 48h (§5.5.7)

### 5.5.5 Participation tiers within a group

| Tier | Role |
|---|---|
| **Observer** | Read access; can attend meetings; limited discussion |
| **Participant** | Active contributor to discussions; can propose agenda items; async votes |
| **WG Member** | Sustained contributor with demonstrated expertise; counted for quorum (WGs only) |
| **Lead / Facilitator** | Sets agenda, facilitates, escalates |

**Becoming a WG Member:** 3 months sustained participation + meaningful contributions (code, spec text, reviews, docs) + nomination by existing WG Member or Lead + no objections within 7 days. Inactivity for 3 consecutive months → emeritus (revivable).

### 5.5.6 WG decision-making (binding)

1. **Lazy consensus (default):** proposal announced with deadline (5 days minor, 10 days significant). Silence = consent. Any WG Member can block with documented objection + proposed alternatives.
2. **Formal vote (if blocked or if Lead/3+ Members request):** 50% quorum; simple majority for routine, 2/3 for scope changes. Core Maintainer feedback is advisory unless stated otherwise. Document with rationale.
3. **Escalation:** Lead presents to Core Maintainers with context. A designated CM (not from same org as parties) provides binding guidance, requests more info, or kicks to full CM deliberation. Initial response target: 5 business days.

**Direct-escalation-worthy matters** (skip local resolution): scope/authority disputes, cross-group conflicts, CoC issues, membership disputes.

### 5.5.7 Meeting requirements (same for WGs + IGs)

- Open to all — no closed/org-internal meetings
- Published ≥7 days in advance on [meet.modelcontextprotocol.io](https://meet.modelcontextprotocol.io)
- Agenda published in the [Meeting Notes GitHub Discussions category](https://github.com/modelcontextprotocol/modelcontextprotocol/discussions)
- Notes published within 48 hours to the same discussion
- Cadence is Leads' call — no fixed requirement

### 5.5.8 Forming a new group

**Working Group:**
1. Widely acknowledged concern requiring coordination
2. PR creating `docs/community/<name>/overview.mdx` (Maintainer approval via CODEOWNERS)
3. PR creating `docs/community/<name>/charter.mdx` (Core Maintainer approval via CODEOWNERS)
4. Initial member list approved by WG Lead
5. Leadership sponsored by ≥2 Core Maintainers or 1 Lead Maintainer

**Interest Group:**
1. Post in Discord `#wg-ig-group-creation` channel using the creation template
2. Secure sponsorship: ≥2 Core Maintainers or 1 Lead Maintainer
3. Facilitator(s) organize IG + author charter

Charter template: [/community/charter-template](https://modelcontextprotocol.io/community/charter-template).

### 5.5.9 Reporting cadence

- **WGs:** quarterly updates (end of Jan/Apr/Jul/Oct) posted as GitHub Discussion — deliverable progress, escalations, membership, priorities, resource needs.
- **IGs:** no formal reporting; keep charter + member list current.

### 5.5.10 Licensing, IP, and trademark (IMPORTANT — read before first PR)

MCP is under **Linux Foundation governance** — "Model Context Protocol a Series of LF Projects, LLC." That means LF Projects' policies apply on top of MCP's own rules.

**License terms for contributions:**

| What you contribute | License |
|---|---|
| Code | [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) |
| Specification | [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) |
| Documentation (non-spec) | [Creative Commons Attribution 4.0 International (CC-BY 4.0)](https://creativecommons.org/licenses/by/4.0) |
| SEP documents themselves | Public domain / CC0-1.0-Universal (whichever more permissive) |

**Key rules:**
- **No CLA / no copyright assignment.** Contributors retain copyright in their work as independent authorship. You grant the project a license, you don't hand over ownership.
- **Outbound = inbound.** All outbound code + specs ship under Apache 2.0. Exceptions only by Core Maintainer approval.
- **Governance changes must also be approved by LF Projects, LLC** — not just MCP maintainers.

**LF Projects policies that apply** (all at https://lfprojects.org/policies/):
1. **Code of Conduct** — LF default unless MCP adopts an approved alternative (MCP has its own: [CODE_OF_CONDUCT.md](https://github.com/modelcontextprotocol/.github/blob/main/CODE_OF_CONDUCT.md))
2. **Antitrust Policy** — mandatory; MCP also ships [ANTITRUST.md](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/ANTITRUST.md). Don't discuss pricing, market allocation, or competitively sensitive commercial topics in any MCP channel.
3. **Trademark Policy** — governs use of "MCP" and "Model Context Protocol" marks. Don't use the marks to imply endorsement of your product.
4. **Terms of Use** — conditions for participation in LF-hosted platforms.
5. **Privacy Policy** — how LF handles contributor data.
6. **General Rules of Operation** — baseline operational standards.
7. **Telemetry Data Collection Policy** — governs any telemetry shipped by LF-hosted tools.

Policy amendments take effect 30 days after publication (Trademark Policy + Terms of Use are immediate). Questions: `manager@lfprojects.org`. For anything that smells legal, consult your own counsel — LF doesn't provide individual legal advice.

**Practical contributor checklist:**
- [ ] Your contribution is original or properly attributed
- [ ] You're authorized to contribute it (employer's OSS policy if you work for one)
- [ ] You're not introducing GPL/AGPL/copyleft code into Apache 2.0-licensed repos
- [ ] You haven't attached a restrictive license header
- [ ] If redistributing docs content, attribution is preserved per CC-BY 4.0

### 5.5.11 Typical onramp

For someone getting involved seriously:
1. Join [Discord](https://discord.gg/6CSzBmMkjX). **Set display name to `name (company)` or `username (company)` before first post** (server rule, §8.2). Lurk 1–2 IGs aligned to your interests.
2. Read the spec; the server assumes base understanding. Don't use Discord as a getting-started venue.
3. Attend [live calls](https://meet.modelcontextprotocol.io/); ship small PRs / take meeting notes.
4. After ~3 months of sustained contribution in a WG → nominate for WG Member.
5. Longer-term path to Maintainer via [Contributor Ladder](https://modelcontextprotocol.io/community/contributor-ladder).

---

## Step 6: Repo map

| Repo | Contents | Notes |
|---|---|---|
| [`modelcontextprotocol/modelcontextprotocol`](https://github.com/modelcontextprotocol/modelcontextprotocol) | Spec, docs, SEPs | Primary for governance work |
| [`typescript-sdk`](https://github.com/modelcontextprotocol/typescript-sdk) | TS/JS SDK | |
| [`python-sdk`](https://github.com/modelcontextprotocol/python-sdk) | Python SDK | |
| [`go-sdk`](https://github.com/modelcontextprotocol/go-sdk) | Go SDK | Partner co-maintained |
| [`java-sdk`](https://github.com/modelcontextprotocol/java-sdk) | Java SDK | |
| [`kotlin-sdk`](https://github.com/modelcontextprotocol/kotlin-sdk) | Kotlin SDK | JetBrains co-maintained |
| [`csharp-sdk`](https://github.com/modelcontextprotocol/csharp-sdk) | C# SDK | Microsoft co-maintained |
| [`swift-sdk`](https://github.com/modelcontextprotocol/swift-sdk) | Swift SDK | |
| [`rust-sdk`](https://github.com/modelcontextprotocol/rust-sdk) | Rust SDK | |
| [`ruby-sdk`](https://github.com/modelcontextprotocol/ruby-sdk) | Ruby SDK | |
| [`php-sdk`](https://github.com/modelcontextprotocol/php-sdk) | PHP SDK | |

---

## Step 6.5: Roadmap-aligned priorities (boost your SEP's odds)

From the [MCP roadmap](https://modelcontextprotocol.io/development/roadmap) (last updated 2026-03-05). **SEPs aligned with these areas get expedited review and the highest acceptance odds.** Outside these areas → longer review, higher bar for justification.

### Priority Areas

1. **Transport Evolution & Scalability** — stateless Streamable HTTP, scalable session handling, MCP Server Cards (`.well-known` metadata). Owned by **Transports WG** + **Server Card WG**. No new official transports this cycle.
2. **Agent Communication** — Tasks primitive ([SEP-1686](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1686)) lifecycle gaps: retry semantics, expiry policies. Owned by **Agents WG**.
3. **Governance Maturation** — Contributor Ladder SEP, WG delegation model, charter template. [SEP-1302](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1302) formalized WG/IG structure; [SEP-2085](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/2085) established succession/amendment. Owned by **Governance WG**.
4. **Enterprise Readiness** — audit trails, SSO/enterprise auth ([Cross-App Access](https://xaa.dev)), gateway/proxy patterns, configuration portability. Expected **Enterprise WG** to form; much will land as extensions, not core spec.

### On the Horizon (lower priority, but SEPs welcome)

- **Triggers & Event-Driven Updates** — server-push callbacks vs polling
- **Result Type Improvements** — streamed results, reference-based results
- **Security & Authorization** — fine-grained scopes, OAuth mix-up prevention, vuln disclosure program. Active: [SEP-1932 DPoP](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/1932), [SEP-1933 Workload Identity Federation](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/1933)
- **Extensions Ecosystem** — `ext-auth`, `ext-apps` tracks; Skills primitive; registry extension support

### Validation investment

- **Conformance test suites** — automated spec verification
- **SDK Tiers** — [SEP-1730](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1730) defines tiering so devs know which SDKs track spec most closely
- **Reference implementations** — canonical implementations for new features

**Pre-flight check for your SEP idea:** Is it in a priority area? Is it backed by the owning WG? Both yes = fastest path. If your idea falls in "On the Horizon", [SEP-2133](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/2133) Extensions Framework lets you experiment in `experimental-ext-*` repos before needing a formal SEP.

---

## Step 6.6: Worked example — SEP-2133 (Extensions Framework)

Concrete reference for what a merged+FINAL SEP looks like. Read [PR #2133](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2133) directly for the current shape of the diff, reviewer list, and vote record — don't rely on a cached summary for those specifics (they rot).

**What the SEP established** (from the merged doc, [SEP-2133](https://modelcontextprotocol.io/seps/2133-extensions)):
- Extensions governance + technical standards
- **Extension identifiers:** reverse-domain notation (e.g. `io.modelcontextprotocol/oauth-client-credentials`)
- **Official extensions:** live in dedicated repos under `github.com/modelcontextprotocol/ext-*`
- **Capability negotiation:** `extensions` field added to `ClientCapabilities` and `ServerCapabilities`
- Legal framework: trademark, antitrust, licensing, contributor provisions

**Typical shape of a Standards-Track SEP's diff** (use PR #2133 as a template):
- New SEP doc at `seps/<num>-<slug>.md`
- Schema updates to relevant types in `schema/draft/schema.ts`
- Docs page(s) in `docs/`
- Lifecycle / spec page updates if needed
- Example JSON/TypeScript demonstrating the feature

**Review pattern worth imitating** (verify current reviewers on the PR itself):
- Expect extensive Core Maintainer review across multiple rounds
- Comments typically focus on: definition clarity, collision prevention, breaking-change definitions, **RFC 2119 normative language consistency** (MUST / SHOULD / MAY)
- Final decision happens at the biweekly Core Maintainer meeting (§5.4) — vote counts are recorded on the PR; check there, don't cache them in this skill

**Takeaways for your own SEP:**
- Use RFC 2119 keywords (MUST/SHOULD/MAY) consistently — reviewers will call this out
- Pre-empt collision/naming questions before review
- Be explicit about what counts as a breaking change
- Expect 4+ maintainer review rounds; budget for iteration
- Include example JSON/code, not just prose
- Legal clauses matter — don't omit them for a governance-adjacent SEP

---

## Step 7: Finding something to work on

For first-timers or when browsing:

- **Good first issues (spec):** https://github.com/modelcontextprotocol/modelcontextprotocol/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
- **Docs typos / clarity fixes:** always welcome, no issue required.
- **Schema examples:** add JSON to `schema/draft/examples/` — high leverage for low effort.
- **SDK good-first-issues:** check each SDK repo's issue tracker.

Use `gh` to triage quickly. **Org-wide search is usually more useful than single-repo — there are 11+ SDK repos + the spec repo:**
```bash
# Org-wide across all MCP repos (most useful first query):
gh search issues 'org:modelcontextprotocol label:"good first issue" state:open' --limit 30

# Or one specific repo:
gh issue list --repo modelcontextprotocol/modelcontextprotocol --label "good first issue" --state open
gh issue list --repo modelcontextprotocol/php-sdk        --label "good first issue" --state open
# ... swap the repo name for any SDK
```

---

## Step 8: Communication channels

All channels governed by the [Code of Conduct](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/CODE_OF_CONDUCT.md). Professional, inclusive, vendor-neutral.

### 8.1 Channel map — pick the right venue

| Channel | Purpose | When to use |
|---|---|---|
| [Discord](https://discord.gg/6CSzBmMkjX) | Real-time contributor chat | Quick questions, coordination, WG/IG discussions |
| [meet.modelcontextprotocol.io](https://meet.modelcontextprotocol.io/) | Live calls | WG/IG meetings, progress reports |
| [GitHub Discussions](https://github.com/modelcontextprotocol/modelcontextprotocol/discussions) | Structured long-form | Proposals, roadmap planning, **feature requests**, polls, announcements |
| [GitHub Issues](https://github.com/modelcontextprotocol/modelcontextprotocol/issues) | Actionable tasks | **Bug reports with repro steps**, documented fixes, CI/infra problems, release tasks |
| PR to `seps/` | SEP submission | **SEPs go here, NOT as Issues** |
| [SECURITY.md](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/SECURITY.md) | Vulnerability reports | Security issues — **NEVER post publicly** |

**Critical rule:** feature requests → Discussions, NOT Issues. Bugs with repro → Issues. SEPs → PR to `seps/`. This is the single most common newcomer mistake.

### 8.2 Discord etiquette — MCP's rules are STRICTER than most OSS Discords

Read these carefully. Violations (especially #2) are ban-worthy. **Source: MCP Contributor Discord pinned rules + [/community/communication](https://modelcontextprotocol.io/community/communication). Last verified 2026-04-16.**

**The ten rules:**

1. **Scope of the server.** It exists to **advance MCP as a protocol**. Not a user-support forum, not a "getting started with MCP" channel. Participants are assumed to have a solid base understanding of the spec.
2. **No self-promotion. Period.** Beyond introducing yourself, **do not bring up your project or product unless it is directly relevant to the discussion at hand**. Standalone announcements of tools/skills/SDKs/services are out.
3. **Solicitation of work anywhere on the server is a bannable offense.** Don't DM maintainers for hire. Don't post "looking for contract work."
4. **Usage discussions are out of scope** — unless the usage is being cited as an example for a protocol improvement or proposal. "How do I implement X with MCP?" is the wrong question here; ask in GitHub Discussions or the user-facing channels of specific clients.
5. **Display name format is required:** `name (company)` or `username (company)`. Set this before your first post.
6. **Use threads, not main-channel messages,** for anything beyond a single-message ack. Threads keep channels browsable.
7. **No vendor or product marketing.** Brand mentions OK only as spec-relevant examples (from `/community/communication`).
8. **Security issues never post publicly** — use the [SECURITY.md](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/SECURITY.md) private flow (§8.3).
9. **Any Discord discussion heading toward a decision or proposal MUST move to GitHub Discussions or an Issue** (tag `notes`) to create a persistent searchable record.
10. **Private channels** are "incident rooms" (CoC, security, people matters). Not for routine dev.

**Public channels cover** (per `/community/communication`): SDK development (the verified cross-SDK channel is `#general-sdk-dev`; per-language channels may exist but verify), WG/IG channels (§5.5.4), onboarding, office hours.

### 8.2a Before your first post in any Discord channel — checklist

1. **Set your display name to `name (company)` or `username (company)`** before posting anything.
2. **Read the server-wide rules channel** (and any pinned welcome).
3. **Read pinned messages in the target channel.** Click the pin icon in Discord's channel header.
4. **Check the channel description** (topic bar).
5. **Scroll back ~50 messages.** Watch how moderators redirect people — that's the ground-truth norm.
6. **Start a thread for anything multi-message.** Don't bury the main channel.

### 8.2b DO NOT post a standalone tool/skill/project announcement

The strict reading of rule #2 is that *any* top-level "I built X, here it is" post is self-promotion, even if the tool is MCP-related and open-source. **Exceptions are narrow:**

- ✅ **In `#introductions`, you may briefly mention what you build.** Keep it one line of context, no link.
- ✅ **In a live discussion where your tool is directly relevant**, you may reply in-thread with the link + "I made this, happy to take feedback." The tool must answer the specific question being asked.
- ✅ **If a maintainer explicitly asks you to share**, you may share in whatever channel they pointed you to.
- ❌ **Do NOT** open a top-level message in `#general`, `#show-and-tell` (if it even exists here — don't assume), or any dev channel with "hey I built X, here's the link." That's the default-self-promo pattern the rule bans.
- ❌ **Do NOT** pre-announce a tool before it's been referenced in an existing discussion.

**If you genuinely want the community to know about a contributor tool:**
- Path A: lurk for weeks; wait for a discussion where the tool is the natural answer; reply in-thread.
- Path B: open a GitHub Discussion in `modelcontextprotocol/modelcontextprotocol` (or the relevant SDK repo) describing the tool + why it exists. GitHub Discussions are on-topic for tooling; Discord isn't.
- Path C: if the tool is specifically useful for contributors, propose documenting it in the community docs via a PR. That's on-topic.

**Rule-of-thumb:** if you're typing "just wanted to share..." into Discord, stop. Open a GitHub Discussion instead.

### 8.2c Introduction post template (the ONE case where a brief mention is OK)

**Step 0 — before ANY post, including the intro: confirm your employer's OSS policy allows personal contribution to MCP.** Most large employers have explicit rules (intranet search for "open source contribution policy"). Check:
- Does your employment agreement's IP / outside-work clause cover this?
- Does your employer require manager pre-approval for OSS participation?
- Does your employer require a specific disclosure format when you identify as an employee in OSS forums?

If your employer blocks or conditions personal MCP contribution → **resolve that first**. Don't post, don't set a display name, don't lurk with an identifiable handle until cleared. The post is permanent; the policy check is 10 minutes.

**Step 0a — pick your display-name format (server rule: `name (company)` or `username (company)`)**:

| Format | When to use |
|---|---|
| `Name (Employer)` | You're contributing as a representative of your employer (rare for individual contributors) |
| `Name (Employer, personal)` | **Default for employed people contributing in personal capacity.** Truthful, clearly signals you're not speaking for the employer. |
| `Name (personal)` or `Name (independent)` | Self-employed, between jobs, or your employer's OSS policy explicitly requires non-employer affiliation labels. Strict reading of MCP's rule expects `(company)`, so prefer the `(Employer, personal)` form when an employer exists. |
| `Name (freelance)` | Only if you are actually freelance. Not a hedge for "I don't want to name my employer." |

**Never pick a label that's inaccurate** — MCP contributors often have employer-facing presences (LinkedIn, personal sites) and inaccurate affiliation gets noticed. Dishonest labeling is a worse look than any honest affiliation.

**Step 0b — if you work somewhere with antitrust exposure** (big tech, finance, retail-tech, enterprise SaaS), skim MCP's [Antitrust Policy](https://modelcontextprotocol.io/community/antitrust) before posting. Your words could be read as your employer's position in edge cases. The `(Employer, personal)` label reduces but doesn't eliminate this.

**Then** post in `#introductions` only, as a first post:

```
Hi 👋 <name> — <one-line role/background>, recently started contributing to MCP.
Been digging into <specific area, e.g. the SEP process / auth / tasks>.
<Optional: one sentence about what you build in your day job, no link>.
Looking forward to lurking, learning, and eventually <concrete contribution goal>.
```

Rules this must follow:
- Employer OSS policy confirmed (Step 0) — NO EXCEPTIONS
- Display name set per Step 0a FIRST
- No links in the intro post
- No "I made an X, check it out" — that's promo
- One sentence of background, not a résumé
- Name a concrete thing you want to learn/contribute, not a vague interest

### 8.3 Security issues — the one rule to never break

- Do NOT open public issues, PRs, or Discord posts for vulnerabilities.
- Use the private reporting flow in [SECURITY.md](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/SECURITY.md).
- Or contact a [Lead or Core Maintainer](https://modelcontextprotocol.io/community/governance#current-core-maintainers) directly.
- Follow responsible disclosure.

### 8.4 Where decisions are recorded

All MCP decisions are public:

| Type | Location |
|---|---|
| Technical decisions | GitHub Issues + SEPs |
| Spec changes | [Changelog](https://modelcontextprotocol.io/specification/draft/changelog) |
| Process changes | [Community docs](https://modelcontextprotocol.io/community/governance) |
| Governance decisions | GitHub Issues + SEPs |

Decision write-ups should capture: decision makers, background/motivation, options considered, rationale, implementation steps.

### 8.5 Quick "where do I put this?" cheat sheet

- "I hit a bug, here's the repro" → **Issue**
- "I think we should add X feature" → **Discussion**
- "I have a spec change to propose" → **PR to `seps/`**
- "Is anyone working on X?" → **Discord** (then if serious, move to Discussion)
- "I want to talk through a design idea" → **Discord** → **Discussion** once it crystalizes
- "I found a vulnerability" → **SECURITY.md private flow**
- "We decided something in Discord" → move the outcome to **Discussion** or **Issue** with `notes` label

---

## Step 9: AI-contribution disclosure

MCP welcomes AI-assisted contributions. **Disclose** in the PR/issue body with a one-liner: "Drafted with Claude; I reviewed and tested all changes."

The human contributor must be able to:
- Explain what the change does
- Articulate why it's needed
- Verify it works (tests pass, behavior confirmed)

See [AI Contributions policy](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/CONTRIBUTING.md#ai-contributions).

---

## Step 10: Good PR vs bad PR (quick checklist)

Before requesting review:

- [ ] Focused on ONE issue (not a grab-bag)
- [ ] Descriptive commits, not "fixed stuff"
- [ ] Issue number referenced if applicable
- [ ] All CI checks green
- [ ] `npm run check` passes locally
- [ ] Tests added (SDK) or examples added (spec), where applicable
- [ ] AI-assist disclosed if used

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `npm run check` fails | Check Node ≥24; re-run `npm install`; `npm run generate:schema`; `npm run format` |
| PR sitting for weeks | CI green? Then polite ping in PR comment; cross-post in Discord channel; last resort → Core Maintainer |
| No SEP sponsor | Discussed in Discord/WG first? Split into smaller SEPs? Demonstrated community interest? |
| SEP rejected | Not permanent. Address feedback, try different angle, or wait. |

---

## Reference links

- MDX spec: https://mdxjs.com/
- Mintlify docs (component library): https://www.mintlify.com/docs/components
- Mintlify main: https://www.mintlify.com/
- Contributor Communication guide: https://modelcontextprotocol.io/community/communication
- Spec changelog: https://modelcontextprotocol.io/specification/draft/changelog
- SECURITY.md: https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/SECURITY.md
- Code of Conduct: https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/CODE_OF_CONDUCT.md
- Contributing guide: https://modelcontextprotocol.io/community/contributing
- SEP Guidelines: https://modelcontextprotocol.io/community/sep-guidelines
- SEP template: https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/seps/README.md#sep-file-structure
- SEPs directory: https://github.com/modelcontextprotocol/modelcontextprotocol/tree/main/seps
- Design principles: https://modelcontextprotocol.io/community/design-principles
- Project roadmap: https://modelcontextprotocol.io/development/roadmap
- Governance model: https://modelcontextprotocol.io/community/governance
- Working + Interest Groups: https://modelcontextprotocol.io/community/working-interest-groups
- Contributor Ladder: https://modelcontextprotocol.io/community/contributor-ladder
- SEP-2148 (Contributor Ladder, canonical): https://modelcontextprotocol.io/seps/2148-contributor-ladder
- SEP-2149 (WG/IG Governance + Charter Template, canonical): https://modelcontextprotocol.io/seps/2149-working-group-charter-template
- Lead Maintainer succession section: https://modelcontextprotocol.io/community/contributor-ladder#succession
- Charter Template: https://modelcontextprotocol.io/community/charter-template
- Meeting calendar: https://meet.modelcontextprotocol.io
- Meeting Notes category: https://github.com/modelcontextprotocol/modelcontextprotocol/discussions
- Access repo (member lists): https://github.com/modelcontextprotocol/access
- LF Projects policies: https://www.lfprojects.org/policies/
- Working/Interest Groups: https://modelcontextprotocol.io/community/working-interest-groups
- Communication: https://modelcontextprotocol.io/community/communication
- Maintainers: https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/MAINTAINERS.md
- Code of Conduct: https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/CODE_OF_CONDUCT.md
- License: Apache 2.0 (code/spec), CC-BY 4.0 (docs)

---

## Step 11: Reference appendix (distilled from gap-high sources)

Compact synthesis of contributor-critical pages. Each has a source link for full detail.

### 11.1 Design Principles (SEP pre-flight checklist)

Source: https://modelcontextprotocol.io/community/design-principles. Your SEP is evaluated against **8 principles** — if it fails any, budget more review cycles or reshape:

1. **Convergence over choice** — one way to solve a problem in the spec. Extensions are where choice is tolerated.
2. **Composability over specificity** — don't add protocol features that can be built from tools/resources/prompts/tasks.
3. **Interoperability over optimization** — features must degrade gracefully. Capability negotiation is the mechanism.
4. **Stability over velocity** — "no" leaves the door open; "yes" closes it forever. Optimize for decades.
5. **Capability over compensation** — don't add permanent structure to work around temporary model limitations.
6. **Demonstration over deliberation** — working prototype > theoretical argument. See §5.5 prototype requirement.
7. **Pragmatism over purity** — accept some inconsistency for adoption.
8. **Standardization over innovation** — codify proven patterns. Experiment via extensions; standardize via SEPs.

### 11.2 Antitrust Policy

Source: https://modelcontextprotocol.io/community/antitrust. **Effective 2025-09-29.** Contact: `antitrust@modelcontextprotocol.io`.

Applies to WG/IG meetings and any forum where competitors may be present. **Do NOT discuss:**
- Individual company prices, discounts, margins, costs
- Industry-wide pricing, capacity, production
- Bidding intentions or specific contracts
- Individual company product plans, territories, customers
- Actual/potential supplier or customer exclusion
- Market shares, confidential business strategy

**Meeting hygiene:** adhere to prepared agendas; ensure minutes exist; if a discussion crosses a line, **protest + leave the meeting + insist it's noted in minutes**; consult your own counsel.

### 11.3 SDK Tiering System

Source: https://modelcontextprotocol.io/community/sdk-tiers ([SEP-1730](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1730)). Key dates: conformance tests available **2026-01-23**, official tiering published **2026-02-23**.

| Tier | Conformance | New features | Triage | Critical bug fix | Stable release |
|---|---|---|---|---|---|
| **1 Fully Supported** | 100% | Before spec release | 2 biz days | 7 days | Required |
| **2 Commitment to Full** | 80% | ≤6 months | 1 month | 2 weeks | ≥1 stable |
| **3 Experimental** | no min | none | none | none | not required |

**Relegation:** Tier 1→2 if any test fails 4 weeks; Tier 2→3 if >20% fail 4 weeks.
**Advancement:** self-assess → open issue → conformance tests pass → SDK WG approval.
**P0 bug** = CVSS ≥7.0 security **or** core functionality broken (connection, message exchange, primitives).
**Required labels:** `bug`/`enhancement`/`question`, `needs confirmation`/`needs repro`/`ready for work`/`good first issue`/`help wanted`, `P0`/`P1`/`P2`/`P3`.

### 11.4 Server concepts — server primitives deep

Source: https://modelcontextprotocol.io/docs/learn/server-concepts.

| Primitive | Controlled by | Methods | Use for |
|---|---|---|---|
| **Tools** | Model (LLM decides) | `tools/list`, `tools/call` | Actions with side effects |
| **Resources** | Application | `resources/list`, `resources/templates/list`, `resources/read`, `resources/subscribe` | Read-only context data |
| **Prompts** | User (explicit invocation) | `prompts/list`, `prompts/get` | Pre-built templates / slash commands |

**Tool definition:** JSON-Schema `inputSchema`. Name should be namespaced (`calculator_arithmetic`, not `calculate`).
**Resources:** unique URIs (`file:///…`, `calendar://…`), MIME type declared. Two discovery patterns: direct URIs + URI templates with `{param}` (e.g. `weather://forecast/{city}/{date}`). Templates support parameter completion.
**Prompts:** parameterized templates; users invoke explicitly (slash commands, command palettes).

### 11.5 Client concepts — client primitives deep

Source: https://modelcontextprotocol.io/docs/learn/client-concepts.

| Primitive | Method | Purpose |
|---|---|---|
| **Elicitation** | `elicitation/requestInput` | Server asks user for info; includes a JSON Schema form. **Never passwords/API keys.** |
| **Roots** | `roots/list`, `roots/list_changed` | Client tells server filesystem boundaries (`file://` URIs). Advisory, not a security boundary. |
| **Sampling** | `sampling/createMessage` | Server requests LLM completion via client; human-in-loop approval at request + response. |
| **Logging** | (server → client notifications) | Server emits structured logs. |

**Sampling params:** `messages`, `modelPreferences` (hints + `costPriority`/`speedPriority`/`intelligencePriority`), `systemPrompt`, `maxTokens`.

### 11.6 Versioning

Source: https://modelcontextprotocol.io/docs/learn/versioning.

- Version strings = date `YYYY-MM-DD`. Version increments ONLY for backwards-incompatible changes. Backwards-compat changes don't bump the version.
- Revision statuses: **Draft** (not ready), **Current** (usable, receives BC changes), **Final** (frozen).
- Current protocol version: **`2025-11-25`**.
- Negotiation happens in `initialize`. Both sides MAY support multiple versions but MUST agree on one per session. On mismatch → clients SHOULD disconnect.

### 11.7 Lifecycle spec

Source: https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle.

Three phases: **Initialization → Operation → Shutdown**.

1. Client sends `initialize` with `protocolVersion`, `capabilities`, `clientInfo`. Client SHOULD NOT send non-ping requests before server responds.
2. Server responds with its `protocolVersion`, `capabilities`, `serverInfo`, optional `instructions`.
3. Client sends `notifications/initialized` (no response expected).
4. Both sides MUST respect negotiated protocol version + only use negotiated capabilities.

**Capabilities (client):** `roots`, `sampling`, `elicitation` (form/url), `tasks`, `experimental`.
**Capabilities (server):** `prompts`, `resources` (with `subscribe`/`listChanged`), `tools` (with `listChanged`), `logging`, `completions`, `tasks`, `experimental`.

**Shutdown:**
- **stdio:** client closes stdin → wait → SIGTERM → SIGKILL.
- **HTTP:** close the connection.

**Error codes:** `-32602` for "Unsupported protocol version". Response body includes `supported: [...]` + `requested`.

**Timeouts:** implementations SHOULD enforce per-request timeouts + cancellation notifications. MAY reset on progress notifications but MUST enforce a max.

### 11.8 Transports spec

Source: https://modelcontextprotocol.io/specification/2025-11-25/basic/transports.

**Two standard transports:** stdio, Streamable HTTP. Clients SHOULD support stdio whenever possible.

**stdio rules:**
- Client launches server as subprocess. Server reads JSON-RPC from stdin, writes to stdout. Messages newline-delimited, MUST NOT contain embedded newlines.
- Server MAY use stderr for any logging (debug, info, error). Client MUST NOT assume stderr means error.
- Server MUST NOT write anything to stdout that isn't a valid MCP message.

**Streamable HTTP:** single MCP endpoint supporting POST + GET. POST for client→server messages; server returns either `application/json` (one response) or `text/event-stream` (SSE stream). GET opens SSE for server-initiated messages.
- **Security:** servers MUST validate `Origin` header (DNS rebinding); SHOULD bind to localhost only when local; SHOULD implement auth.
- **Sessions:** server MAY assign `MCP-Session-Id` header on initialize. Clients MUST echo it. Server MAY terminate session → HTTP 404 → client starts new session.
- **Protocol version header:** `MCP-Protocol-Version: <version>` required on all HTTP requests after initialize. Missing → server assumes `2025-03-26`.
- **Resumability:** SSE events MAY have IDs. Clients reconnect via GET with `Last-Event-ID`. Server MAY replay per-stream.
- **Replaces** HTTP+SSE transport from `2024-11-05`. Backwards compat: try POST first, fall back to GET `endpoint` event if 400/404/405.

**Custom transports:** MAY implement but MUST preserve JSON-RPC format + lifecycle.

### 11.9 Authorization spec

Source: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization. Auth is **OPTIONAL**; HTTP-based transports SHOULD conform; stdio SHOULD use env credentials.

**Basis:** OAuth 2.1 draft + RFC 8414 (AS metadata) + RFC 7591 (DCR) + RFC 9728 (PRM) + Client ID Metadata Documents draft.

**MUST haves:**
- MCP server = OAuth 2.1 resource server. MUST implement RFC 9728 Protected Resource Metadata.
- MCP clients MUST use PRM for AS discovery. MUST support both WWW-Authenticate + well-known URI paths.
- Auth servers MUST provide RFC 8414 OR OpenID Connect Discovery. Clients MUST support both.
- MUST implement PKCE (S256 when capable). Client refuses to proceed if server doesn't advertise `code_challenge_methods_supported`.
- Resource Indicators (RFC 8707): `resource` param MUST be in authz + token requests, identifying the specific MCP server as the token audience.
- Tokens: `Authorization: Bearer <token>` on every HTTP request (even same session). Never in query strings. Server MUST validate audience. Server MUST NOT pass through tokens to upstream APIs.

**Client registration (priority order):** 1) pre-registration, 2) Client ID Metadata Document (if AS advertises `client_id_metadata_document_supported`), 3) Dynamic Client Registration (RFC 7591), 4) user prompt.

**Scope strategy:** use `scope` from `WWW-Authenticate` 401 header; fallback to PRM `scopes_supported`; omit if neither. Step-up flow on `403 insufficient_scope`.

**Errors:** 401 = needs auth/bad token; 403 = bad scope/perms; 400 = malformed.

**Active SEPs touching auth:** [SEP-1932 DPoP](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/1932), [SEP-1933 Workload Identity Federation](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/1933), [SEP-991 CIMD](https://modelcontextprotocol.io/seps/991-enable-url-based-client-registration-using-oauth-c), [SEP-985 PRM/RFC9728 alignment](https://modelcontextprotocol.io/seps/985-align-oauth-20-protected-resource-metadata-with-rf).

### 11.10 Spec changelog — `2025-11-25` vs `2025-06-18`

Source: https://modelcontextprotocol.io/specification/2025-11-25/changelog.

**Major:**
1. AS discovery now supports OpenID Connect Discovery 1.0 (PR #797).
2. Icons as additional metadata for tools/resources/templates/prompts ([SEP-973](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/973)).
3. Incremental scope consent via `WWW-Authenticate` ([SEP-835](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/835)).
4. Tool-name format guidance ([SEP-986](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/1603)).
5. `ElicitResult` / `EnumSchema` standards-based: titled, untitled, single-select, multi-select ([SEP-1330](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1330)).
6. URL mode elicitation for out-of-band flows ([SEP-1036](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/887)).
7. Tool calling added to sampling via `tools` + `toolChoice` ([SEP-1577](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1577)).
8. OAuth Client ID Metadata Documents as recommended registration ([SEP-991](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/991), PR #1296).
9. **Experimental Tasks** primitive — durable requests with polling + deferred retrieval ([SEP-1686](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1686)).

**Minor/process:** stderr logging allowed for any level (#670), HTTP 403 for bad Origin (#1439), input validation errors as Tool Execution Errors ([SEP-1303](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1303)), SSE polling via server disconnect ([SEP-1699](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1699)), PRM/RFC-9728 alignment ([SEP-985](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/985)), default values in elicitation schemas ([SEP-1034](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1034)), **JSON Schema 2020-12 as default dialect** ([SEP-1613](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1613)).

**Governance:** [SEP-932](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/932) (governance), [SEP-994](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/994) (comms), [SEP-1302](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1302) (WG/IG formalization), [SEP-1730](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1730) (SDK tiers).

Full diff: https://github.com/modelcontextprotocol/specification/compare/2025-06-18...2025-11-25

### 11.11 SEP index snapshot (2026-04-16)

Source: https://modelcontextprotocol.io/seps/index. Totals: **27 Final / 2 Accepted / 1 Draft** at fetch.

**Accepted (awaiting reference impl):**
- [SEP-2260](https://modelcontextprotocol.io/seps/2260-Require-Server-requests-to-be-associated-with-Client-requests) — Require Server requests associated with Client requests
- [SEP-2207](https://modelcontextprotocol.io/seps/2207-oidc-refresh-token-guidance) — OIDC-Flavored Refresh Token Guidance

**Draft:**
- [SEP-2243](https://modelcontextprotocol.io/seps/2243-http-standardization) — HTTP Header Standardization for Streamable HTTP Transport

**Final (most relevant for contributor context):**
- [SEP-2149](https://modelcontextprotocol.io/seps/2149-working-group-charter-template), [SEP-2148](https://modelcontextprotocol.io/seps/2148-contributor-ladder), [SEP-2133](https://modelcontextprotocol.io/seps/2133-extensions), [SEP-2085](https://modelcontextprotocol.io/seps/2085-governance-succession-and-amendment)
- [SEP-1865 MCP Apps](https://modelcontextprotocol.io/seps/1865-mcp-apps-interactive-user-interfaces-for-mcp), [SEP-1850 PR-based SEP workflow](https://modelcontextprotocol.io/seps/1850-pr-based-sep-workflow)
- [SEP-1730 SDK Tiers](https://modelcontextprotocol.io/seps/1730-sdks-tiering-system), [SEP-1686 Tasks](https://modelcontextprotocol.io/seps/1686-tasks)
- [SEP-1613 JSON Schema 2020-12](https://modelcontextprotocol.io/seps/1613-establish-json-schema-2020-12-as-default-dialect-f), [SEP-1577 Sampling with Tools](https://modelcontextprotocol.io/seps/1577--sampling-with-tools)
- [SEP-1330 Elicitation enum](https://modelcontextprotocol.io/seps/1330-elicitation-enum-schema-improvements-and-standards), [SEP-1319 Payload decoupling](https://modelcontextprotocol.io/seps/1319-decouple-request-payload-from-rpc-methods-definiti)
- [SEP-1303 Input validation as Tool Exec Errors](https://modelcontextprotocol.io/seps/1303-input-validation-errors-as-tool-execution-errors), [SEP-1302 WG/IG formalization](https://modelcontextprotocol.io/seps/1302-formalize-working-groups-and-interest-groups-in-mc)
- [SEP-1046 OAuth client credentials](https://modelcontextprotocol.io/seps/1046-support-oauth-client-credentials-flow-in-authoriza), [SEP-1036 URL mode elicitation](https://modelcontextprotocol.io/seps/1036-url-mode-elicitation-for-secure-out-of-band-intera)
- [SEP-1034 Elicitation defaults](https://modelcontextprotocol.io/seps/1034--support-default-values-for-all-primitive-types-in), [SEP-1024 Local server security](https://modelcontextprotocol.io/seps/1024-mcp-client-security-requirements-for-local-server-)
- [SEP-994 Comms guidelines](https://modelcontextprotocol.io/seps/994-shared-communication-practicesguidelines), [SEP-991 CIMD](https://modelcontextprotocol.io/seps/991-enable-url-based-client-registration-using-oauth-c)
- [SEP-990 Enterprise IdP controls](https://modelcontextprotocol.io/seps/990-enable-enterprise-idp-policy-controls-during-mcp-o), [SEP-986 Tool names](https://modelcontextprotocol.io/seps/986-specify-format-for-tool-names)
- [SEP-985 PRM/RFC9728](https://modelcontextprotocol.io/seps/985-align-oauth-20-protected-resource-metadata-with-rf), [SEP-973 Metadata icons](https://modelcontextprotocol.io/seps/973-expose-additional-metadata-for-implementations-res)
- [SEP-932 Governance](https://modelcontextprotocol.io/seps/932-model-context-protocol-governance), [SEP-414 OpenTelemetry](https://modelcontextprotocol.io/seps/414-request-meta)

**Before drafting a SEP, check:** does yours duplicate an existing one? Extend one? Conflict with one in `Final`? Use the index as your literature review.

---

## Session log

Append one-liners when this skill is used on real contributions — SHA, PR URL, lessons.

<!-- 2026-04-16: skill scaffolded from modelcontextprotocol.io/community/contributing -->
<!-- 2026-04-16: dry-run #2 on modelcontextprotocol/inspector#832 — all dry-run #1 bugs held (§1.4, §2, §4/§8.2, §6.6, §7). New bugs filed as GH issues: §6 missing non-SDK repos, §4 mistitled, no §11.7 cross-ref. Skill correctly triaged #832 as direct PR, not SEP. -->
