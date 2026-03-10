# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module NerRuby
  module Models
    class Api < Base
      PROVIDERS = {
        openai: {
          url: "https://api.openai.com/v1/chat/completions",
          model: "gpt-4o"
        },
        huggingface: {
          url: "https://api-inference.huggingface.co/models/",
          model: "dslim/bert-base-NER"
        }
      }.freeze

      def initialize(provider: :openai, api_key: nil, model: nil)
        @provider = provider
        @api_key = api_key || ENV["#{provider.to_s.upcase}_API_KEY"]
        @model = model || PROVIDERS.dig(provider, :model)

        raise Error, "API key is required for #{provider}" unless @api_key
      end

      def recognize(text, labels: nil)
        return [] if text.nil? || text.strip.empty?

        case @provider
        when :openai then recognize_openai(text, labels: labels)
        when :huggingface then recognize_huggingface(text)
        else raise Error, "Unknown provider: #{@provider}"
        end
      end

      private

      def recognize_openai(text, labels: nil)
        label_str = (labels || Entity::LABELS).map(&:to_s).join(", ")
        prompt = <<~PROMPT
          Extract named entities from the following text. Return JSON array with objects having keys: text, label, score.
          Labels: #{label_str}
          Text: #{text}
        PROMPT

        body = {
          model: @model,
          messages: [{ role: "user", content: prompt }],
          response_format: { type: "json_object" }
        }

        response = post_json(PROVIDERS[:openai][:url], body, {
          "Authorization" => "Bearer #{@api_key}"
        })

        content = response.dig("choices", 0, "message", "content")
        parsed = JSON.parse(content)
        entities = parsed["entities"] || parsed

        entities.map do |e|
          Entity.new(
            text: e["text"],
            label: e["label"],
            score: e["score"] || 0.9
          )
        end
      end

      def recognize_huggingface(text)
        url = "#{PROVIDERS[:huggingface][:url]}#{@model}"
        response = post_json(url, { inputs: text }, {
          "Authorization" => "Bearer #{@api_key}"
        })

        response.map do |e|
          Entity.new(
            text: e["word"],
            label: e["entity_group"] || e["entity"],
            score: e["score"] || 0.0
          )
        end
      end

      def post_json(url, body, headers)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri.request_uri)
        req["Content-Type"] = "application/json"
        headers.each { |k, v| req[k] = v }
        req.body = JSON.generate(body)

        response = http.request(req)
        JSON.parse(response.body)
      end
    end
  end
end
