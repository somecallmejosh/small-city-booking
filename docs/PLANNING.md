# Small City Studio — Booking App Planning Document

## Overview

A professional-grade progressive web app (PWA) for a single-room recording studio with a single admin/owner. The app allows the admin to create and manage available booking slots, and lets customers browse, book, and pay for studio time. The studio operates on an hourly model. Stripe handles all payments and refunds.

The app is deployed on affordable infrastructure but is held to the same engineering and UX standards as any production-quality commercial product: near-complete test coverage, zero-friction user flows, and a UI that feels indistinguishable from a native app.

---

## User Roles

### Admin (single owner)

- One account, designated by a seeded database flag (`admin: true`)
- Access to a protected `/admin` area
- Full control over slots, bookings, customers, agreements, and settings

### Customer

- Must create an account (email + password)
- Must agree to the current Terms of Booking before completing any reservation
- Must pay in full at time of booking via Stripe
- Can cancel a booking up to 24 hours before the session start for a full refund

---

## Tech Stack

| Layer              | Technology                                                               |
| ------------------ | ------------------------------------------------------------------------ |
| Framework          | Ruby on Rails 8.1.1                                                      |
| Database           | PostgreSQL                                                               |
| Frontend           | Hotwire (Turbo Frames/Streams + Stimulus)                                |
| Styling            | TailwindCSS                                                              |
| Auth               | Rails `authentication` generator (email + password)                      |
| Payments           | Stripe (Payment Intents, Refunds API, optional Payment Links)            |
| Push Notifications | Web Push API (`web-push` gem)                                            |
| Email              | Action Mailer (SMTP via Postmark or similar, low cost)                   |
| Rich Text          | Action Text (Trix editor, built into Rails)                              |
| Background Jobs    | Solid Queue (bundled with Rails 8, used for hold expiry + notifications) |
| File Storage       | Active Storage (if needed)                                               |
| Components         | ViewComponent (reusable, testable UI components)                         |
| Testing            | RSpec, Capybara + Cuprite, FactoryBot, SimpleCov, WebMock/VCR            |
| Code Quality       | RuboCop (rails-omakase), Brakeman, Bundler Audit                         |
| Error Tracking     | Sentry (free tier)                                                       |
| Pagination         | Pagy                                                                     |

### PWA

- `manifest.json` served from Rails (name, icons, `display: standalone`, `theme_color`)
- Service worker registered on page load to handle push notification subscriptions and offline caching
- Install prompt shown to returning users who haven't installed

---

## Data Models

### User

```
id
email              :string, unique, not null
password_digest    :string
name               :string
phone              :string, nullable
admin              :boolean, default: false
stripe_customer_id :string, nullable
created_at
updated_at
```

_Indexes: email (unique)_

---

### StudioSetting

A single-row config table.

```
id
hourly_rate_cents  :integer, not null
studio_name        :string
studio_description :text
cancellation_hours :integer, default: 24   # policy cutoff
created_at
updated_at
```

---

### Agreement

Versioned terms of booking. Each save creates a new version. Old versions are read-only.

```
id
version            :integer, not null       # auto-incremented
body               :action_text (rich text)
published_at       :datetime
created_at
```

_The "current" agreement is the one with the latest `published_at`._

---

### Slot

Represents a single one-hour block of available time opened by the admin.

```
id
starts_at          :datetime, not null      # e.g. 2025-03-05 15:00:00
status             :string, default: 'open' # open | held | reserved | cancelled
held_by_user_id    :bigint, nullable, FK → users
held_until         :datetime, nullable      # Time.current + 5.minutes when held
created_at
updated_at
```

_`ends_at` is always `starts_at + 1.hour` — derived, not stored._
_`held_by_user_id` and `held_until` are only set when `status = 'held'`; cleared on expiry or reservation._
_Indexes: starts_at, status, held_until_

---

### Booking

Links one or more consecutive Slots to a Customer.

```
id
user_id                  :bigint, FK → users
agreement_id             :bigint, FK → agreements   # snapshot at time of booking
status                   :string, default: 'confirmed'  # confirmed | cancelled | completed
stripe_payment_intent_id :string, nullable
stripe_payment_link_id   :string, nullable            # for admin-created bookings
stripe_refund_id         :string, nullable
total_cents              :integer, not null
notes                    :text, nullable              # admin notes
admin_created            :boolean, default: false
cancelled_at             :datetime, nullable
cancellation_reason      :text, nullable
refunded                 :boolean, default: false
created_at
updated_at
```

_Indexes: user_id, status, stripe_payment_intent_id_

---

### BookingSlot (join table)

```
id
booking_id         :bigint, FK → bookings
slot_id            :bigint, FK → slots
```

