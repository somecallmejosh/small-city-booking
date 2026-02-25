class BulkSlotCreator
  Result = Data.define(:created_count, :skipped_count, :errors)

  def initialize(days_of_week:, start_date:, end_date:, start_hour:, end_hour:)
    @days_of_week = days_of_week.map(&:to_i)
    @start_date   = start_date
    @end_date     = end_date
    @start_hour   = start_hour.to_i
    @end_hour     = end_hour.to_i
  end

  def call
    created = 0
    skipped = 0
    errors  = []

    (@start_date..@end_date).each do |date|
      next unless @days_of_week.include?(date.wday)

      timestamps_for(date).each do |starts_at|
        if active_slot_exists?(starts_at)
          skipped += 1
        elsif Slot.create(starts_at: starts_at, status: "open").persisted?
          created += 1
        else
          errors << "Could not create slot for #{starts_at.strftime('%b %-d at %-I:%M %p')}"
        end
      end
    end

    Result.new(created_count: created, skipped_count: skipped, errors: errors)
  end

  private

    def timestamps_for(date)
      if @start_hour < @end_hour
        (@start_hour...@end_hour).map { |h| Time.zone.local(date.year, date.month, date.day, h) }
      else
        # Overnight: e.g. 22 → 2 spans midnight into the next calendar day
        same_day = (@start_hour..23).map { |h| Time.zone.local(date.year, date.month, date.day, h) }
        next_day = date + 1
        overflow = (0...@end_hour).map { |h| Time.zone.local(next_day.year, next_day.month, next_day.day, h) }
        same_day + overflow
      end
    end

    def active_slot_exists?(starts_at)
      Slot.where(starts_at: starts_at).where.not(status: "cancelled").exists?
    end
end
