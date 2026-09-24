/*
 * SO_snowflakeMark — THE provenance marker. Every screen calls this and nothing
 * renders the mark any other way, so the asset, its accessibility fallback and
 * any future change are ONE edit rather than five scattered ones.
 *
 * ===================== THIS RULE PREVIEWS BROKEN. BY DESIGN. =====================
 * Opening this object in Designer shows
 *     "Rich text icon must be contained (directly or indirectly) within a rich
 *      text display component"
 * and that is CORRECT, NOT A DEFECT. This is a FRAGMENT RULE: it returns a bare
 * a!richTextImage / a!richTextIcon, which is not a component and cannot stand
 * alone — it is only ever composed inside an a!richTextDisplayField by its
 * callers, which is exactly where it is legal. The preview has no call site, so
 * it has no container, so it complains.
 *
 * PREVIEW ERRORS STANDALONE BY DESIGN — FRAGMENT RULE; RENDER VIA ANY CALL SITE.
 * Verify it through a screen that uses it (SO_analystWatchlist, SO_caseDetail),
 * never through this object's own preview. Do not "fix" it by wrapping the
 * return in a!richTextDisplayField: that would make the rule a component, and
 * every caller would then be nesting a display field inside a display field
 * instead of placing a mark inline beside its label.
 *
 * ============================ WHY THERE IS A SWITCH ============================
 * The marker is the in-system Snowflake logo document (cons!SO_SNOWFLAKE_LOGO),
 * and it is LIVE as of 2026-09-09: viewer rights were granted in Designer and
 * read back as SO Analysts (direct) plus SO Users and SO Administrators
 * (inherited from the folder), so both demo personas can read it.
 *
 * THE FALLBACK STAYS, and it is insurance rather than leftovers. The document
 * still lives in the FINANCIAL SERVICES DATA FABRIC EXAMPLES application — a
 * cross-application asset is a SINGLE POINT OF FAILURE for a multi-SC demo, and
 * the failure mode is severe. MEASURED 2026-09-03, before the grant: neither
 * persona could read it, a!documentImage threw
 *     "User Does Not Have Rights to Perform this Operation"
 * and because a rich-text image failure is an EXPRESSION error it did not
 * degrade to a missing picture — it took the ENTIRE watchlist down. A design
 * account never sees this; only a persona login exposes it (behavioural security
 * verification, appian-supplemental §3 — validation and a design-account render
 * both passed while both personas were broken).
 *
 * So if that application is deleted, re-imported, or has its security reset,
 * every SO screen dies for every analyst again. cons!SO_MARK_USE_LOGO is the
 * one-flip recovery: set it false and every screen falls back to the platform's
 * own snowflake icon instead of erroring. It is deliberately a constant, not an
 * auto-detect, because SAIL cannot ask "can this user read this document"
 * without throwing the very error we are avoiding.
 *
 * THE DURABLE FIX remains open and is a Designer step: upload the PNG into the
 * SO Artifacts folder (which already grants SO Users viewer) and repoint
 * cons!SO_SNOWFLAKE_LOGO at the copy, so the SO application owns its own asset.
 * Binary documents cannot be created over the Dev MCP (§1).
 *
 * The fallback is the platform icon "snowflake-o", NOT the U+2744 character —
 * the character marker was rejected at gate A and must not return. The icon is
 * colour- and size-controlled and reads as the same mark at a glance.
 */
a!localVariables(
  local!useLogo: a!defaultValue(cons!SO_MARK_USE_LOGO, false),
  local!show: a!defaultValue(ri!showWhen, true),

  if(
    local!useLogo,
    a!richTextImage(
      image: a!documentImage(
        document: cons!SO_SNOWFLAKE_LOGO,
        altText: "Live from Snowflake",
        caption: "Live from Snowflake"
      ),
      showWhen: local!show
    ),
    a!richTextIcon(
      icon: "snowflake-o",
      color: "#3E7396",
      altText: "Live from Snowflake",
      caption: "Live from Snowflake",
      showWhen: local!show
    )
  )
)
