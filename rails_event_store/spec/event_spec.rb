require 'spec_helper'

module Test
  class TestCreated < RailsEventStore::Event
  end
end

module RailsEventStore
  describe Client do

    specify 'for empty data it initializes instance with default values' do
      event = Test::TestCreated.new({})
      expect(event.event_type).to eq  'TestCreated'
      expect(event.event_id).to_not   be_nil
      expect(event.metadata).to_not   be_nil
      expect(event.data).to           be_nil

      metadata = event.metadata
      expect(metadata).to be_a Hash
      expect(metadata[:timestamp]).to be_a Time
    end

    specify 'UUID should be unique' do
      event_1 = Test::TestCreated.new({})
      event_2 = Test::TestCreated.new({})
      expect(event_1.event_id).to_not eq(event_2.event_id)
    end

    specify 'convert to hash' do
      event_data = {
          data: { data: 'sample' },
          event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd',
          event_type: 'OrderCreated',
          metadata: { meta: 'test'}
      }
      event = Test::TestCreated.new(event_data)
      expect(event.to_h).to eq event_data
    end
  end
end
