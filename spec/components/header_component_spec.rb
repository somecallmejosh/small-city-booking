require "rails_helper"

RSpec.describe HeaderComponent, type: :component do
  it "renders the logo linking to root" do
    render_inline(described_class.new)

    expect(page).to have_css("a[href='/']")
    expect(page).to have_text("Small City Studios")
  end

  it "renders the logo SVG with accessible attributes" do
    render_inline(described_class.new)

    expect(page).to have_css("svg[role='img'][aria-label='Company logo']")
  end

  it "renders desktop nav slot content inside the desktop nav element" do
    render_inline(described_class.new) do |c|
      c.with_desktop_nav { "Desktop Nav Content" }
    end

    expect(page).to have_css("nav[aria-label='Main navigation']", text: "Desktop Nav Content")
  end

  it "omits desktop nav element when slot is not provided" do
    render_inline(described_class.new)

    expect(page).not_to have_css("nav[aria-label='Main navigation']")
  end

  it "renders mobile nav slot content inside the dialog" do
    render_inline(described_class.new) do |c|
      c.with_mobile_nav { "Mobile Nav Content" }
    end

    expect(page).to have_css("[role='dialog']", text: "Mobile Nav Content", visible: false)
    expect(page).to have_css("nav[aria-label='Mobile navigation']", text: "Mobile Nav Content", visible: false)
  end

  it "hamburger button has correct initial ARIA attributes" do
    render_inline(described_class.new)

    expect(page).to have_css(
      "button[aria-expanded='false'][aria-controls='nav-mobile-menu'][aria-label='Navigation']"
    )
  end

  it "hamburger button wires to the navigation controller open action" do
    render_inline(described_class.new)

    expect(page).to have_css("button[data-action='navigation#open']")
  end

  it "mobile menu drawer is hidden by default" do
    render_inline(described_class.new)

    expect(page).to have_css("#nav-mobile-menu[hidden]", visible: false)
  end

  it "mobile menu drawer has dialog role and aria-modal" do
    render_inline(described_class.new)

    expect(page).to have_css("[role='dialog'][aria-modal='true']#nav-mobile-menu", visible: false)
  end

  it "close button inside drawer has accessible label" do
    render_inline(described_class.new)

    expect(page).to have_css("button[aria-label='Close navigation menu']", visible: false)
  end

  it "backdrop is hidden by default and marked aria-hidden" do
    render_inline(described_class.new)

    expect(page).to have_css("[data-navigation-target='backdrop'][hidden][aria-hidden='true']", visible: false)
  end

  it "header element mounts the navigation Stimulus controller" do
    render_inline(described_class.new)

    expect(page).to have_css("header[data-controller='navigation']")
  end
end
