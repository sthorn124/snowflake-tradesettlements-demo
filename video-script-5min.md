# Pre-Settlement Fail Prevention: 5-Minute Recorded Walkthrough

*Narration and screen cues for a single-take screen recording. Written 2026-10-22 from `demo-script-15min-client-awareness.md`, revised the same day to give the supervisor and analyst screens their own beats. Target length about 5:45; nobody watches a 15-minute recording.*

---

## Before recording (10 minutes)

- Demo Admin site, off camera: if the status line says "Loaded before today" or the hero case is already resolved, **Reset the demo**, then **Load the demo**. Wait 2 minutes, confirm 3 cases. Never click Load twice. The Demo Admin site is never shown in the recording.
- Three browser tabs, in this order: **Supervisor**, **Watchlist**, the hero case (**SAP GY / Diamond Trust**, trade `TRD9DEMO01`, found by name under Needs your action). Close the Demo Admin tab.
- Browser zoom 110 to 125 percent. Full-screen the browser window. Hide bookmarks bar and other tabs' notifications.
- Recorder: Loom, Zoom local recording, or macOS screen recording with the microphone on. Record the browser window only, 1080p. A headset mic or the laptop mic in a quiet room; no speaker-echo.
- Read the narration once out loud with the pages in front of you. Then record in one take. Trim the two Ask waits afterwards (Loom's trim or iMovie); everything else stays.

---

## 0:00 to 0:35 · Open

**Screen: Supervisor tab, top of page. No clicks. The Demo Admin site is setup only and never appears on camera; the first frame of the video is this page.**

> "This is a joint Appian and Snowflake demo for settlement operations at a bank. Every trade has to settle, usually the next day, and when it fails it costs real money. Most firms still find out on the day. Here, Snowflake predicts which trades will fail, and Appian turns each prediction into work: a case with an owner, a deadline and an audit trail. An AI agent handles the straightforward ones. People handle the ones that need judgment. And the data never leaves Snowflake."

## 0:35 to 1:50 · The supervisor's view (what the head of settlements sees)

**Screen: Supervisor tab. Cursor moves across the six KPI cards, then scroll to the Cutoff runway chart, then Analyst queues, then Escalations awaiting supervisor.**

> "This is the head of settlements at nine in the morning, across every desk. Six numbers along the top: predicted fails still open, value at risk in US dollars, how many sit inside the critical window, escalations waiting on a supervisor, what the agent resolved straight through today, and the penalties that avoided. Every number with the Snowflake mark is computed in Snowflake and read live. Nothing was copied into Appian; fifty thousand trades sit where they always sat.
>
> The runway chart is the next twelve hours, hour by hour: how much value settles in each hour and how much of it is still at risk. Below it, analyst queues: open work by who holds it, which is where a supervisor reassigns. And escalations awaiting supervisor: each one with the reason it escalated written out, and how long it has been waiting against a one-hour SLA."

**Screen: scroll to Ask across the book. Click "How do fail rates differ by asset class?" Keep recording; trim the wait in post.**

> "The supervisor can also ask the book a question in plain English. That goes to Snowflake Cortex, runs against the full history, and the answer comes back computed in Snowflake. Nobody wrote a report."

**Screen: the answer lands. Read one number from it.**

## 1:50 to 2:50 · The analyst's morning (what one desk sees)

**Screen: Watchlist tab, top of page. Cursor across the four KPI cards, then the Latest scoring batch band.**

> "Same application, the analyst's view. An analyst sees one desk, not the house: her four numbers are her desk's open fails, value at risk, what is inside the critical window, and what cleared straight through. The row-level security that scopes her to her desk is set once on the data, so every screen inherits it.
>
> The band is the overnight scoring batch. Fifteen trades came in. Most were cleared by Snowflake's scoring alone, so no case and no human. One was resolved by the AI agent. One escalated automatically. One is waiting for a person. Nobody walked in to fifteen trades. They walked in to one."

**Screen: Needs your action. Cursor down the columns: risk, cutoff countdown, auto-release score.**

> "Needs your action is her queue, sorted by time to cutoff. Each row carries the fail probability from Snowflake, the live countdown to cutoff, and the agent's auto-release score against the 80 it needs to act alone."

**Screen: scroll to Escalated, with supervisor. Point at the BATS LN / Horizon Securities row and its red Escalation text. Then Cleared this batch, collapsed, point at the summary line.**

> "This one escalated by policy, not by the AI's opinion. The broker confirmation is 26 hours late and there's less time than that to the cutoff. There's no fix inside the window, so the rules send it straight to a supervisor, every time. The AI advises. The rules decide what it's allowed to do on its own. And cleared this batch is everything that never needed a person."

## 2:50 to 4:20 · The hero case

**Screen: hero case tab. Scroll slowly: Trade & counterparty, the Counterparty card with Recent settlement fails, Timing, Agent assessment.**

> "This is the one that needed a person. 210,000 shares of SAP, 18.7 million euros, counterparty Diamond Trust. Snowflake put the chance of this failing at 83 percent.
>
> One page: the trade and the prediction, from Snowflake. The counterparty's recent fails, from Snowflake's history. The time left to cutoff. And the agent's assessment: it worked out a fix, but its score is around 60, and it only acts on its own above 80. So it held the case for a human and laid out its reasoning. That gate is the firm's, not the AI's."

**Screen: scroll to Ask about this case, click "How does Diamond Trust compare with the book?" Keep recording; trim the wait in post.**

> "Before deciding, the analyst can ask about this case in plain English. That goes to Snowflake Cortex, runs against the full history, and comes back live."

**Screen: the answer lands. Read the two fail rates off the screen.**

> "Diamond Trust fails [N] percent of the time against [N] for the rest of the book, mostly for this same reason. The flag is credible. The analyst accepts the agent's proposal, a partial release: Diamond Trust delivers the shares it has today, the rest follows, and most of the trade settles on time."

## 4:20 to 5:05 · The decision and the record

**Screen: scroll to the top. Click Record Disposition. Choose Settled - Partial Release. Leave the note empty. Submit. Scroll to Activity and move the cursor down the entries.**

> "Record the disposition. Done. And here's the record: the prediction, what the agent recommended and why it held, and what the analyst decided, each with a time and a name. Nobody assembles this afterwards. That's the audit trail compliance asks for, written as the work happened."

## 5:05 to 5:45 · Close

**Screen: Supervisor tab, or stay on the case.**

> "Three things to take away. The data never moved: Snowflake predicted and answered, Appian did the work on top of it, live. The AI was gated: it acted alone only above a threshold the firm set, policy overrode it when the window was gone, and every decision is on the record. And this isn't about settlements. Anywhere you have scores sitting in a data platform and people acting on them by hand, this is the shape of the answer."

---

## After recording

- Trim the two Ask waits to about three seconds each. Leave everything else.
- Demo Admin: **Reset the demo**, so the hero is back in Awaiting review for the next presenter.
- If the agent's score read something other than "around 60," say what was on screen; it varies between 60 and 66 and is always below 80.
