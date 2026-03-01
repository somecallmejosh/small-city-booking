# Small City Studio — Owner's Manual

This guide explains how the booking app works for both you (the studio owner) and your customers. No technical knowledge required.

---

## Table of Contents

1. [Overview](#overview)
2. [Admin: Your Control Panel](#admin-your-control-panel)
   - [Dashboard](#dashboard)
   - [Managing Time Slots](#managing-time-slots)
   - [Managing Bookings](#managing-bookings)
   - [Managing Customers](#managing-customers)
   - [Studio Agreement](#studio-agreement)
   - [Studio Settings](#studio-settings)
3. [Customer Experience](#customer-experience)
   - [Browsing Available Slots](#browsing-available-slots)
   - [Making a Booking](#making-a-booking)
   - [After Payment](#after-payment)
   - [Cancellations & Refunds](#cancellations--refunds)
   - [Notifications](#notifications)
4. [Cancellation & Refund Policy](#cancellation--refund-policy)
5. [Notifications Reference](#notifications-reference)
6. [Tips & Best Practices](#tips--best-practices)

---

## Overview

Small City Studio is a self-service booking app for your recording studio. Customers browse your available time slots, pay securely via Stripe, and receive instant confirmation — all without you having to be involved in each transaction.

You manage everything from an **Admin Panel** that customers never see. Your customers interact with the **public-facing booking calendar**.

---

## Admin: Your Control Panel

Sign in with your admin email and password to access the admin panel. The navigation along the top gives you access to every section described below.

---

### Dashboard

The dashboard is your at-a-glance overview. It shows:

- **Open slots** — how many upcoming slots are still available to book
- **Reserved slots** — how many upcoming slots have been paid for

Quick links on the dashboard take you to the most common tasks: creating slots, viewing customers, editing your agreement, and adjusting settings.

---

### Managing Time Slots

Slots are the 1-hour blocks of time customers can book. You control the schedule entirely — the calendar only shows what you've created.

#### Creating Slots One at a Time

Go to **Slots → New Slot**. Pick a date and start time. The slot is immediately available for customers to book.

#### Creating Slots in Bulk

Go to **Slots → Bulk Create**. This is the fastest way to set up your schedule:

1. Choose which **days of the week** to include (e.g., Tuesday, Wednesday, Friday)
2. Set a **date range** (e.g., March 1 through March 31)
3. Set a **time window** (e.g., 10:00 AM to 6:00 PM)
4. Click **Create Slots**

The app generates one slot per hour within that window, on each of the selected days, for the entire date range. It skips any slots that already exist. You'll see a summary of how many were created.

**Overnight sessions:** If your studio runs late-night hours (e.g., 10 PM to 2 AM), just set the end time earlier than the start time — the app handles midnight automatically.

#### Cancelling a Slot

From the **Slots** list, click **Cancel** next to any open slot. Cancelled slots disappear from the customer calendar immediately. You can only cancel slots that haven't been reserved — if a slot is part of a booking, cancel the booking first.

---

### Managing Bookings

Go to **Bookings** to see every booking in the system.

#### Filtering Bookings

Use the filter tabs at the top to view bookings by status:

| Status | What it means |
|--------|---------------|
| **Pending** | Customer is in the middle of checkout; payment not yet confirmed |
| **Confirmed** | Payment successful; session is locked in |
| **Cancelled** | Booking was cancelled by the customer or by you |
| **Completed** | Session has already taken place |

#### Viewing a Booking

Click on any booking to see full details: customer info, all session times, total paid, Stripe payment and receipt links, and refund status (if applicable).

#### Creating a Manual Booking

Go to **Bookings → New Booking**. This lets you create and assign a booking directly — useful for customers who call or email instead of booking online.

1. Select the customer from the dropdown (or create them first in the Customers section)
2. Select the open slots for their session
3. Optionally add internal notes
4. Optionally generate a **Stripe Payment Link** — a shareable URL you can email to the customer so they can pay online at their convenience

The booking is created as **Confirmed** immediately (no payment required if you don't generate a payment link, or if you're handling payment another way).

#### Cancelling a Booking

From any booking detail page, click **Cancel Booking**.

- If the booking was **paid via Stripe**, the app automatically issues a full refund to the customer's card.
- The slots are released back to "open" so other customers can book them.
- The customer receives a push notification that their booking was cancelled.

You can also cancel multiple bookings at once from the Bookings list by selecting their checkboxes and using the bulk cancel action.

---

### Managing Customers

Go to **Customers** to see everyone who has created an account.

#### Searching Customers

Type a name or email in the search bar. Partial matches work — you don't need to type the full name.

#### Viewing a Customer Profile

Click on any customer to see:

- Their name, email, and phone number
- **Total spend** — how much they've paid across all confirmed and completed bookings
- **Booking history** — a table of every booking they've made, with dates, duration, cost, and status

#### Creating a Customer Account

Go to **Customers → New Customer**. Enter their email, name, and phone number. The app generates a temporary password automatically — the customer should use **Forgot Password** on the login page to set their own password the first time they sign in.

#### Editing Customer Info

From any customer profile, click **Edit**. You can update their name and phone number. Email addresses cannot be changed after account creation.

---

### Studio Agreement

The Studio Agreement is the terms and conditions your customers must accept before completing a booking. Every customer is shown the current agreement at checkout and must check a box confirming they've read it.

#### Publishing a New Agreement

Go to **Agreement → Edit**. Write or paste your terms using the rich text editor (supports bold, italic, headings, bullet lists, and links). Click **Save** to publish immediately.

Each saved version is automatically numbered. Future bookings use the new version; past bookings remain linked to the version the customer originally agreed to — this protects you legally if terms change.

#### Agreement History

All previous versions are stored and viewable at any time. You can see exactly what a customer agreed to at the time of their booking.

---

### Studio Settings

Go to **Settings** to configure the basics of how your studio is presented and priced.

| Setting | What it does |
|---------|--------------|
| **Studio Name** | Appears on the booking page and in notifications |
| **Studio Description** | A short tagline customers see when browsing (e.g., "Professional 2-mic isolated booth") |
| **Hourly Rate** | The price per hour. Booking totals are calculated automatically: hours × rate |
| **Cancellation Window** | How many hours before a session a customer can still cancel for a full refund (e.g., 24 hours) |

Changes take effect immediately for new bookings. Existing confirmed bookings are not affected.

---

## Customer Experience

This section describes what your customers see and do when they use the app.

---

### Browsing Available Slots

When a customer visits the site, they see a calendar of your available slots for the next 30 days. Slots are grouped by date. Each slot shows the time and is color-coded by status:

| Color | Status | What it means to the customer |
|-------|--------|-------------------------------|
| Green | Open | Available to book |
| Yellow | Held | Someone is checking out — may open up soon |
| Blue | Reserved | Already booked |
| Gray | Cancelled | Not available |

The calendar updates in real time — if a slot becomes available or gets taken while a customer is browsing, their view updates automatically without refreshing the page.

---

### Making a Booking

Customers must be signed in to book. If they don't have an account, they can create one from the sign-in page.

#### Selecting Slots

Customers click on the first slot they want, then click the last slot they want. All consecutive hours in between are selected automatically. The running total updates as they select slots.

**Important:** Only consecutive, open slots can be selected. If a held or reserved slot falls in the middle of a desired range, customers must work around it.

#### The 2-Minute Hold

When a customer clicks **Continue to Checkout**, the app places a **2-minute hold** on their selected slots. During this time:

- The slots turn yellow and are unavailable to other customers
- A countdown timer on the checkout page shows how much time remains
- If the customer doesn't complete payment in time, the hold expires automatically and slots return to green

This prevents double-booking without requiring payment upfront.

#### Checkout & Payment

On the checkout page, customers see:

- Their selected sessions with dates and times
- Total cost
- The current Studio Agreement (which they must accept by checking a box)

Clicking **Confirm & Pay** sends them to Stripe's secure payment page. All card processing happens on Stripe — your studio never sees or stores any card information.

After successful payment, customers are redirected back to a confirmation page.

---

### After Payment

Customers can view all their bookings under **My Bookings**. From there they can:

- See upcoming and past sessions
- Access a Stripe receipt for any paid booking
- Cancel a confirmed booking (if within the cancellation window)

---

### Cancellations & Refunds

Customers can cancel any confirmed booking from their **My Bookings** page. Before confirming, they see a message explaining whether they'll receive a refund.

- **Full refund:** Cancellation is more than [cancellation window] hours before the session starts
- **No refund:** Cancellation is within [cancellation window] hours of the session

Refunds are processed automatically through Stripe and typically appear on the customer's card within 5–10 business days.

---

### Notifications

Customers can opt in to push notifications in their browser. Once enabled, they'll receive notifications for:

- Booking confirmed
- Booking payment failed
- Booking cancelled by the studio

Notifications work even when the app isn't open in the browser.

---

## Cancellation & Refund Policy

| Who cancels | When | Refund? |
|-------------|------|---------|
| Customer | More than [window] hours before session | Full refund, automatic |
| Customer | Within [window] hours of session | No refund |
| You (admin) | Any time | Full refund, automatic |

The cancellation window is set in **Settings** and applies to all bookings. You can always override it by cancelling a booking yourself — admin cancellations always refund the customer.

---

## Notifications Reference

The app sends push notifications automatically in these situations:

| Event | Who is notified |
|-------|----------------|
| Customer pays successfully | Customer + You (admin) |
| Payment fails | Customer |
| Customer cancels their own booking | Customer |
| You cancel a customer's booking | Customer |
| You create a manual booking for a customer | Customer |

You receive a notification for every successful booking so you're always aware of new sessions without checking the dashboard.

---

## Tips & Best Practices

**Set your schedule in advance.** Use Bulk Create to generate an entire month of slots at once. You can always cancel individual slots later if the studio is unavailable.

**Create the agreement before going live.** Customers must accept it before booking. The app will not let them proceed without a published agreement.

**Verify your hourly rate in Settings** before your first booking. Once a booking is confirmed, the rate is locked in — changing the rate later only affects future bookings.

**Use the cancellation window that matches your costs.** If you have setup or prep costs that you incur the day before a session, set the window to 24 or 48 hours so you're protected.

**Create accounts for phone/email customers.** If someone calls to book, create their account under Customers, then create the booking manually and optionally generate a Payment Link for them to pay online.

**Check the dashboard regularly.** The at-a-glance stats tell you quickly if you have inventory (open slots) and confirmed revenue (reserved slots) for the coming weeks.

**You can always refund.** If something goes wrong — a session falls through, equipment fails, the studio isn't available — you can cancel any confirmed booking from the admin panel and the customer will be automatically refunded. No manual Stripe work required.
