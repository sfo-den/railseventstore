require 'spec_helper'
require 'action_controller/railtie'

module RailsEventStore
  RSpec.describe LinkByMetadata do

    before do
      rails = double("Rails", configuration: Rails::Application::Configuration.new)
      stub_const("Rails", rails)
      Rails.configuration.event_store = event_store
    end

    let(:event_store) { RailsEventStore::Client.new }

    specify "defaults to Rails.configuration.event_store and passes rest of options" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(
        key: :city,
        prefix: "sweet+")
      )
      event_store.publish(ev = OrderCreated.new(metadata:{
        city: "Paris",
      }))
      expect(event_store.read.stream("sweet+Paris").each.to_a).to eq([ev])
    end

  end

  RSpec.describe LinkByCorrelationId do
    before do
      rails = double("Rails", configuration: Rails::Application::Configuration.new)
      stub_const("Rails", rails)
      Rails.configuration.event_store = event_store
    end

    let(:event_store) { RailsEventStore::Client.new }
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id   = "CAU"
      end
    end

    specify "links" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new)
      event_store.publish(event)
      expect(event_store.read.stream("$by_correlation_id_COR").each.to_a).to eq([event])
    end

    specify "defaults to Rails.configuration.event_store and passes rest of options" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new(prefix: "sweet+"))
      event_store.publish(event)
      expect(event_store.read.stream("sweet+COR").each.to_a).to eq([event])
    end
  end

  RSpec.describe LinkByCausationId do
    before do
      rails = double("Rails", configuration: Rails::Application::Configuration.new)
      stub_const("Rails", rails)
      Rails.configuration.event_store = event_store
    end

    let(:event_store) { RailsEventStore::Client.new }
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id   = "CAU"
      end
    end

    specify "links" do
      event_store.subscribe_to_all_events(LinkByCausationId.new)
      event_store.publish(event)
      expect(event_store.read.stream("$by_causation_id_CAU").each.to_a).to eq([event])
    end

    specify "defaults to Rails.configuration.event_store and passes rest of options" do
      event_store.subscribe_to_all_events(LinkByCausationId.new(prefix: "sweet+"))
      event_store.publish(event)
      expect(event_store.read.stream("sweet+CAU").each.to_a).to eq([event])
    end
  end

end