_Indexes: booking_id, slot_id (unique)_

---

### AgreementAcceptance

Legal record that a customer agreed to a specific version of the terms.

```
id
user_id            :bigint, FK → users
agreement_id       :bigint, FK → agreements
booking_id         :bigint, FK → bookings
ip_address         :string
user_agent         :string
accepted_at        :datetime
```

---

### PushSubscription

Stores Web Push API subscription objects per user.

```
id
user_id            :bigint, FK → users
endpoint           :string, not null
p256dh             :string, not null
auth               :string, not null
created_at
```

_One user can have multiple subscriptions (multiple devices)._

---

## Admin Features

### 1. Availability Management (`/admin/slots`)

- **Create slots individually:** pick a date, start time → creates one 1-hour slot
- **Create slots in bulk (recurring):**
  - Select days of the week (checkboxes: Mon–Sun)
  - Select date range (start date → end date)
  - Select time range (e.g., 3:00 PM → 1:00 AM next day)
  - System generates all hour-long slots that fall within the time range for the selected days
- **Calendar view:** month/week view showing open (green), booked (blue), and cancelled (grey) slots
- **Cancel an open slot:** removes it from customer view (only if not yet booked)
- **View booked slots:** read-only; must cancel the booking to free the slot

### 2. Booking Management (`/admin/bookings`)

- List all bookings (filterable by status: confirmed, cancelled, completed)
- View booking detail: customer info, time slots, payment status, agreement version accepted
- **Cancel a booking:** triggers Stripe refund (full amount), updates slot status to `open`, sends push + email notification to customer and admin
- **Create a booking manually:**
  - Select an existing customer or enter new customer info (name, email, phone)
  - Select consecutive available slots from a calendar
  - Optionally generate and send a Stripe Payment Link to the customer's email
  - If no payment link: booking is saved with `admin_created: true`, no payment required
  - Customer still receives confirmation notification

### 3. Customer Management (`/admin/customers`)

- List all customers (search by name/email)
- View customer detail: profile info, booking history, total spend
- Edit customer name, phone number
- Cannot delete customers who have bookings (to preserve history)

### 4. Agreement Management (`/admin/agreement`)

- View current published agreement (rendered rich text)
- Edit via Trix editor (Action Text)
- Saving creates a new Agreement record with an incremented version number and sets `published_at` to now
- Past versions are archived and viewable (read-only)
- Warning displayed: "Saving will publish a new version. Existing bookings will not be affected."

### 5. Studio Settings (`/admin/settings`)

- Hourly rate (in dollars, stored as cents)
- Studio name and description (shown on customer-facing pages)
- Cancellation policy window (hours before booking that allows refund, default 24)

---

## Customer Features

### 1. Account

- Sign up with name, email, phone (optional), password
- Log in / log out
- Update profile (name, phone, password)
- Manage push notification subscription (enable/disable on profile page)

### 2. Browse & Book (`/`)

- Landing page shows studio info, current hourly rate, and a booking calendar
- Calendar highlights available slots in green
- Customer clicks a starting slot; if adjacent slots are also open, they can extend the selection
- Multi-slot selection: clicking a start slot and an end slot (or dragging) selects all slots between them if they are all open and consecutive
- Booking summary shows: selected time range, total hours, total cost

### 3. Checkout

- Customer confirms their slot selection → app attempts to hold all selected slots (see Slot Hold Flow below)
  - If hold succeeds: customer proceeds to the checkout page with a **5-minute countdown timer** displayed
  - If hold fails (a slot was just taken): customer sees an error and is returned to the calendar to reselect
- Customer is shown the current Terms of Booking (rendered rich text)
- Customer must check "I agree to the Terms of Booking" before proceeding
- Customer is redirected to Stripe Checkout (or Payment Intent + hosted UI)
- If the hold expires while on the Stripe page, the webhook will find no valid hold and reject the booking; the customer is redirected back with an expiry message
- On successful payment:
  - Booking record created
  - Slot statuses updated from `held` to `reserved`; `held_by_user_id` and `held_until` cleared
  - AgreementAcceptance record created with IP address and user agent
  - Push notification sent to customer: "Booking confirmed — [date/time]"
  - Push notification sent to admin: "New booking from [customer name] — [date/time]"
  - Confirmation email sent to customer

### 4. My Bookings (`/bookings`)

- List upcoming and past bookings
- Booking detail: date/time, payment receipt (Stripe link), agreement version
- **Cancel booking:**
  - If > 24 hours before start: cancellation processed, full Stripe refund issued, notification sent
  - If ≤ 24 hours before start: form shows "This booking is within 24 hours. Cancellation is final with no refund." Requires explicit confirmation. No refund issued.
  - Cancelled slot status returns to `open`

