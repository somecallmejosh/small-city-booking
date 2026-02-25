class BreadcrumbComponent < ViewComponent::Base
  # items: Array of { label: String, path: String } hashes.
  # The last item is the current page and renders without a link.
  def initialize(items:)
    @items = items
  end
end
