# frozen_string_literal: true

require_relative "../browser"
require "sinatra/base"

module RubyEventStore
  module Browser
    class App < Sinatra::Base
      def self.for(
        event_store_locator:,
        host: nil,
        path: nil,
        api_url: nil,
        environment: :production,
        related_streams_query: DEFAULT_RELATED_STREAMS_QUERY
      )
        self.tap do |app|
          app.settings.instance_exec do
            set :event_store_locator, event_store_locator
            set :related_streams_query, -> { related_streams_query }
            set :host, host
            set :root_path, path
            set :api_url, api_url
            set :environment, environment
          end
        end
      end

      use Rack::Static,
          urls: {
            "/ruby_event_store_browser.js" => "ruby_event_store_browser.js",
            "/bootstrap.js" => "bootstrap.js"
          },
          root: "#{__dir__}/../../../public"

      configure do
        set :host, nil
        set :root_path, nil
        set :api_url, nil
        set :event_store_locator, -> {  }
        set :related_streams_query, nil
        set :protection, except: :path_traversal
      end

      get "/api/events/:id" do
        begin
          json Event.new(event_store: settings.event_store_locator, event_id: params["id"])
        rescue RubyEventStore::EventNotFound
          404
        end
      end

      get "/api/streams/:stream_name" do
        json GetStream.new(
               stream_name: params["stream_name"],
               routing: routing,
               related_streams_query: settings.related_streams_query
             )
      end

      get "/api/streams/:stream_name/relationships/events" do
        json GetEventsFromStream.new(
               event_store: settings.event_store_locator,
               stream_name: params["stream_name"],
               page: params["page"],
               routing: routing
             )
      end

      get %r{/(events/.*|streams/.*)?} do
        erb(<<~ERB, locals: { path: settings.root_path || request.script_name })
          <!DOCTYPE html>
          <html>
            <head>
              <title>RubyEventStore::Browser</title>
              <meta name="ruby-event-store-browser-settings" content='<%= browser_settings %>'>
            </head>
            <body>
              <script type="text/javascript" src="<%= path %>/ruby_event_store_browser.js"></script>
              <script type="text/javascript" src="<%= path %>/bootstrap.js"></script>
            </body>
          </html>
        ERB
      end

      helpers do
        def routing
          Routing.new(settings.host || request.base_url, settings.root_path || request.script_name)
        end

        def browser_settings
          JSON.dump(
            {
              rootUrl: routing.root_url,
              apiUrl: settings.api_url || routing.api_url,
              resVersion: RubyEventStore::VERSION
            }
          )
        end

        def json(data)
          content_type "application/vnd.api+json"
          JSON.dump data.to_h
        end
      end
    end
  end
end
