# Pre-Settlement Fail Prevention: 15-Minute Client Awareness Demo

*Presenter script for a first-time demoer. Written 2026-10-15 for the NAIC awareness session. Built from `talk-track-10min-internal.md`; every click and label below was checked against the deployed screens on that date.*

**Scott fills in before handing this over:**

- Environment URL: `________________________`
- Presenter account: `________________________` (must be in both `SO Supervisors` and `SO Demo Admins`)

---

## What you are showing, in one paragraph

This is a joint Appian and Snowflake demo. The example is a settlements desk at a bank: Snowflake predicts which trades will fail to settle, Appian turns each prediction into a piece of governed work before the cutoff, and an AI agent handles the easy ones while people handle the hard ones. The client is not a settlements desk, and you do not need to pretend they are. The point of the demo is the pattern: the data never leaves the data platform, AI does the first pass, and every AI decision is gated and recorded. You will say that at the start and again at the end.

You do not need to explain how anything is built. If someone asks a technical question you cannot answer, say "I'll get you a precise answer from our team" and move on.

---

## Before the day

1. **Get access.** You need an account that is in two groups: `SO Supervisors` and `SO Demo Admins`. Scott sets this up. Test it by opening both links below. If the Demo Admin page shows a single card telling you to request a group, you are missing one; tell Scott.
2. **The two sites.**
   - Settlement Operations (the demo): `<environment URL>/suite/sites/settlement-ops`. Three pages: Watchlist, Cases, Supervisor.
   - Demo Admin (setup only, never shown to the client): `<environment URL>/suite/sites/settlement-ops-admin`.
3. **Do one full dry run at least a day before**, including the setup steps and the Reset at the end. Recording the disposition in Beat 4 resolves the hero case, so after a rehearsal you must Reset and Load again or the case will already be closed when you present.
4. **Read the Watchlist and the hero case once on your own**, so the screens are familiar before anyone is watching.

---

## 30 minutes before: setup

**Step 1. Load the demo data.**

- Open the Demo Admin site. Read the status line at the top.
- If it says **"No demo data loaded."** click **Load the demo**.
- If it says **"Loaded before today. Reset, then Load for fresh dates."** click **Reset the demo**, wait until the status line changes, then click **Load the demo**.
- If it says **"Demo loaded"** with today's date and you have not touched the hero case since, you are already set. If you rehearsed today and resolved the hero, Reset then Load.
- Wait about 2 minutes. The console should report 15 demo trades and 3 cases loaded now.
- **Never click Load twice.** A second click re-stamps the scoring time and the screens stop matching the story.

**Step 2. Open three browser tabs on the Settlement Operations site.**

- **Tab A:** the **Supervisor** page.
- **Tab B:** the **Watchlist** page.
- **Tab C:** the hero case. On the Watchlist, under **Needs your action**, find the row for **SAP GY** with counterparty **Diamond Trust** (trade id `TRD9DEMO01`). It may not be the top row; its position moves with the time of day, so find it by name. Click it to open the case and leave this tab open.

**Step 3. Tidy up.**

- Close the Demo Admin tab. The client should never see it.
- Zoom the browser to 110 to 125 percent so the screens read well on a shared screen.
- Put Tab A on screen. Share only the browser window.

---

## The demo (about 12 minutes plus questions)

Each beat tells you which tab, what to click, and what to say. The quoted lines are a guide; say them in your own words.

### Beat 1: Why this exists (0:00 to 2:00)

**Tab A, Supervisor page. Don't click anything yet.**

> "What I'm going to show you is a joint demo from Appian and Snowflake. The example is a settlements operation at a bank. Every trade a bank does has to settle, usually the next day, and when settlement fails it costs real money and real client trust. Most firms still find out a trade failed on the day it was supposed to settle.
>
> This demo shows a different way. Snowflake looks at every pending trade and predicts which ones will fail. Appian turns those predictions into work: cases with owners, deadlines and an audit trail. An AI agent handles the straightforward ones. People handle the ones that need judgment. And the data never leaves Snowflake to make any of that happen.
>
> The settlements example isn't your business. The pattern is what matters: predictions you already have, or could have, becoming governed action."