---

## Business Rules

1. The studio is in **East Hartford, CT** — all times are stored in UTC and displayed in **US Eastern Time** (`America/New_York`). `config.time_zone = "Eastern Time (US & Canada)"` is set in `application.rb`. ActiveSupport handles DST transitions automatically. The slot creation form accepts and displays times in Eastern, and all emails, notifications, and UI labels show Eastern time.
2. A Slot is always exactly 1 hour (`starts_at` to `starts_at + 1.hour`)
3. Only one booking can hold a given slot at a time (enforced by DB unique constraint on `booking_slot.slot_id` where booking status is `confirmed`)
4. Customers may book multiple consecutive slots in a single transaction; the total is `number_of_slots × hourly_rate_cents`
5. The cancellation refund window is stored in `StudioSetting.cancellation_hours` (default: 24). If `booking.starts_at - Time.current > cancellation_hours.hours`, a full refund is allowed.
6. Admin can always cancel and refund, regardless of the cancellation window
7. Every booking stores a reference to the `Agreement` version in effect at the time of booking. Changes to the agreement do not affect past bookings.
8. Push notifications are sent to both the admin and relevant customer on: booking confirmed, booking cancelled
9. For admin-created bookings where no payment link is sent, no `stripe_payment_intent_id` is stored and `total_cents` may be 0
10. A customer's Stripe customer ID is created on first payment and stored for future use
11. When a customer begins checkout, all selected slots are held for **5 minutes** (`held_until = Time.current + 5.minutes`, `status = 'held'`, `held_by_user_id = current_user.id`). Slots held by another user are treated as unavailable to all other customers.
12. A held slot is exclusively owned by the holding user during the hold window. No other customer can select or hold it.
13. If the hold expires before payment completes, all held slots revert to `open` and the customer receives an in-page error prompting them to restart.
14. Hold acquisition uses a database-level row lock (`SELECT FOR UPDATE`) inside a transaction to prevent two simultaneous requests from claiming the same slot.
15. A Solid Queue recurring job runs every minute to release expired holds (`held_until < Time.current`) back to `open`, clearing `held_by_user_id` and `held_until`.

---

## Slot Hold Flow

When a customer submits their slot selection, the app must atomically claim all selected slots before proceeding to checkout.

### Hold Acquisition (server-side)

1. Open a database transaction
2. Lock the target slot rows with `SELECT FOR UPDATE SKIP LOCKED`
   - `SKIP LOCKED` means if another request already holds the lock, this request skips those rows rather than waiting — making the failure fast and explicit
3. Verify all locked slots are currently `open` (status check inside the lock)
4. If any slot is not `open`: rollback, return error → customer prompted to reselect
5. If all slots are `open`: update all to `status: 'held'`, `held_by_user_id: current_user.id`, `held_until: Time.current + 5.minutes`
6. Commit transaction
7. Redirect customer to checkout with timer visible

### Hold Expiry

- **Recurring job (Solid Queue):** runs every 60 seconds, resets any slot where `status = 'held' AND held_until < Time.current` back to `open` and clears hold fields
- **Lazy cleanup:** the `Slot.available` scope also excludes held-but-expired slots: `WHERE status = 'open' OR (status = 'held' AND held_until < NOW())` — prevents stale holds from blocking the calendar view between job runs

### Hold Release on Abandonment

- If the customer navigates away before payment, the Solid Queue job reclaims their held slots within at most 1 minute after `held_until` passes
- No explicit "release" action is required from the client

### Countdown Timer (Frontend)

- A Stimulus controller reads `held_until` from a data attribute rendered server-side
- Counts down in real time; at zero, disables the payment button and shows: "Your reservation has expired. Please go back and reselect your slots."
- Timer is purely informational — the server enforces the actual hold window

### Routes for Hold

```ruby
resources :slot_holds, only: [:create, :destroy]
# POST /slot_holds      → acquire hold, redirect to checkout
# DELETE /slot_holds/:id → explicit early release (optional, e.g. on back button)
```

---

## Payment Flow

### Standard Booking (Customer Self-Service)

1. Customer selects slots → app acquires 5-minute hold on all selected slots (atomic DB transaction)
2. Customer reviews Terms of Booking and checks "I agree"
3. App creates a Stripe PaymentIntent for `slots.count × hourly_rate_cents`
4. Customer completes payment in Stripe Checkout (must complete within remaining hold window)
5. Stripe fires `payment_intent.succeeded` webhook → app verifies hold is still valid, then confirms the booking and transitions slots from `held` to `reserved`
6. If hold has expired by webhook time: payment is refunded automatically via Stripe, customer notified to retry
7. On customer cancellation (≥24 hours): app calls Stripe Refunds API with `payment_intent_id`
8. On admin cancellation: app calls Stripe Refunds API unconditionally

