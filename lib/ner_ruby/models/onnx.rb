# frozen_string_literal: true

require "json"

module NerRuby
  module Models
    class Onnx < Base
      attr_reader :label_map

      def initialize(model_path:)
        require "onnx_ruby"
        @model_path = model_path
        raise ModelNotFoundError, "Model not found: #{model_path}" unless File.exist?(model_path)

        @session = OnnxRuby::Session.new(model_path)
        @label_map = load_config_label_map
      end

      def predict(input_ids)
        attention_mask = Array.new(input_ids.length, 1)
        token_type_ids = Array.new(input_ids.length, 0)

        outputs = @session.run(
          input_ids: [input_ids],
          attention_mask: [attention_mask],
          token_type_ids: [token_type_ids]
        )

        outputs[0][0]
      end

      private

      def load_config_label_map
        config_path = File.join(File.dirname(@model_path), "config.json")
        return nil unless File.exist?(config_path)

        config = JSON.parse(File.read(config_path))
        id2label = config["id2label"]
        return nil unless id2label.is_a?(Hash)

        id2label.each_with_object({}) do |(k, v), map|
          map[k.to_i] = v.to_s
        end
      end
    end
  end
end