*If you know NAIC runs on Snowflake, add: "and because you're on Snowflake, this is exactly the shape it would take for you." If you don't know, leave it out.*

### Beat 2: The supervisor's view (2:00 to 4:30)

**Still Tab A.**

Point with your cursor as you go. Don't click.

- The small **Snowflake mark** next to numbers across the page.
- **Value at risk** at the top.
- **Escalations awaiting action** (one case will be there).
- **Cutoff runway, next 12 hours** (the chart).

> "This is what the head of settlements sees in the morning. Every number with the Snowflake mark is computed in Snowflake and read live. Nothing was copied into Appian. There are 50,000 trades behind this page and they're sitting where they always sat.
>
> Overnight, Snowflake scored every pending trade. Appian took the risky ones and made them cases, each with an owner and a cutoff. A prediction on its own is a row in a table. The moment it becomes a case, somebody is accountable for it."

**Optional, only if the dry run went smoothly:** click the question **"How do fail rates differ by asset class?"** under **Ask across the book**. It takes 15 to 35 seconds. While it runs:

> "The supervisor can also ask questions in plain English. This goes to Snowflake, runs against the full history, and comes back as an answer. Nobody wrote a report."

When the answer lands, read one number from it out loud. If it shows an error, say "live call, let me try again," click once more, and if it fails again move on. Nothing else depends on it.

### Beat 3: The analyst's morning (4:30 to 7:00)

**Tab B, Watchlist page.**

Point at the **Latest scoring batch** band near the top.

> "This is the analyst's screen. Fifteen trades came in overnight. Most were cleared by Snowflake's scoring alone, so no case and no human. One was resolved by the AI agent on its own. One was escalated automatically. One is waiting for a person. Nobody walked in to fifteen trades. They walked in to one."

Scroll to **Escalated, with supervisor**. Point at the row (BATS LN, Horizon Securities) and the red text in its **Escalation** column.

> "This one escalated by policy, not by the AI's opinion. The broker confirmation is 26 hours late and there's less time than that to the cutoff. There's no fix inside the window, so the rules send it straight to a supervisor, every time. The AI advises. The rules decide what it's allowed to do on its own."

Scroll to **Cleared this batch**. It is collapsed; point at its summary line (how many cleared by Snowflake scoring) without expanding it. Then go to Tab C.

### Beat 4: The hero case (7:00 to 11:00)

**Tab C, the SAP GY / Diamond Trust case.**

> "This is the one that needed a person. 210,000 shares of SAP, 18.7 million euros, with a counterparty called Diamond Trust. Snowflake put the chance of this failing at 83 percent."

Scroll slowly down the page. Point at each section as you name it.

- **Trade & counterparty** and the **Counterparty** card with **Recent settlement fails** (the line says *Live from Snowflake*).
- **Timing** with the time remaining to cutoff.
- **Agent assessment**: the agent's reasoning and the line **"auto-release score NN, releases at 80."** The score will read somewhere around 60 to 66. Say "around 60."

> "Look at what's on this one page. The trade and the prediction, from Snowflake. The counterparty's recent fails, from Snowflake's settlement history. The time left to the cutoff. And the agent's assessment: it worked out a fix, but its score is around 60 and the rule is it only acts on its own above 80. So it held the case for a human and laid out its reasoning. That gate is set by the firm, not by the AI."

Scroll to **Ask about this case**. Click **"How does Diamond Trust compare with the book?"** It takes 15 to 35 seconds. While it runs:

> "Before deciding, the analyst can ask about this specific case. Same thing: Snowflake, the full history, answered live."

When the answer lands, read the two fail rates off the screen (Diamond Trust's and the rest of the book's). Don't quote numbers from memory; read what's there.

