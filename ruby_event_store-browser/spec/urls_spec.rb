require "spec_helper"

module RubyEventStore
  module Browser
    RSpec.describe Urls do
      specify do
        initial = Urls.initial
        expect(initial.app_url).to be_nil
        expect(initial.api_url).to be_nil
      end

      specify { expect(Urls.initial).to eq(Urls.initial) }
      specify { expect(Urls.initial).not_to eq(Object) }

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net"))
        with_request = Urls.initial.with_request(mocked_request)

        expect(with_request.app_url).to eq("http://example.net")
        expect(with_request.api_url).to eq("http://example.net/api")
      end

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net", script_name: "/res"))
        with_request = Urls.initial.with_request(mocked_request)

        expect(with_request.app_url).to eq("http://example.net/res")
        expect(with_request.api_url).to eq("http://example.net/res/api")
      end

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net"))
        expect(Urls.initial).not_to eq(Urls.initial.with_request(mocked_request))
      end

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net"))
        expect(Urls.initial.with_request(mocked_request)).to eq(Urls.initial.with_request(mocked_request))
      end

      specify do
        from_configuration = Urls.from_configuration("http://example.net", nil)

        expect(from_configuration.app_url).to eq("http://example.net")
        expect(from_configuration.api_url).to eq("http://example.net/api")
      end

      specify do
        from_configuration = Urls.from_configuration("http://example.net", "/res")

        expect(from_configuration.app_url).to eq("http://example.net/res")
        expect(from_configuration.api_url).to eq("http://example.net/res/api")
      end

      specify do
        from_configuration = Urls.from_configuration("http://example.net", "/res", "http://api.example.net")

        expect(from_configuration.app_url).to eq("http://example.net/res")
        expect(from_configuration.api_url).to eq("http://api.example.net")
      end

      specify do
        expect(Urls.from_configuration("http://example.net", nil)).to eq(
          Urls.from_configuration("http://example.net", nil)
        )
      end

      specify do
        expect(Urls.from_configuration("http://example.net", "/res")).not_to eq(
          Urls.from_configuration("http://example.net", nil)
        )
      end

      specify do
        expect(Urls.from_configuration("http://example.com", nil)).not_to eq(
          Urls.from_configuration("http://example.net", nil)
        )
      end

      specify do
        expect(Urls.from_configuration("http://example.net", nil, nil)).not_to eq(
          Urls.from_configuration("http://example.net", nil, "http://api.example.net")
        )
      end

      specify "paginated_events_from_stream_url" do
        routing = Urls.from_configuration("http://example.com:9393", nil)
        expect(routing.paginated_events_from_stream_url(id: "all")).to eq(
          "http://example.com:9393/api/streams/all/relationships/events"
        )
      end

      specify "passing pagination params" do
        routing = Urls.from_configuration("http://example.com:9393", nil)
        expect(
          routing.paginated_events_from_stream_url(id: "all", position: "head", direction: "forward", count: 30)
        ).to eq(
          "http://example.com:9393/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=30"
        )
      end

      specify "escaping stream name" do
        routing = Urls.from_configuration("http://example.com:9393", nil)
        expect(routing.paginated_events_from_stream_url(id: "foo/bar.xml")).to eq(
          "http://example.com:9393/api/streams/foo%2Fbar.xml/relationships/events"
        )
      end

      specify "streams_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")
        expect(routing.streams_url).to eq("http://example.com:9393/res/api/streams")
      end

      specify "events_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")
        expect(routing.events_url).to eq("http://example.com:9393/res/api/events")
      end

      specify "browser_js_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")
        expect(routing.browser_js_url).to eq("http://example.com:9393/res/ruby_event_store_browser.js")
      end

      specify "bootstrap_js_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")
        expect(routing.bootstrap_js_url).to eq("http://example.com:9393/res/bootstrap.js")
      end
    end
  end
end
