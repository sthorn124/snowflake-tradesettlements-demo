/*
 * SO_fxToUsd — converts a notional to USD so the house view can add up.
 *
 * ============ READ THIS BEFORE TRUSTING A NUMBER THAT CAME THROUGH HERE ============
 * THE RATES BELOW ARE INDICATIVE STATIC CONSTANTS. THEY ARE NOT A MARKET FEED,
 * NOT A RATE OF RECORD, AND NOT REFRESHED. There is no FX source anywhere in
 * this demo: TRADES carries a notional and a currency and nothing carries a
 * rate, so a cross-currency total cannot be computed from the data alone.
 *
 * The supervisor screen needs one house number — "value at risk across all
 * desks" is meaningless per-currency when the book runs EUR, GBP, JPY and CHF
 * at once — so the choice was between a labelled approximation and no house
 * view. The approximation is taken, and it is labelled everywhere it surfaces:
 * every figure derived from this rule renders with "USD eq." and carries a
 * tooltip naming the basis. That is the honest form of this compromise. What
 * would NOT be honest is a bare "486.2M" with no unit and no provenance.
 *
 * The mockup asserts "USD eq." on exactly these figures, so this is the mockup's
 * own intent rather than an invention of the build.
 *
 * PHASE 5 / PRODUCTION: replace with a rate lookup — a small Snowflake table
 * joined at query time, or a daily rate constant set by the packet builder. When
 * that lands, this rule keeps its signature and only its body changes, so no
 * screen moves.
 *
 * A NULL OR UNKNOWN CURRENCY RETURNS THE AMOUNT UNCONVERTED, deliberately: a
 * missing rate must not silently zero a position out of the house total. It
 * overstates a soft currency and understates nothing, which is the safe
 * direction for a risk figure.
 */
a!localVariables(
  local!amount: todecimal(a!defaultValue(ri!amount, 0)),
  local!ccy: upper(trim(a!defaultValue(ri!currency, ""))),
  local!rate: a!match(
    value: local!ccy,
    equals: "USD", then: 1.0,
    equals: "EUR", then: 1.08,
    equals: "GBP", then: 1.27,
    equals: "CHF", then: 1.13,
    equals: "JPY", then: 0.0067,
    equals: "AUD", then: 0.66,
    equals: "CAD", then: 0.73,
    equals: "SEK", then: 0.095,
    equals: "HKD", then: 0.128,
    equals: "SGD", then: 0.74,
    default: 1.0
  ),
  local!amount * local!rate
)