> "So Diamond Trust fails a lot more often than the book, and mostly for this same reason. The flag is credible. The analyst accepts the agent's proposal: a partial release. Diamond Trust delivers the shares it has today, the rest follows, and most of the trade settles on time instead of all of it failing."

Now record the decision. **Scroll back to the top of the case.**

1. In the case header, click **Record Disposition**.
2. In the **Disposition** dropdown choose **Settled - Partial Release**.
3. Leave **Resolution note** empty. (Do not type a note. A known display issue shows the note under the agent's name, which contradicts the point you just made.)
4. Click **Record Disposition** to submit.

Scroll down to **Activity**.

> "Done. And here's the record: the prediction, what the agent recommended and why it held, and what the analyst decided, each with a time and a name. Nobody assembles this afterwards. It's the audit trail compliance asks for, written as the work happened."

Point at the sequence of entries. Don't read them word for word; some entries show internal codes.

### Beat 5: What this means for you (11:00 to 13:00)

**Any tab. Stop scrolling.**

> "Three things to take away.
>
> First, the data never moved. Snowflake did the predicting and answered the questions. Appian did the work on top of it, live, with no copy and no sync.
>
> Second, the AI was gated. It acted on its own only when it was confident enough, the threshold was the firm's, policy overrode it when the window was gone, and every decision is on the record. That's what model risk and compliance teams ask about first.
>
> Third, this isn't about settlements. Any place you have predictions or scores sitting in a data platform and people acting on them by hand, this is the shape of the answer: the insight becomes a governed piece of work the moment it arrives.
>
> Happy to take questions, and we can set up a working session on what this would look like on your data."

---

## Questions you may get, and short answers

**Is the data copied into Appian?** No. Appian reads it from Snowflake when the screen loads. The Snowflake mark shows exactly which numbers came from there.

**Is the AI deciding on its own?** Only when its score clears a threshold the firm sets. Below that it hands the case to a person with its reasoning. And policy rules can override it entirely, which is what the escalated case showed.

**What is Snowflake doing and what is Appian doing?** Snowflake stores the data, scores the trades, and answers the plain-English questions. Appian makes cases, assigns owners, runs the agent and the rules, and keeps the audit trail.

**How is the prediction model built?** Say: "The scoring runs inside Snowflake against the trade history. I'll have our team walk you through the model itself." Don't describe the model.

**Could this work on our data?** Yes. The pattern works with any data that already lives in Snowflake, or any data platform Appian can read live. The settlements example is one use case built on it.

**Why not build all of this in Snowflake?** Snowflake can predict and answer questions. It has no cases, owners, deadlines, escalations or record of who decided what. Appian is that layer, running on the Snowflake data without moving it.

**Is this a product or a demo?** It's a demo built on the standard Appian platform and a standard Snowflake account. Nothing custom was built to connect them.

---

## If something goes wrong

- **An Ask shows an amber error.** Say "live call, let me ask again" and click the question once more. If it fails twice, move on; nothing else depends on it.
- **An Ask takes longer than 30 seconds.** Keep talking. They have never gone past about 36 seconds.
- **The agent's score on the hero is different from your rehearsal.** It's a live agent. It will be somewhere in the sixties and still below 80, which is all that matters.
- **The hero case isn't in Needs your action.** It was already resolved, probably in a rehearsal. Go to Demo Admin, Reset the demo, then Load the demo, wait 2 minutes, and re-open the three tabs. This takes about 4 minutes, so check before the meeting starts.
- **Record Disposition isn't in the case header.** The case is already resolved. Same fix as above, or skip the click and talk through the Activity panel instead.
- **A screen looks empty or shows zeros.** Reload the page once. If it stays empty, say "let me come back to that" and move to the next beat.

---

## After the demo

Open the Demo Admin site and click **Reset the demo**. Wait for the status line to confirm. The next presenter starts clean.
