# frozen_string_literal: true

require_relative 'shipping/application_record'
require_relative '../../lib/event'
require_relative '../../lib/types'
require_relative '../../lib/command'
require_relative '../../lib/command_handler'

require_dependency 'shipping/package_shipped'

require_dependency 'shipping/ship_package'

require_dependency 'shipping/on_ship_package'

require_dependency 'shipping/package'
require_dependency 'shipping/shipping_process'

module Shipping
  def self.setup(config)
    @@command_bus = config.command_bus
    @@public_event_store = RailsEventStore::Client.new(
      repository: config.event_repository,
      mapper: RubyEventStore::Mappers::Default.new(
        serializer: JSON,
        events_class_remapping: events_class_remapping
      )
    )
    @@module_event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(
        Shipping::ApplicationRecord),
      mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
    )

    # Subscribe public event handlers below
    public_event_store.tap do |store|
      store.subscribe(ShippingProcess.new(command_bus), to: ['new-order'])
      store.subscribe(ShippingProcess.new(command_bus), to: ['payment-completed'])
    end

    # Subscribe private event handlers below
    event_store.tap do |store|
    end

    # Register commands handled by this module below
    command_bus.tap do |bus|
      bus.register(Shipping::ShipPackage, Shipping::OnShipPackage.new(event_store))
    end
  end

  def self.events_class_remapping
    {
      'new-order' => 'Shipping::OrderPlaced',
      'payment-completed' => 'Shipping::OrderPaid',
    }
  end

  def self.command_bus
    @@command_bus
  end

  def self.public_event_store
    @@public_event_store
  end

  def self.event_store
    @@module_event_store
  end

  def self.setup?
    command_bus && event_store && public_event_store
  end

  class OrderPlaced < Event
    event_type 'new-order'
    attribute :order_id, Types::UUID
  end

  class OrderPaid < Event
    event_type 'payment-completed'
    attribute :order_id, Types::UUID
  end
end
