module StyleHelper
  def btn_primary
    "inline-flex items-center justify-center rounded-lg bg-stone-900 px-5 py-2.5 text-sm font-medium text-white hover:bg-stone-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-stone-900 disabled:opacity-50"
  end

  def btn_secondary
    "inline-flex items-center justify-center rounded-lg border border-stone-300 bg-white px-5 py-2.5 text-sm font-medium text-stone-700 hover:bg-stone-50"
  end

  def btn_danger
    "inline-flex items-center justify-center rounded-lg bg-red-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-red-700"
  end

  def session_form_wrapper
    "mx-auto w-full max-w-md rounded-xl border border-stone-200 bg-white p-6 shadow-sm space-y-4"
  end

  def input_field
    "block w-full rounded-lg border border-stone-300 bg-white px-3 py-2 text-sm text-stone-900 placeholder:text-stone-400 focus:border-stone-500 focus:outline-none focus:ring-1 focus:ring-stone-500"
  end

  def form_label
    "block text-sm font-medium text-stone-700 mb-1.5"
  end

  def card
    "rounded-xl border border-stone-200 bg-white p-5 shadow-sm"
  end

  def page_container
    "mx-auto w-full max-w-2xl px-4 lg:px-8"
  end

  SLOT_STATUS_BADGE_CLASSES = {
    "open"      => "bg-green-100 text-green-800",
    "held"      => "bg-yellow-100 text-yellow-800",
    "reserved"  => "bg-blue-100 text-blue-800",
    "cancelled" => "bg-stone-100 text-stone-500"
  }.freeze

  def slot_status_badge_classes(status)
    SLOT_STATUS_BADGE_CLASSES.fetch(status, "bg-stone-100 text-stone-500")
  end

  SLOT_BUTTON_CLASSES = {
    "open"      => "rounded-lg border border-green-300 bg-green-50 px-3 py-2 text-sm font-medium text-green-800 hover:bg-green-100 cursor-pointer",
    "held"      => "rounded-lg border border-yellow-300 bg-yellow-50 px-3 py-2 text-sm font-medium text-yellow-800 cursor-not-allowed opacity-60",
    "reserved"  => "rounded-lg border border-blue-300 bg-blue-50 px-3 py-2 text-sm font-medium text-blue-800 cursor-not-allowed opacity-60",
    "cancelled" => "rounded-lg border border-stone-200 bg-stone-50 px-3 py-2 text-sm font-medium text-stone-400 cursor-not-allowed opacity-40"
  }.freeze

  def slot_button_classes(slot)
    SLOT_BUTTON_CLASSES.fetch(slot.status, "rounded-lg border border-stone-200 bg-stone-50 px-3 py-2 text-sm")
  end
end
