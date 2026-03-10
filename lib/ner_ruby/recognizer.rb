# frozen_string_literal: true

module NerRuby
  class Recognizer
    def initialize(model: nil, tokenizer: nil, label_map: nil, backend: nil, provider: nil, api_key: nil)
      config = NerRuby.configuration

      if backend == :api
        @api_model = Models::Api.new(provider: provider || :openai, api_key: api_key)
      else
        model_path = model || config.default_model_path
        tokenizer_path = tokenizer || config.default_tokenizer_path

        if model_path && tokenizer_path
          raise ModelNotFoundError, "Model not found: #{model_path}" unless File.exist?(model_path)

          @model = Models::Onnx.new(model_path: model_path)
          @tokenizer = load_tokenizer(tokenizer_path)
          detected_label_map = label_map || @model.label_map
          @decoder = Decoder.new(label_map: detected_label_map)
          @pipeline = Pipeline.new(model: @model, tokenizer: @tokenizer, decoder: @decoder)
        end
      end
    end

    def recognize(text, labels: nil)
      return [] if text.nil? || text.strip.empty?
      validate_labels!(labels) if labels

      if @api_model
        entities = @api_model.recognize(text, labels: labels)
      else
        raise Error, "No model loaded. Provide model and tokenizer paths." unless @pipeline
        entities = @pipeline.call(text)
      end

      if labels
        label_syms = labels.map(&:to_sym)
        entities = entities.select { |e| label_syms.include?(e.label) }
      end

      min = NerRuby.configuration.min_score
      entities.select { |e| e.score >= min }
    end

    def recognize_batch(texts, labels: nil)
      texts.map { |text| recognize(text, labels: labels) }
    end

    private

    def load_tokenizer(path)
      require "tokenizer_ruby"
      TokenizerRuby::Tokenizer.new(path)
    end

    def validate_labels!(labels)
      unless labels.is_a?(Array) && labels.all? { |l| l.is_a?(Symbol) || l.is_a?(String) }
        raise ValidationError, "labels must be an array of symbols or strings"
      end
    end
  end
end
