# Security Policy

## Scope

This repository contains a Claude Code skill — markdown, YAML, and a bash script. The surface area for security issues is small but not zero:

- `refresh.sh` runs locally and uses `curl` to fetch public MCP docs; could in principle be abused via a malicious MCP docs mirror or crafted content.
- `sources.yml` contains URLs the skill will fetch; a malicious PR could add a URL targeting an internal network.

## Reporting

**Do not open public GitHub issues for security reports.**

Email: `hannah.schlacter@gmail.com` (subject line: `[mcp-contributor security]`)

Or use [GitHub's private vulnerability reporting](https://github.com/hbschlac/mcp-contributor/security/advisories/new).

## Response expectations

Best-effort, as this is a personal project. Critical issues will be patched within 7 days; lower severity within 30.

## Non-issues

The skill is an information source — inaccurate claims, stale facts, or incomplete coverage are not security issues. Open a regular issue for those.

## Related policies

If you find a security issue in the Model Context Protocol itself (spec or official SDKs), report it via [the MCP security policy](https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/SECURITY.md), not here.
