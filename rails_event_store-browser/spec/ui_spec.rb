require 'spec_helper'

FooBarEvent = Class.new(::RailsEventStore::Event)

module RailsEventStore
  RSpec.describe Browser, type: :feature, js: true do
    include SchemaHelper

    def silence_stderr
      $stderr = StringIO.new
      yield
      $stderr = STDERR
    end

    around(:each) do |example|
      begin
        load_database_schema
        silence_stderr { example.run }
      end
    end

    specify "main view", mutant: false do
      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: 'dummy')

      visit('/res')
      
      expect(page).to have_content("Events in all")

      within('.browser__results') do
        click_on 'FooBarEvent'
      end

      within('.event__body') do
        expect(page).to have_content(foo_bar_event.event_id)
        expect(page).to have_content(%Q[timestamp: "#{foo_bar_event.metadata[:timestamp].as_json}" ])
        expect(page).to have_content(%Q[foo: "bar"])
      end
    end

    specify "stream view", mutant: false do
      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: 'foo/bar.xml')

      visit('/res/#streams/foo%2Fbar.xml')
      
      expect(page).to have_content("Events in foo/bar.xml")

      within('.browser__results') do
        click_on 'FooBarEvent'
      end

      within('.event__body') do
        expect(page).to have_content(foo_bar_event.event_id)
        expect(page).to have_content(%Q[timestamp: "#{foo_bar_event.metadata[:timestamp].as_json}"])
        expect(page).to have_content(%Q[foo: "bar"])
      end
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
