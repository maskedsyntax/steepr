# Steepr: Diagnosis & Revenue Plan

## What the Numbers Say

As of launch (v1.0):
- **518 impressions** total in the App Store
- **57 product page views**
- **9 downloads**
- **0 paying users**

This is a product, positioning, and distribution problem — all three, compounding each other. The app is well-built. The market isn't finding it, and even those who do aren't compelled to pay.

---

## Root Cause Diagnosis

### 1. The App Is Invisible (Primary Problem)

518 impressions is near-zero for a launched app. A healthy indie app sees thousands of impressions per day from organic search alone within weeks of launch.

**Why:**
- Zero ratings or reviews → App Store algorithm treats the app as unproven and doesn't surface it
- Keywords target tea *types* (`matcha,chai,oolong`) not *search intent* (`tea timer`, `steep timer`, `brew timer`)
- No external traffic (backlinks, press, social) to signal relevance to Apple's algorithm
- Reddit posts and DMs drive awareness, but without a compelling hook, awareness doesn't convert

### 2. The Pro Value Is Too Thin

The $5.99 unlock offers: unlimited custom teas, iCloud sync, advanced haptics, 2 extra sounds. For most users:
- 8 built-in presets covers 90% of their teas → they'll never hit the 3 custom cap
- iCloud sync is a nice-to-have, not a must-have for a timer app
- Haptic strength and sound choice are not a reason to pay

The problem isn't the price — $5.99 is fair. The problem is that users can't *feel* the gap between free and Pro.

### 3. Brewing Precision Has a Small Activist Audience

Most tea drinkers (even enthusiasts) don't have a felt pain with native timers. "Set a 3-minute timer" already works fine for them. The users who *need* Steepr — people who brew multiple teas daily, care about °C precision, re-steep, track their brews — are a small segment, and they're not browsing the App Store looking for a solution.

### 4. No Habit Loop → No Upgrade Pressure

After the first few sessions, nothing pulls the user back or toward Pro. The app is passive — it waits for you to open it. There's no history, no streaks, no journal, no data that gets more valuable over time.

---

## The Plan

### Phase 1: Fix ASO (Immediate — 1–2 days, no code)

This is the highest-leverage action. More impressions → more downloads → more paying users. Nothing else matters if nobody sees the app.

**Keywords — replace the current set:**
- Remove: `matcha,chai,oolong,green,black,white,puerh,herbal,brew,steep,kettle,infuser,looseleaf,siri,widget`
- Use: `tea timer,steep timer,brew timer,tea clock,matcha timer,herbal timer,tea reminder,brewing guide,tea alarm,loose leaf`
- Rationale: rank for *what people type when they have the problem*, not the product category

**Subtitle:**
- Current: "Tea Timer & Brewing Presets"
- Better: "Steep Timer with Watch App" — hits a concrete search query, highlights the real differentiator

**Description (first 3 lines matter most — only those show before "more"):**
- Current: "Master the art of tea." (vague)
- Better: "Pick a tea. Tap start. Steepr counts down the perfect steep time and alerts you when it's done — on your iPhone or Apple Watch." (concrete, scannable, includes keywords)

**Screenshot reorder:**
- Frame 1: Show the full flow — tea list → tap → timer starts (not a raw countdown clock)
- Frame 2: Apple Watch screen (clearest differentiator vs. native timer)
- Move the Pro/paywall screenshot to last position — leading with a paywall is off-putting

**Category:** Keep Food & Drink as primary; consider Utilities as secondary for broader surfacing.

**Get 10–15 ratings immediately:**
- Ask friends, family, beta users explicitly to leave a rating after downloading
- 10+ ratings moves the app out of "no data" territory in Apple's algorithm

---

### Phase 2: Make Pro Worth Paying For (1–2 weeks of code)

The free tier needs to create *desire* for Pro, not satisfaction. Add features that deepen engagement and make the upgrade obvious.

**Re-steep Support (already planned for v1.1 — highest priority)**
- This is the single highest-value feature for serious tea drinkers
- Pu-erh, oolong, and green teas are re-steeped 3–7 times with increasing durations
- Free: re-steep current tea manually (one tap, same timer again)
- Pro: full re-steep sequences with auto-increment timing per tea type
- This gives Pro a *workflow* reason, not just a storage reason

