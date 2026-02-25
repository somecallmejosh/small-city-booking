module ApplicationHelper
  def hour_options
    (0..23).map do |h|
      label = Time.zone.local(2000, 1, 1, h).strftime("%-I:%M %p")
      [ label, h ]
    end
  end
end