### Admin-Created Booking with Payment Link

1. Admin creates booking, selects "Send Payment Link"
2. App creates a Stripe Payment Link for the amount
3. Link is emailed to the customer
4. Stripe fires `checkout.session.completed` webhook → app marks the booking as paid

### Stripe Webhooks (`POST /webhooks/stripe`)

- `payment_intent.succeeded` → confirm booking
- `payment_intent.payment_failed` → release reserved slots, notify customer
- `checkout.session.completed` → confirm admin-created booking as paid
- Webhook signature verified using `STRIPE_WEBHOOK_SECRET`

---

## Notifications

### Web Push (Primary)

- Uses `web-push` gem
- VAPID keys stored in credentials/environment variables
- PushSubscription records created when customer enables notifications in the browser
- Notifications delivered as background jobs (Solid Queue/Sidekiq)
- Notification sent to all of a user's subscribed devices

### Push Notification Triggers

| Event                              | Admin notified | Customer notified            |
| ---------------------------------- | -------------- | ---------------------------- |
| Customer creates a booking         | Yes            | Yes (confirmation)           |
| Customer cancels a booking         | Yes            | Yes (confirmation)           |
| Admin cancels a booking            | —              | Yes                          |
| Admin creates booking for customer | —              | Yes (if subscription exists) |

### Email (Secondary / Fallback)

- Action Mailer + SMTP (Postmark free tier or similar)
- Sent alongside push notifications (or as fallback if customer has no push subscription)
- Email types: booking confirmation, cancellation confirmation, payment link (admin bookings)

---

## Routing

```ruby
# Auth (generated by rails generate authentication)
# GET/POST /sign_in, /sign_out, /sign_up, etc.

# Customer-facing
root to: "home#index"
resources :bookings, only: [:index, :new, :create, :show] do
  member do
    post :cancel
  end
end
resources :push_subscriptions, only: [:create, :destroy]
resources :slot_holds, only: [:create, :destroy]
get "/help", to: "help#show"

# Stripe webhooks
post "/webhooks/stripe", to: "webhooks#stripe"

# Admin
namespace :admin do
  root to: "dashboard#index"
  resources :slots, only: [:index, :new, :create, :destroy] do
    collection do
      get  :bulk_new
      post :bulk_create
    end
  end
  resources :bookings, only: [:index, :show, :new, :create] do
    member do
      post :cancel
    end
  end
  resources :customers, only: [:index, :show, :edit, :update]
  resource :agreement, only: [:show, :edit, :update]
  resource :settings, only: [:show, :edit, :update]
end
```

_Admin routes are protected by `before_action :require_admin` in `AdminController`._

---

## PWA Setup

- `public/manifest.json` — name, short_name, icons (192px, 512px), `display: standalone`, `theme_color`, `background_color`, `start_url: "/"`
- Service worker at `public/sw.js`:
  - Intercepts `push` events → displays notification with title, body, and a link to the relevant booking
  - Intercepts `notificationclick` → opens or focuses the app
  - Caches static assets for basic offline support
- Service worker registered in `application.js` on page load
- `<meta name="apple-mobile-web-app-capable" content="yes">` for iOS install
- Install prompt managed in Stimulus controller (`install_controller.js`)

---

## Engineering Standards

### Testing

The goal is ≥95% line coverage with meaningful tests — not tests written to hit a number but tests that verify real behavior and prevent regressions.

**Test stack:**
- **RSpec** — all model, service, job, mailer, and request specs
- **Capybara + Cuprite** (headless Chrome) — end-to-end system tests for every user-facing flow
- **FactoryBot** — shared test data factories for all models
- **SimpleCov** — coverage reporting; CI fails if coverage drops below 95%
- **WebMock** — stubs all external HTTP calls in tests (no real Stripe or SMTP calls)
- **VCR** — cassette recordings for Stripe API interactions; replays them in CI
- **Stripe CLI (`stripe listen`)** — used in development to forward live test webhooks locally

**What gets tested:**
- Every model: validations, scopes, instance methods, business logic
- Every service object and background job: happy path + all failure paths
- Every controller action: correct response codes, redirects, flash messages
- Every Stripe webhook handler: correct state transitions for each event type, idempotency (duplicate events must not double-book or double-refund)
- Slot hold concurrency: a concurrent hold attempt on the same slot must fail for one and succeed for the other
- Cancellation policy: boundary conditions at exactly 24 hours before, just inside, and just outside the window
- Agreement snapshotting: booking always references the agreement version active at time of booking
- Admin authorization: every admin-only route returns 403/redirect for non-admin users

