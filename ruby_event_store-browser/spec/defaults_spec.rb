require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    nested_app = ->(app) do
      Rack::Builder.new do
        map "/res" do
          run app
        end
      end
    end
    include Browser::IntegrationHelpers.with(host: "railseventstore.org", app: nested_app)

    it "takes path from request" do
      event_store.publish(events = 21.times.map { DummyEvent.new })
      web_client.get "/res/api/streams/all/relationships/events"

      expect(web_client.parsed_body["links"]).to eq(
        {
          "last" =>
            "http://railseventstore.org/res/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
          "next" =>
            "http://railseventstore.org/res/api/streams/all/relationships/events?page%5Bposition%5D=#{events[1].event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
        }
      )
    end

    it "builds api url based on the settings" do
      inside_app =
        RubyEventStore::Browser::App.for(
          event_store_locator: -> { event_store },
          api_url: "https://example.com/some/custom/api/url"
        )
      outside_app =
        Rack::Builder.new do
          map "/res" do
            run inside_app
          end
        end

      response = WebClient.new(outside_app, "railseventstore.org").get("/res")

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("https://example.com/some/custom/api/url")
    end

    it "passes RES version" do
      response = web_client.get "/res"

      expect(parsed_meta_content(response.body)["resVersion"]).to eq(RubyEventStore::VERSION)
    end

    it "passes root_url" do
      response = web_client.get "/res"

      expect(parsed_meta_content(response.body)["rootUrl"]).to eq("http://railseventstore.org/res")
    end

    it "default #api_url is based on root_path" do
      response = web_client.get "/res"

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    it "default JS sources are based on app_url" do
      response = web_client.get "/res"

      script_tags(response.body).each do |script|
        expect(script.attribute("src").value).to match %r{\Ahttp://railseventstore.org/res}
      end

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    it "default CSS sources are based on app_url" do
      response = web_client.get "/res"

      link_tags(response.body).each do |link|
        expect(link.attribute("href").value).to match %r{\Ahttp://railseventstore.org/res}
      end

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    def script_tags(response_body)
      Nokogiri.HTML(response_body).css("script")
    end

    def link_tags(response_body)
      Nokogiri.HTML(response_body).css("link")
    end

    def meta_content(response_body)
      Nokogiri.HTML(response_body).css("meta[name='ruby-event-store-browser-settings']").attribute("content")
    end

    def parsed_meta_content(response_body)
      JSON.parse(meta_content(response_body))
    end
  end
end
