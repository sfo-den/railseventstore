# frozen_string_literal: true

require_relative "../browser"
require "rack"
require "erb"
require "json"

module RubyEventStore
  module Browser
    class Router
      NoMatch = Class.new(StandardError)

      class Route
        NAMED_SEGMENTS_PATTERN = %r{\/([^\/]*):([^:$\/]+)}.freeze
        private_constant :NAMED_SEGMENTS_PATTERN

        def initialize(request_method, pattern, &block)
          @request_method = request_method
          @pattern = pattern
          @handler = block
        end

        def match(request)
          return unless request.request_method.eql?(request_method)

          match_data = regexp.match(File.join("/", request.path_info))
          match_data.named_captures.transform_values { |v| Rack::Utils.unescape(v) } if match_data
        end

        def call(params)
          handler[params]
        end

        private

        def regexp
          /\A#{pattern.gsub(NAMED_SEGMENTS_PATTERN, '/\1(?<\2>[^$/]+)')}\Z/
        end

        attr_reader :request_method, :pattern, :handler
      end

      def initialize
        @routes = Array.new
      end

      def add_route(request_method, pattern, &block)
        routes << Route.new(request_method, pattern, &block)
      end

      def handle(request)
        routes.each do |route|
          route_params = route.match(request)
          return route.call(request.params.merge(route_params)) if route_params
        end
        raise NoMatch
      end

      private

      attr_reader :routes
    end

    class App
      def self.for(
        event_store_locator:,
        host: nil,
        path: nil,
        api_url: nil,
        environment: nil,
        related_streams_query: DEFAULT_RELATED_STREAMS_QUERY
      )
        Rack::Builder.new do
          use Rack::Static,
              urls: {
                "/ruby_event_store_browser.js" => "ruby_event_store_browser.js",
                "/bootstrap.js" => "bootstrap.js"
              },
              root: "#{__dir__}/../../../public"
          run App.new(
                event_store_locator: event_store_locator,
                related_streams_query: related_streams_query,
                host: host,
                root_path: path,
                api_url: api_url
              )
        end
      end

      def initialize(event_store_locator:, related_streams_query:, host:, root_path:, api_url:)
        @event_store_locator = event_store_locator
        @related_streams_query = related_streams_query
        @host = host
        @root_path = root_path
        @api_url = api_url
      end

      def call(env)
        request = Rack::Request.new(env)
        routing = Routing.new(host || request.base_url, root_path || request.script_name)

        router = Router.new
        router.add_route("GET", "/api/events/:event_id") do |params|
          json Event.new(event_store: event_store, event_id: params.fetch("event_id"))
        end
        router.add_route("GET", "/api/streams/:stream_name") do |params|
          json GetStream.new(
                 stream_name: params.fetch("stream_name"),
                 routing: routing,
                 related_streams_query: related_streams_query
               )
        end
        router.add_route("GET", "/api/streams/:stream_name/relationships/events") do |params|
          json GetEventsFromStream.new(
                 event_store: event_store,
                 routing: routing,
                 stream_name: params.fetch("stream_name"),
                 page: params["page"]
               )
        end
        %w[/ /events/:event_id /streams/:stream_name].each do |starting_route|
          router.add_route("GET", starting_route) do
            erb bootstrap_html, root_path: routing.root_path, settings: settings(routing)
          end
        end
        router.handle(request)
      rescue EventNotFound, Router::NoMatch
        not_found
      end

      private

      attr_reader :event_store_locator, :related_streams_query, :host, :root_path, :api_url

      def event_store
        event_store_locator.call
      end

      def bootstrap_html
        <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>RubyEventStore::Browser</title>
            <meta name="ruby-event-store-browser-settings" content="<%= Rack::Utils.escape_html(JSON.dump(settings)) %>">
          </head>
          <body>
            <script type="text/javascript" src="<%= root_path %>/ruby_event_store_browser.js"></script>
            <script type="text/javascript" src="<%= root_path %>/bootstrap.js"></script>
          </body>
        </html>
        HTML
      end

      def not_found
        [404, {}, []]
      end

      def json(body)
        [200, { "Content-Type" => "application/vnd.api+json" }, [JSON.dump(body.to_h)]]
      end

      def erb(template, **locals)
        [200, { "Content-Type" => "text/html;charset=utf-8" }, [ERB.new(template).result_with_hash(locals)]]
      end

      def settings(routing)
        { rootUrl: routing.root_url, apiUrl: api_url || routing.api_url, resVersion: res_version }
      end

      def res_version
        RubyEventStore::VERSION
      end
    end
  end
end