### Code Quality

- **RuboCop** (rails-omakase preset) enforced in CI — zero offenses required to merge
- **Brakeman** security scanner runs in CI — no unresolved warnings
- **Bundler Audit** checks for known CVEs in dependencies — CI fails on any high-severity finding
- All public methods on service objects and models have clear intent; complex logic is commented
- No raw SQL except where Active Record cannot express it (e.g., `SELECT FOR UPDATE SKIP LOCKED`)

### Styling Conventions

Tailwind utility classes are never repeated inline across the codebase. Any class string applied in more than one place is extracted into a helper method and referenced by name. This keeps templates readable and change-resistant — updating a style means changing one line, not hunting across dozens of views.

**Where extracted styles live:**
- `app/helpers/style_helper.rb` — app-wide UI primitives (buttons, fields, links, icons, badges, containers)
- Inside a `ViewComponent` class — styles private to that component live as private methods on the class, not in the helper

**Naming convention:** names describe function and variant, not appearance. The name should be meaningful if the colors change.

```ruby
# app/helpers/style_helper.rb
module StyleHelper
  def btn_primary   = "inline-flex items-center justify-center rounded-lg bg-stone-900 px-5 py-2.5 text-sm font-medium text-white hover:bg-stone-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-stone-900 disabled:opacity-50"
  def btn_secondary = "inline-flex items-center justify-center rounded-lg border border-stone-300 bg-white px-5 py-2.5 text-sm font-medium text-stone-700 hover:bg-stone-50"
  def btn_danger    = "inline-flex items-center justify-center rounded-lg bg-red-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-red-700"
  def input_field   = "block w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-sm text-stone-900 placeholder:text-stone-400 focus:border-stone-500 focus:outline-none focus:ring-1 focus:ring-stone-500"
  def card          = "rounded-xl border border-stone-200 bg-white p-5 shadow-sm"
  def page_container = "mx-auto w-full max-w-2xl px-4 lg:px-8"
end
```

```erb
<%# In any template or component template %>
<button class="<%= btn_primary %>">Confirm & Pay</button>
<div class="<%= page_container %>">...</div>
```

**Applies to:** buttons (primary, secondary, danger, ghost), form inputs and labels, links, icon wrappers, badge/pill states, card and panel containers, page-level layout wrappers.

### Error Handling

- Controllers never let exceptions bubble to a raw 500 page; `rescue_from` handles known error classes with user-friendly messages
- All Stripe API calls are wrapped in rescue blocks; network or API failures surface as flash errors without losing the user's place
- Background jobs use Solid Queue's built-in retry with exponential backoff (3 retries, then dead-letter queue)
- Stripe webhook handler is fully idempotent — replaying any webhook event must produce the same result as processing it once
- **Sentry** captures all unhandled exceptions in production with full request context; alerts on new issues

### ViewComponent

ViewComponent is the default for any UI element that is reused in more than one location, or that contains logic. Partials are acceptable for simple, static, single-use markup only.

**Why ViewComponent over partials:**
- Components are unit-testable in isolation without a full request (`ViewComponent::TestCase`)
- Explicit, typed inputs — no reliance on ambient instance variables or implicit locals
- Rendering logic lives in the component class, not scattered across helpers or the template
- IDE support for finding usages, refactoring, and spotting breaking changes

**Component examples:**
- `SlotCardComponent` — renders a single calendar slot (open / held / reserved / cancelled states)
- `BookingSummaryComponent` — selected time range, total hours, total cost
- `CountdownTimerComponent` — hold expiry timer with `data-controller` wired for Stimulus
- `FlashMessageComponent` — success/error/info banners
- `BookingRowComponent` — a single row in a booking list (used in admin and customer views)
- `AgreementAcceptanceComponent` — terms body + checkbox + submit; reused in customer checkout and admin-created booking flow
- `ConfirmationDialogComponent` — bottom-sheet on mobile, centered modal on desktop; reused for all destructive action confirmations
- `BreadcrumbComponent` — renders the `<nav aria-label="Breadcrumb">` trail; accepts an array of `{label:, path:}` items

**Testing convention:**
- Every component has a `spec/components/<name>_component_spec.rb`
- Specs cover all slot states, edge-case inputs, and ARIA attribute correctness
- System tests exercise components in the context of real user flows

### Security

