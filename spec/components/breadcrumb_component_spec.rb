require "rails_helper"

RSpec.describe BreadcrumbComponent, type: :component do
  let(:items) do
    [
      { label: "Admin", path: "/admin" },
      { label: "Bookings", path: "/admin/bookings" },
      { label: "Booking #42", path: nil }
    ]
  end

  it "renders a nav element with the Breadcrumb label" do
    render_inline(described_class.new(items: items))

    expect(page).to have_css("nav[aria-label='Breadcrumb']")
  end

  it "renders ancestor items as links" do
    render_inline(described_class.new(items: items))

    expect(page).to have_link("Admin", href: "/admin")
    expect(page).to have_link("Bookings", href: "/admin/bookings")
  end

  it "renders the last item as plain text with aria-current='page'" do
    render_inline(described_class.new(items: items))

    expect(page).to have_css("li[aria-current='page']", text: "Booking #42")
    expect(page).not_to have_link("Booking #42")
  end

  it "renders a single-item breadcrumb with just the current page" do
    render_inline(described_class.new(items: [ { label: "Dashboard", path: nil } ]))

    expect(page).to have_css("li[aria-current='page']", text: "Dashboard")
  end
end
