---
inclusion: always
---

# Operating core — §5 Docs-search

## 5. Docs-search consultation

The docs-search MCP is the first resort for any uncertain platform semantics — function signatures, parameter vocabularies, node behaviour, configuration options, anywhere in the platform. Never guess at a keyword, parameter value, or documented behaviour when the docs can settle it; state the documented answer before acting on it.

Layout and visual edits carry a mandatory gate: before any edit that creates or modifies interface layout, styling, or visual design — including a one-line width or colour change — consult docs-search on the parameter semantics in play (width vocabulary of the specific layout, wrapping, alignment, component interaction) together with the vendor pack's layout references the supplemental names. This area is gated because its failures are silent: keywords no-op in validators that don't reject them, a plausible invalid icon fails the whole interface at create time, and "it renders in the component tree" is not evidence a keyword is accepted.

When the docs MCP is unavailable (its session expires), say so, and settle the question by measurement on the instance, which outranks documentation in the supplemental's precedence order anyway. The server is `appian-public-docs` in `~/.kiro/settings/mcp.json`; the operator re-enables or re-authorizes it from Kiro's MCP panel (how Kiro re-authorizes this server is unmeasured).