- Rails CSRF protection enabled on all state-changing requests
- Stripe webhook signature verified on every inbound request using `STRIPE_WEBHOOK_SECRET`; unsigned or tampered requests return 400 immediately
- Admin namespace protected by `before_action :require_admin` at the `Admin::BaseController` level — not per-action
- `rack-attack` throttles: 5 failed login attempts per IP per minute, 10 signup attempts per IP per 10 minutes
- Content Security Policy (CSP) headers configured via `SecureHeaders` or Rails' built-in CSP DSL
- No card data or PII ever written to logs; `config.filter_parameters` includes all sensitive fields
- Brakeman runs on every CI build; unresolved issues block deployment

---

## UI/UX Principles

The app must feel as polished and responsive as a native mobile app. "No friction" means the user is never confused, never waiting, and never loses progress.

### Native App Feel

- **Turbo Drive** handles all navigation — pages never go blank or flash during transitions; only the changed content updates
- **Turbo Frames** wrap dynamic content areas (slot calendar, booking summary, form responses) for partial updates without full page reloads
- **Turbo Streams** broadcast real-time calendar updates: when another user holds or releases slots, the calendar updates in all connected browsers without a refresh
- **Stimulus** provides targeted JavaScript for: countdown timer, calendar slot selection, install prompt, clipboard copy, and confirmation dialogs
- Page transitions are instant; any operation that takes >300ms shows a loading indicator

### Zero-Friction User Flows

**The 2-click rule:** Every primary user action should be completable in at most 2 clicks from the user's current position. Where 2 clicks is genuinely impossible (e.g., multi-field forms, payment entry), the goal is the absolute minimum number of clicks, keystrokes, scrolls, and page loads the task allows. No action should ever require navigation away from context to complete a related subtask.

Examples:
- **Customer books a slot:** tap slot on calendar (1) → tap "Confirm & Pay" (2) → Stripe handles the rest
- **Customer cancels a booking:** tap "Cancel" on the booking row (1) → tap "Yes, cancel" on the confirmation (2)
- **Admin opens a slot:** tap "+" on the calendar day (1) → tap "Create" with pre-filled time (2)
- **Admin cancels a booking:** tap "Cancel & Refund" on the booking detail (1) → tap "Confirm" (2)

**Content philosophy:** The app contains zero superfluous text. Every label, placeholder, and heading is self-evident from context — no onboarding tooltips, no instructional paragraphs, no "click here to..." copy. The UI teaches through its structure, not its words. A dedicated **User Manual** (linked from the nav) provides deeper documentation for users who want it, but the app never requires reading it to use it.

**User Manual** (available at `/help`):
- How the booking calendar works and what each slot state means
- The cancellation policy and refund timeline
- The Terms of Booking — what it means and why it exists
- Admin workflow: creating slots, managing bookings, updating the agreement
- Written in plain language; no assumed technical knowledge

**Other zero-friction commitments:**
- Every action has immediate visual feedback: buttons enter a loading state on click; success and error states are visible within milliseconds
- Forms preserve all user input on validation failure — no data is lost
- Error messages are inline, adjacent to the failing field, and specific enough to act on ("Email is already registered — sign in instead?" not "Email is invalid")
- All destructive actions (cancel booking, publish new agreement) require a single confirmation that clearly states the consequence — not a multi-step modal flow

### Mobile-First Design

- All layouts and components are designed for mobile first; desktop layouts are an enhancement via `sm:` / `md:` / `lg:` Tailwind breakpoints
- Touch targets are a minimum of 44×44px (Apple HIG / WCAG 2.5.5)
- Calendar slot grid is generously spaced for touch interaction; slots show time label and status clearly at small sizes
- Swipe-to-navigate between weeks/months on the calendar (Stimulus + touch events)
- Confirmation dialogs use a bottom-sheet presentation on mobile, centered modal on desktop
- No interaction depends on hover — everything works with tap

### Accessibility (WCAG 2.1 AA — Non-Negotiable)

Although the app is primarily used on mobile, it must be 100% keyboard accessible on all devices and screen sizes. Every interaction achievable with a pointer must also be achievable with a keyboard alone.

**Keyboard accessibility:**
- Tab order follows the visual reading order on every page
- Every interactive element is reachable and operable via keyboard: slots, buttons, calendar navigation, form fields, confirmation dialogs
- Slot calendar: arrow keys navigate between slots; Enter/Space selects a slot; Escape clears a selection
- All modal and bottom-sheet dialogs trap focus while open and return focus to the trigger element on close
- No keyboard trap outside of intentional dialog focus traps

**Drag and drop:**
- If drag-and-drop is used (e.g., admin reordering slots or views), it must have a fully equivalent keyboard alternative — every action performable by dragging must be performable by keyboard without extra steps
- Drag-and-drop interactions must announce state changes via `aria-live`: "Slot moved to Thursday 4 PM", "Drop cancelled"
- The keyboard alternative must be discoverable without reading external documentation