**Brew Journal (tasting notes + ratings)**
- After timer completes, prompt: "How was it? ★★★★★ | Add a note"
- Free: last 5 entries visible
- Pro: full unlimited history with notes, searchable
- Creates *data* that gets more valuable over time — and is lost if you don't upgrade

**Caffeine Daily Total (free feature — retention hook)**
- The data model already has `caffeineMilligrams` on every tea
- Show "Today: 120mg from 3 brews" on the brew tab
- No gating needed — health-conscious users will open the app every time they brew just to track this

**Better paywall triggers:**
- Current: paywall only shows when adding the 4th custom tea (rare trigger)
- Add: soft paywall nudge after 7th brew session ("You're a real tea drinker. Steepr Pro was made for you.")
- Add: passive nudge in Settings → About after 14 days of use

---

### Phase 3: Community & Distribution (Ongoing)

Reddit didn't work because posts feel promotional and text-only content doesn't demonstrate the app. What works:

**Short-form video (highest ROI, zero cost):**
- Record a 30-second screen recording: open app → tap tea → timer starts → Live Activity → Watch haptic on completion
- Post to r/tea, r/teaude, r/apple, r/applewatch with no pitch — just show it working beautifully
- Let comments ask "what app is this?" — that's organic
- Same video works on Instagram Reels and TikTok with "my morning tea routine" framing

**Pitch bloggers and newsletters:**
- "Best iPhone apps for tea lovers" roundups rank well and drive App Store search
- Target: tea blogs, MacStories, AppAdvice, productivity newsletters
- Offer a free Pro code for an honest mention

**Leverage the Watch angle specifically:**
- Almost no apps have a well-designed native watchOS tea timer
- r/applewatch is underserved and enthusiastic about useful watch apps
- This is a better audience than r/tea for distribution

**App Store promo code giveaways:**
- Post 10 Pro codes in tea subreddits in exchange for honest reviews
- "Giving away 10 Pro codes — reply and I'll DM you one, just leave an App Store review if you like it"
- This is fully within App Store guidelines

---

### Phase 4: Remove Purchase Friction (1–3 days of code)

**Add a 7-day Pro trial:**
- Users experience unlimited teas, iCloud sync, all sounds/haptics for 7 days free
- After trial, they're downgraded — and now they *feel* the loss
- Loss aversion is far more effective than showing a paywall upfront
- StoreKit 2 supports introductory offers on non-consumables

**Keep the one-time purchase model:**
- "One-time purchase, no subscription" is a genuine differentiator and marketing asset
- Tea communities and indie app buyers respond strongly to this framing
- It's a feature, not a constraint — don't touch it

---

### Phase 5: Expand the Addressable Market (v2, 2–3 months out)

Tea is a small market. Coffee is 10x larger and even more precision-obsessed (people buy $200 scales just for pour-over).

**Add coffee brewing presets:**
- French press (4 min / 94°C)
- Aeropress (1–2 min / 88°C)
- Pour-over / V60 (3 min / 93°C)
- Cold brew (12–24 hours)

Update subtitle and description to cover both. New keyword territory: `french press timer`, `aeropress timer`, `pour over timer`, `coffee brew timer` — real search volume, weak competition.

Don't do this yet. Fix discovery first, then expand.

---

## Priority Order (Do These First)

1. **Rewrite keywords, subtitle, description** — no code, 30 min, live within 24 hrs after Apple review
2. **Reorder screenshots** — put Watch screenshot 2nd, move paywall shot to last
3. **Ask 15 people to download and rate** — friends, family, anyone
4. **Post a screen recording video** to r/tea and r/applewatch this week
5. **Build re-steep support** — strongest Pro upgrade hook for core users
6. **Add brew journal** — creates retention and a meaningful Pro gate
7. **Add 7-day Pro trial** — removes "buy blind" friction

---

## What NOT To Do

- Don't add a subscription — contradicts the strongest marketing claim
- Don't expand to coffee yet — fix discovery first
- Don't rebuild the app — the product quality is good; the problem is distribution
- Don't add TelemetryDeck yet — premature with this traffic volume; add it after Phase 1 shows traction

---

## 30-Day Targets After ASO Fix

| Metric | Current | Target |
|---|---|---|
| Daily impressions | ~17/day | 200+/day |
| Product page views | 57 total | 30+/day |
| Downloads | 9 total | 5+/day |
| Ratings | 0 | 15+ |
| Pro conversions | 0 | 3–5 |
