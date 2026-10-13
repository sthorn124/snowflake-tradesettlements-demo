# Pre-Settlement Fail Prevention — 10-Minute Internal Talk Track

*Copied into the repo 2026-10-13 from the live Claude Doc (https://claude.ai/artifact/Lmv1Kskdczm8JQnxVpboXo), the editable original. This is the 10-minute internal version written 2026-09-25 for the AE/SC session; the full one-hour client demo script is still unwritten (see TODO.md, Phase 5 Part C).*

Sep 25, 2026 · @Scott

## Before the session (5 minutes)

Log in with your own account, not sam.supervisor. You're in both groups, so you see all three tabs and the admin site with no switching; sam can't open the admin site.

- Admin site: if the console shows the amber "Loaded before today" line, press Reset, then Load. If it says "No demo data loaded," press Load. Wait about 2 minutes, confirm 3 cases. Never press Load twice.
- Open three tabs: Supervisor, Watchlist, and the hero case (TRD9DEMO01, SAP GY).

Recording the disposition resolves the hero case. If you rehearse it beforehand, press Reset then Load afterwards so the hero is back in Awaiting review. Do the same after the session, so the next presenter starts clean.

## 0:00–1:30 · Why this exists

*Supervisor tab on screen, don't click yet.*

> "Every one of our capital-markets accounts has the same problem. Settlement fails cost real money: CSDR penalties, funding costs, and client trust. T+1 shrank the window to fix them from a day to a few hours. And most firms still find out a trade failed on settlement day.
>
> A lot of those same firms have spent millions on Snowflake. This demo is the answer to 'what does Appian do for a Snowflake customer.' The pitch line: your Snowflake investment already knows which trades will fail. Appian is the layer that does something about it before the cutoff."

*Then zoom out to the platform (adds about 40 seconds):*

> "One more thing before I show it, because it matters more than the use case. Settlements is just the first one we built. Underneath it is a pattern that works for anything a customer already has in Snowflake.
>
> Appian reads Snowflake data where it sits, live, with no sync. It calls Snowflake's models and Cortex from inside a process or a screen. It can run Snowflake jobs from a workflow step. And it wraps all of it in cases, security, AI gates and audit, while the data stays under Snowflake's governance.
>
> So swap the data and the same build becomes AML alert triage, KYC refresh, collateral calls, credit limit breaches or reconciliation breaks. Any time a customer says 'our data team built a model and nobody acts on it,' that's this conversation."

## 1:30–3:30 · The supervisor's house view

*Point at the Snowflake marks, the value at risk, the escalations card.*

> "This is the head of settlements at 9am. Every number with the Snowflake mark is computed in Snowflake and read live. No copy, no sync, no nightly extract. Appian reads 50,000 trades where they sit.
>
> Snowflake's ML model scored every pending trade overnight. Appian turned the risky ones into cases with owners, cutoffs and SLAs. A prediction on its own is just a row in a table. The moment it becomes a case, someone is accountable for it."

*Click* **"How do fail rates differ by asset class?"** *(about 15 seconds; talk while it spins; skip this Ask if you're short on time, the hero case has its own):*

> "And the supervisor can ask questions in plain English. This goes to Snowflake Cortex, runs against the full history, and the answer comes back computed in Snowflake. Nobody wrote a report or a query."

*When it lands, read one number from it.*

## 3:30–6:00 · The analyst's morning

*Watchlist tab. Point at the latest scoring batch band.*

> "Here's the part that lands with ops people. Fifteen trades came in overnight. Most were cleared by Snowflake scoring alone, so no case, no human. One was resolved by the AI agent. One escalated automatically. And one is waiting for a human. Nobody walked in to fifteen trades to check. They walked in to one."

*Point at the escalated queue, the "window breached" row:*

> "This one escalated by policy, not by the AI's judgment. The broker confirmation is 26 hours late and there's less time than that to cutoff. There's no fix inside the window, so it goes straight to a supervisor, every time. The AI advises, and the rules decide what it's allowed to do on its own."

## 6:00–8:30 · The hero case

*Hero tab (TRD9DEMO01).*

> "This is the one that needed a human. 18.7 million euros of SAP, Diamond Trust as the counterparty, 83% predicted fail. The agent has already worked out a fix, but its confidence is around 0.6, and the rule is it only acts on its own above 0.8. So it holds the case for the analyst, with its reasoning laid out."

*Scroll the case slowly.*

> "Look at what's on this one screen. The trade and its fail prediction, from Snowflake. The counterparty's recent fails, from Snowflake's settlement history. The agent's recommendation and its reasoning. The time left to cutoff. Today an analyst pulls this together from several systems and a spreadsheet. Here it's one page, and none of it was copied to build it."

*Click* **"How does Diamond Trust compare with the book?"** *(about 25 seconds; talk while it spins):*

> "The analyst can ask about this specific case before she decides. Same thing: Cortex, the full history, answered in Snowflake."

*When it lands:*

> "Diamond Trust fails about 22% of the time, against under 13% for the rest of the book, and most of its recent fails were for this exact reason. So the flag is credible. She takes the partial release the agent proposed: Diamond Trust delivers the shares it has today, the rest follows, and most of the trade settles on time instead of all of it failing. Any penalty only applies to the part that's late."

*Click* **Record Disposition** *→* **Settled - Partial Release** *→ submit. Then open the case history.*

> "Done. And look at the history: the prediction, what the agent recommended, why it held, and what she decided, each with a time and a name. Nobody assembles that afterwards. That's the audit trail compliance asks for, written as the work happened."

## 8:30–10:00 · Why you should care

*Back to any screen.*

> "Three reasons this matters to you.
>
> It's a Snowflake story where we're the hero. Snowflake produces the insight, but it has no concept of work: no case, no owner, no deadline, no audit. We're how the insight becomes an outcome, and the data never moves to make that happen.
>
> It's a governance story. Every AI decision is gated. That's what model-risk and compliance ask about first, and we answer it on screen.
>
> And it's reusable. One button loads it, one button resets it, and it runs the same way every time. If you have a capital-markets account on Snowflake, especially one on T+1 or dealing with CSDR penalties, come find me and we'll run it for them."

*Optional closer if there's a minute left:*

> "Coming next: the governance act, with evaluation results and AI cost tracked by desk, and a live late trade that goes from booked to worked in about a minute."

## How the demo uses Snowflake

Snowflake is doing real work on every screen, and the Snowflake mark shows the audience exactly where. Use these if an AE or SC asks "what is Snowflake actually doing here?"

| On screen | What Snowflake does | Why it matters |
| --- | --- | --- |
| Every trade, counterparty, instrument and settlement-history row | Appian reads the 50,000-trade book straight from Snowflake tables at query time. Nothing is synced or copied into Appian. | One copy of the data. No pipeline to build, no reconciliation, and Snowflake's governance stays intact. |
| Fail risk % and predicted fail reason on every trade | Snowflake's ML model scores each pending trade and writes the prediction back to a Snowflake table. | Firms learn a trade will fail at trade date, not on settlement day. |
| "Cleared by Snowflake scoring" in the latest batch | Low-risk trades are cleared by the score alone, so they never become cases. | Most volume never reaches a human. People only work what needs judgment. |
| Both Ask panels | The question goes to Snowflake Cortex: an AI agent working over a semantic model of the settlement data. Cortex writes and runs the query in Snowflake across all 50,000 trades. | Plain-English analytics inside the workflow. No report request, no SQL, no extract. |
| Ask answers after the demo is loaded | Cortex's counts include the three demo trades the moment they load (one more High, two more Critical than the baseline). | Proof the answer is live against the book as it is right now, not a cached report. |
| Load and Reset on the admin console | Appian calls Snowflake stored procedures that insert or remove the 15 demo trades. | Appian orchestrates Snowflake, not just reads it. The same pattern drives any Snowflake process from a workflow step. |

The one-sentence version for the room: Snowflake predicts and answers, Appian acts and governs, and the data never leaves Snowflake.

## The value

**For the customer**

- **A return on the Snowflake money they already spent.** Their predictions stop being dashboards and start preventing fails.
- **No new data platform.** No copy of the data, no pipeline, no sync to maintain. Snowflake stays the governed source.
- **Fails caught before cutoff.** Fewer CSDR penalties, lower funding costs, fewer buy-ins, and fewer awkward client calls.
- **Analyst time goes where it matters.** Most trades clear without a human, so analysts work the few that need judgment.
- **An audit trail written as the work happens.** Every AI decision is gated, and every action is recorded, which is what model-risk and compliance ask for.

**For Appian sellers**

- **It turns "we're a Snowflake shop" from an objection into the reason to buy.** We complement their data investment instead of competing with it.
- **It opens capital-markets operations** (settlements, middle office) at accounts that already run Snowflake.
- **Discovery questions that surface it:** Are you on Snowflake? What's your settlement fail rate since T+1? What are you paying in CSDR penalties? Today, how do you find out a trade is going to fail?

**If someone asks "why not just build it in Snowflake?"**

Snowflake can predict and answer questions, but it has no cases, owners, deadlines, escalations, approvals, or record of who did what. Building that in Snowflake means building a workflow platform from scratch. Appian is that platform, running on their Snowflake data without moving it.

## If something goes wrong

- An Ask answer shows a plain amber error: say "live call, let me ask again" and click the chip once more.
- An Ask takes longer than 30 seconds: keep talking; they've never exceeded about 36 seconds in testing.
- The agent's confidence on the hero reads 0.62 one day and 0.65 the next. It's a live agent, and it's still below the gate.
