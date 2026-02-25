require "rails_helper"

RSpec.describe BulkSlotCreator do
  subject(:creator) do
    described_class.new(
      days_of_week: days_of_week,
      start_date:   start_date,
      end_date:     end_date,
      start_hour:   start_hour,
      end_hour:     end_hour
    )
  end

  let(:monday)   { Date.today.next_occurring(:monday) }
  let(:wednesday) { monday + 2 }

  describe "#call" do
    context "with a normal (same-day) time range" do
      let(:days_of_week) { [ 1, 3 ] } # Mon and Wed
      let(:start_date)   { monday }
      let(:end_date)     { monday + 6 } # one full week
      let(:start_hour)   { 15 }
      let(:end_hour)     { 18 }

      it "creates 6 slots (3 per day × 2 days)" do
        result = creator.call
        expect(result.created_count).to eq(6)
        expect(result.skipped_count).to eq(0)
        expect(Slot.count).to eq(6)
      end

      it "does not create slots on non-selected days" do
        creator.call
        tuesday_slots = Slot.where("starts_at >= ? AND starts_at < ?", monday + 1, monday + 2)
        expect(tuesday_slots.count).to eq(0)
      end

      it "creates slots with status open" do
        creator.call
        expect(Slot.pluck(:status).uniq).to eq([ "open" ])
      end
    end

    context "with an overnight time range" do
      let(:days_of_week) { [ friday_wday ] }
      let(:friday)        { Date.today.next_occurring(:friday) }
      let(:friday_wday)   { 5 }
      let(:start_date)    { friday }
      let(:end_date)      { friday }
      let(:start_hour)    { 22 }
      let(:end_hour)      { 2 } # 22:00, 23:00 on Fri; 00:00, 01:00 on Sat

      it "creates 4 slots spanning midnight" do
        result = creator.call
        expect(result.created_count).to eq(4)
      end

      it "creates the correct timestamps" do
        creator.call
        times = Slot.order(:starts_at).pluck(:starts_at).map { |t| [ t.wday, t.hour ] }
        expect(times).to eq([
          [ 5, 22 ],
          [ 5, 23 ],
          [ 6, 0  ],
          [ 6, 1  ]
        ])
      end
    end

    context "when duplicate slots exist" do
      let(:days_of_week) { [ 1 ] } # Monday only
      let(:start_date)   { monday }
      let(:end_date)     { monday }
      let(:start_hour)   { 15 }
      let(:end_hour)     { 17 }

      before do
        # Pre-create an open slot at 15:00
        Slot.create!(starts_at: Time.zone.local(monday.year, monday.month, monday.day, 15), status: "open")
      end

      it "skips the duplicate and creates only the non-duplicate" do
        result = creator.call
        expect(result.created_count).to eq(1)
        expect(result.skipped_count).to eq(1)
        expect(Slot.count).to eq(2)
      end
    end

    context "when a cancelled slot exists at the same time" do
      let(:days_of_week) { [ 1 ] }
      let(:start_date)   { monday }
      let(:end_date)     { monday }
      let(:start_hour)   { 10 }
      let(:end_hour)     { 11 }

      before do
        Slot.create!(starts_at: Time.zone.local(monday.year, monday.month, monday.day, 10), status: "cancelled")
      end

      it "creates a new slot (cancelled slots do not block re-creation)" do
        result = creator.call
        expect(result.created_count).to eq(1)
        expect(result.skipped_count).to eq(0)
      end
    end
  end
end