**Semantic markup:**
- `<button>`, `<time datetime="...">`, `<nav>`, `<main>`, `<header>`, `<section>`, `<dialog>`, `<form>`, `<fieldset>`, `<legend>` used throughout
- ARIA attributes only where native semantics are insufficient (`aria-live`, `aria-selected`, `aria-disabled`, `aria-expanded`, `aria-controls`)
- No `<div>` or `<span>` used as interactive elements

**Visual design:**
- All color-coded slot states (open / held / reserved / cancelled) also communicate state via text label or icon — color is never the only indicator
- Color contrast ratio ≥4.5:1 for all body text; ≥3:1 for large text and UI components
- Focus rings are visible and consistently styled on every interactive element — `outline: none` is never used without a custom visible alternative
- Dynamic content changes (Turbo navigation, Turbo Stream updates, form errors, countdown updates) emit appropriate `aria-live` announcements

**Component-level testing:**
- Every `ViewComponent` has accessibility assertions in its spec: correct ARIA attributes for each state, keyboard-operability, and focus management
- System tests include a keyboard-only test pass for the booking and cancellation flows

### Navigation & Wayfinding

The user always knows where they are. Location is communicated through active nav states, breadcrumbs, and the browser tab title — never left to the user to infer.

**Active navigation:**
- The current page's nav item is visually distinguished (different weight, color, or indicator) and carries `aria-current="page"` for screen readers
- Active state is computed server-side and rendered into the nav component — no client-side class toggling required
- Sub-sections of the admin area (Bookings, Customers, Slots, etc.) highlight their parent nav group when active

**Breadcrumbs:**
- Present on any page more than one level deep: `Admin › Bookings › #12345`
- Rendered as semantic `<nav aria-label="Breadcrumb"><ol>...</ol></nav>` with each ancestor as a `<li>` containing a link, and the current page as a non-linked `<li aria-current="page">`
- A `BreadcrumbComponent` renders the trail; pages declare their own breadcrumb data by passing items to the layout

**Page titles:**
- Every page has a descriptive `<title>` that reflects its content: "Booking #12345 — Small City Studio", "Admin · Slots", not just "Small City Studio" on every page
- Titles follow the pattern: `[Page Name] — [App Name]`; admin pages prepend "Admin ·"

**Routing consistency:**
- URLs are readable and predictable (`/bookings/12345`, `/admin/bookings/12345`) — no opaque identifiers in the URL where avoidable
- Back-navigation always returns the user to a meaningful previous state; no dead-ends after form submissions

### Performance

- Avoid N+1 queries: all index and show views use `includes(...)` to eager-load associations; N+1 detection enabled in the test suite (`bullet` gem in development)
- Background jobs handle all slow I/O (email, push notifications, Stripe calls from webhooks) — HTTP requests never block on external services
- Pagination via Pagy on all lists with potentially unbounded rows (bookings, customers, past agreements)
- Turbo Drive page caching enables instant back-navigation without a network request
- Database queries for slot availability use index-covered conditions (`starts_at`, `status`, `held_until`) — no full table scans
- `bullet` gem in development to catch and fix N+1s before they reach production

---

## Deployment

Deployed on affordable infrastructure; the infrastructure cost is low, the production quality is not.

**Platform:** Railway
- Managed Postgres database add-on
- Automatic deploys from `main` branch via Railway's GitHub integration
- Environment variables managed in the Railway dashboard
- Database migrations run automatically via Railway's deploy hook (`bundle exec rails db:migrate`)

### CI/CD Pipeline (GitHub Actions)

Runs on every push and pull request:

1. `bundle exec rspec` — all tests must pass
2. `bundle exec rubocop` — zero offenses
3. `bundle exec brakeman -q` — zero unresolved warnings
4. `bundle exec bundler-audit check --update` — no high-severity CVEs
5. SimpleCov coverage check — fails if below 95%

Deployment to Railway triggers automatically only after all five CI checks pass on `main`.

### Environment Variables Required

```
DATABASE_URL
RAILS_MASTER_KEY
STRIPE_SECRET_KEY
STRIPE_PUBLISHABLE_KEY
STRIPE_WEBHOOK_SECRET
VAPID_PUBLIC_KEY
VAPID_PRIVATE_KEY
SMTP_HOST / SMTP_USER / SMTP_PASSWORD   # or Postmark API key
```

---

## Open Questions / Future Considerations

- Reminder notifications 24 hours before a session (nice-to-have, add later)
- Waitlist feature if all slots are booked (out of scope for v1)
- Discount codes or package deals (out of scope for v1)

