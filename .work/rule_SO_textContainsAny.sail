/*
 * SO_textContainsAny — does haystack contain ANY of needles, case-insensitively.
 *
 * search() CANNOT be used to test substring presence (§4): it does not return a
 * usable "not found" signal in this context. The working form is the
 * len(substitute(...)) identity — removing the needle shortens the string only
 * if the needle was there — and this rule exists so that form is written once
 * rather than copied per marker at every call site.
 *
 * Empty needles are ignored rather than matching everything: substitute() with
 * an empty search string would return the haystack unchanged, which reads as
 * "no match", but relying on that accident would be fragile.
 */
a!localVariables(
  local!hay: lower(a!defaultValue(ri!haystack, "")),
  or(
    a!forEach(
      items: a!defaultValue(ri!needles, {}),
      expression: a!localVariables(
        local!needle: lower(a!defaultValue(fv!item, "")),
        if(
          or(local!needle = "", local!hay = ""),
          false,
          len(substitute(local!hay, local!needle, "")) < len(local!hay)
        )
      )
    )
  )
)
