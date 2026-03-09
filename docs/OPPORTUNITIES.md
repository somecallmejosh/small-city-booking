# Small City Studio — Growth Opportunities

## Context

Chase Briley of Small City Studios works with rap, hip-hop, and R&B artists — 250+ served in 5.5 years. His brand is built on personal connection, transparency, and community. These opportunities are designed to match that ethos: no gimmicks, just tools that reinforce genuine relationships and keep the calendar full.

---

## The Big Three Gaps

### 1. No Self-Registration

Artists currently can't sign up themselves. An admin has to create every customer account. This kills organic lead flow. A potential customer who finds the site at midnight ready to book hits a wall.

### 2. No Email Communication (Beyond Password Reset)

The studio has contact info for every customer who's ever booked. That's a goldmine that's sitting completely unused. No booking confirmations via email, no reminders, no re-engagement.

### 3. No Lead Capture for Unbooked Visitors

A visitor browses the calendar, finds nothing available, and leaves. No way to stay in touch. That potential customer is gone.

---

## Prioritized Feature Roadmap

### Tier 1 — Pipeline Foundations (Highest ROI)

**A. Artist Self-Registration**
Let artists create their own account. Remove the admin bottleneck. The current "admin creates customer" model is appropriate for a small, curated client list — but it's a lead-generation killer. Self-registration with email verification is the single most impactful change.

**B. Waitlist**
When the calendar has no available slots in the next N days (or for a specific date), show a "Join Waitlist" form. When a cancellation happens or new slots are added, notify waitlisted artists by email. This directly fills the pipeline with zero ad spend.

**C. Transactional Emails**
Currently almost no emails go out. Add:

- Booking confirmation email (with session details, prep tips, studio address)
- 24-hour reminder email ("Your session is tomorrow!")
- Post-session follow-up email (sent ~3 hours after session ends): "How'd it go? Book your next session → [link]"

The post-session email is the single highest-leverage retention tool. Strike while the energy is high.

---

### Tier 2 — Conversion & Social Proof

**D. Testimonials on Homepage**
Chase has worked with 250+ artists. A few powerful quotes with artist names on the homepage builds trust for first-time visitors instantly. Admin-managed, simple: a `Testimonial` model with quote + artist name + optional track title.

**E. Promo Codes**
A `PromoCode` model with a percentage or flat discount, applied at checkout. Use cases:

- First-session discount ("FIRSTTRACK" — 10% off)
- Slow-period fill ("MARCH20" during low weeks)
- Reward returning customers personally

**F. "Notify Me When Slots Open"**
A lightweight email capture form for visitors who aren't ready to book or can't find availability. Admin gets a list of interested leads they can notify manually or via automated job when new slots are created.

---

### Tier 3 — Loyalty & Retention

**G. Repeat Customer Recognition**
Track booking count per customer. After their 3rd confirmed session, they're a "returning artist." Surface this in admin (flag on customer record) and send a personal email from Chase: "You've recorded 3 sessions — here's a thank-you discount for your next one."

**H. Re-booking Nudge**
If a confirmed customer hasn't booked again in 30 days, send a single re-engagement email. Not spammy — just one: "Ready to get back in the booth? →"

**I. Referral Codes**
Every customer gets a unique referral link. When a new customer books using it, both get a credit or discount. Artists talk to other artists. This turns your customer base into a sales team.

---

### Tier 4 — Brand & Community (Longer Term)

**J. Artist Showcase / Portfolio**
A public "Artists We've Worked With" page — opt-in, so customers who want the exposure can be featured. Drives SEO, builds community, reinforces Chase's credibility.

**K. Session Packages / Prepaid Hours**
Buy 5 hours, get 1 free. Pays upfront, locks in repeat business, gives Chase cash flow predictability.

---

## Implementation Sequence

```
Sprint 1:  Self-registration + email confirmation
Sprint 2:  Transactional emails (confirmation + reminder + post-session)
Sprint 3:  Waitlist feature
Sprint 4:  Promo codes
Sprint 5:  Testimonials admin + homepage
Sprint 6:  Notify-me lead capture
Sprint 7:  Repeat customer tracking + re-engagement email
Sprint 8:  Referral codes
```

---

## Where to Start

The highest-leverage trio for filling Chase's calendar fastest:

1. **Self-registration** — removes the biggest friction barrier
2. **Post-session follow-up email** — re-books warm customers at peak excitement
3. **Waitlist** — passively captures leads when the calendar is full