---

## Implementation Phases (Suggested)

Tests are written alongside each feature, not after. Every phase ends with a passing test suite and ≥95% coverage for all code written so far.

### Phase 1 — Foundation

- Rails 8.1.1 app setup, TailwindCSS, Hotwire, Importmap or Propshaft
- ViewComponent gem installed; `spec/components` directory wired into RSpec
- RSpec + FactoryBot + Capybara + Cuprite configured; SimpleCov threshold set
- RuboCop, Brakeman, Bundler Audit configured; GitHub Actions CI pipeline wired up
- `rack-attack` throttling configured
- CSP headers configured
- Authentication (`rails generate authentication`); model + request specs for sign up, sign in, sign out, password validation
- Database schema + all migrations
- Seed: admin user, initial `StudioSetting` record
- Sentry configured for production
- `FlashMessageComponent`, `ConfirmationDialogComponent`, and `BreadcrumbComponent` built and tested — used by every subsequent feature
- `StyleHelper` (`app/helpers/style_helper.rb`) written with base UI primitives: `btn_primary`, `btn_secondary`, `btn_danger`, `input_field`, `card`, `page_container`

### Phase 2 — Admin Core

- `Admin::BaseController` with `require_admin` guard; request specs verify non-admin users are rejected on all admin routes
- Slot management: single creation, bulk creation (day × date range × time range), cancellation — model specs for all validation and scoping logic; system tests for the admin bulk-create form
- Agreement management: Action Text editor, versioning on save, archived view — model spec verifying version auto-increment and immutability of past versions
- Studio settings form — request spec covering hourly rate and cancellation window updates

### Phase 3 — Customer Booking Flow

- Calendar view of available slots: Turbo Frame-powered, real-time updates via Turbo Streams when hold status changes; system test: two browsers, user A holds a slot, user B sees it become unavailable without refreshing
- Multi-slot selection Stimulus controller; spec verifying only consecutive open slots can be selected
- Slot hold acquisition: `SlotHoldsController`, `SELECT FOR UPDATE SKIP LOCKED`, 5-minute window; concurrency spec using threads to verify only one of two simultaneous hold attempts succeeds
- Solid Queue recurring job for hold expiry; job spec verifying slots return to `open` after `held_until` passes
- Countdown timer Stimulus controller; system test verifying the payment button is disabled when the timer reaches zero
- Agreement acceptance: inline display, checkbox enforcement, `AgreementAcceptance` record creation with IP and user agent
- Stripe integration: Payment Intent creation, Checkout redirect, webhook handlers; VCR cassettes for all Stripe API calls; webhook handler specs for `payment_intent.succeeded`, `payment_intent.payment_failed`, `checkout.session.completed` — including duplicate-event idempotency

### Phase 4 — Booking Management

- Customer "My Bookings" page: upcoming + past, booking detail with Stripe receipt link
- Customer cancellation flow: ≥24h → full refund; <24h → no-refund confirmation; boundary condition specs at exactly the policy window
- Admin booking list with status filters; booking detail view
- Admin cancel + refund flow; request spec verifying refund is always issued regardless of cancellation window
- Admin manual booking creation + optional Stripe Payment Link; system test for the full admin-creates-booking-and-sends-link flow

### Phase 5 — Notifications

- PWA manifest + service worker setup; offline caching spec
- Web Push: VAPID key generation, `PushSubscription` model, browser subscription Stimulus controller; job spec verifying notifications are sent to all of a user's devices
- Action Mailer: booking confirmation, cancellation, payment link emails; mailer specs with correct recipients, subjects, and body content
- Notification trigger specs: verify correct parties are notified for each event type

### Phase 6 — Polish & Ship

- Customer management page (admin): search, profile, booking history, spend total
- User Manual page (`/help`): booking calendar explainer, cancellation policy, Terms of Booking context, admin workflow guide — plain language, no assumed knowledge
- 2-click audit: walk through every primary user action and verify it meets the ≤2 click rule; refactor any flows that don't
- Full accessibility audit: keyboard-only walkthrough of every flow, screen reader spot-check, color contrast verification for all components
- Mobile UX pass: touch target sizes, swipe-to-navigate calendar, bottom-sheet dialogs
- N+1 audit using `bullet`; fix any detected queries; add `bullet` assertions to system tests
- Full system test run across all critical user journeys from an unauthenticated starting state, including a keyboard-only test pass
- Stripe webhook hardening: signature verification spec with tampered payload
- Load test slot hold concurrency under realistic conditions
- Deploy to Railway; verify GitHub Actions CI/CD pipeline triggers correctly on push to `main`
