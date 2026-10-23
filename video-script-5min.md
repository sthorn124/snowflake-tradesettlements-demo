# Pre-Settlement Fail Prevention: 5-Minute Recorded Walkthrough

*Narration and screen cues for a single-take screen recording. Written 2026-10-22 from `demo-script-15min-client-awareness.md`. Target length 5:00 to 5:30; nobody watches a 15-minute recording.*

---

## Before recording (10 minutes)

- Demo Admin site: if the status line says "Loaded before today" or the hero case is already resolved, **Reset the demo**, then **Load the demo**. Wait 2 minutes, confirm 3 cases. Never click Load twice.
- Three browser tabs, in this order: **Supervisor**, **Watchlist**, the hero case (**SAP GY / Diamond Trust**, trade `TRD9DEMO01`, found by name under Needs your action). Close the Demo Admin tab.
- Browser zoom 110 to 125 percent. Full-screen the browser window. Hide bookmarks bar and other tabs' notifications.
- Recorder: Loom, Zoom local recording, or macOS screen recording with the microphone on. Record the browser window only, 1080p. A headset mic or the laptop mic in a quiet room; no speaker-echo.
- Read the narration once out loud with the pages in front of you. Then record in one take. Trim the two Ask waits afterwards (Loom's trim or iMovie); everything else stays.

---

## 0:00 to 0:35 · Open

**Screen: Supervisor tab. No clicks.**

> "This is a joint Appian and Snowflake demo for settlement operations at a bank. Every trade has to settle, usually the next day, and when it fails it costs real money. Most firms still find out on the day. Here, Snowflake predicts which trades will fail, and Appian turns each prediction into work: a case with an owner, a deadline and an audit trail. An AI agent handles the straightforward ones. People handle the ones that need judgment. And the data never leaves Snowflake."

## 0:35 to 1:20 · The supervisor's view

**Screen: Supervisor tab. Cursor moves to the Snowflake marks, Value at risk, Escalations awaiting action, the Cutoff runway chart.**

> "This is what the head of settlements sees in the morning. Every number with the Snowflake mark is computed in Snowflake and read live. Nothing was copied into Appian. Fifty thousand trades sit where they always sat. Overnight, Snowflake scored every pending trade. Appian took the risky ones and made them cases, each with an owner and a cutoff. A prediction on its own is a row in a table. The moment it becomes a case, somebody is accountable for it."

## 1:20 to 2:05 · The analyst's morning

**Screen: Watchlist tab. Cursor on the Latest scoring batch band, then scroll to Escalated, with supervisor and point at the BATS LN / Horizon Securities row and its red Escalation text.**

> "Fifteen trades came in overnight. Most were cleared by Snowflake's scoring alone, so no case and no human. One was resolved by the AI agent. One escalated automatically. One is waiting for a person. Nobody walked in to fifteen trades. They walked in to one.
>
> This one escalated by policy, not by the AI's opinion. The broker confirmation is 26 hours late and there's less time than that to the cutoff. There's no fix inside the window, so the rules send it straight to a supervisor, every time. The AI advises. The rules decide what it's allowed to do on its own."

## 2:05 to 3:35 · The hero case

**Screen: hero case tab. Scroll slowly: Trade & counterparty, the Counterparty card with Recent settlement fails, Timing, Agent assessment.**

> "This is the one that needed a person. 210,000 shares of SAP, 18.7 million euros, counterparty Diamond Trust. Snowflake put the chance of this failing at 83 percent.
>
> One page: the trade and the prediction, from Snowflake. The counterparty's recent fails, from Snowflake's history. The time left to cutoff. And the agent's assessment: it worked out a fix, but its score is around 60, and it only acts on its own above 80. So it held the case for a human and laid out its reasoning. That gate is the firm's, not the AI's."

**Screen: scroll to Ask about this case, click "How does Diamond Trust compare with the book?" Keep recording; trim the wait in post.**

> "Before deciding, the analyst can ask about this case in plain English. That goes to Snowflake Cortex, runs against the full history, and comes back live."

**Screen: the answer lands. Read the two fail rates off the screen.**

> "Diamond Trust fails [N] percent of the time against [N] for the rest of the book, mostly for this same reason. The flag is credible. The analyst accepts the agent's proposal, a partial release: Diamond Trust delivers the shares it has today, the rest follows, and most of the trade settles on time."

## 3:35 to 4:20 · The decision and the record

**Screen: scroll to the top. Click Record Disposition. Choose Settled - Partial Release. Leave the note empty. Submit. Scroll to Activity and move the cursor down the entries.**

> "Record the disposition. Done. And here's the record: the prediction, what the agent recommended and why it held, and what the analyst decided, each with a time and a name. Nobody assembles this afterwards. That's the audit trail compliance asks for, written as the work happened."

## 4:20 to 5:00 · Close

**Screen: Supervisor tab, or stay on the case.**

> "Three things to take away. The data never moved: Snowflake predicted and answered, Appian did the work on top of it, live. The AI was gated: it acted alone only above a threshold the firm set, policy overrode it when the window was gone, and every decision is on the record. And this isn't about settlements. Anywhere you have scores sitting in a data platform and people acting on them by hand, this is the shape of the answer."

---

## After recording

- Trim the two Ask waits to about three seconds each. Leave everything else.
- Demo Admin: **Reset the demo**, so the hero is back in Awaiting review for the next presenter.
- If the agent's score read something other than "around 60," say what was on screen; it varies between 60 and 66 and is always below 80.
