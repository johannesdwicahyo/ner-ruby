# frozen_string_literal: true

module NerRuby
  class Recognizer
    @@cache = ModelCache.new

    def initialize(model: nil, tokenizer: nil, label_map: nil, backend: nil, provider: nil, api_key: nil)
      config = NerRuby.configuration

      if backend == :api
        @api_model = Models::Api.new(provider: provider || :openai, api_key: api_key)
      else
        model_path = model || config.default_model_path
        tokenizer_path = tokenizer || config.default_tokenizer_path

        if model_path && tokenizer_path
          raise ModelNotFoundError, "Model not found: #{model_path}" unless File.exist?(model_path)

          if config.enable_cache && @@cache.has?(model_path)
            cached = @@cache.get(model_path)
            @model = cached[:model]
            @tokenizer = cached[:tokenizer]
          else
            @model = Models::Onnx.new(model_path: model_path)
            @tokenizer = load_tokenizer(tokenizer_path)
            @@cache.set(model_path, { model: @model, tokenizer: @tokenizer }) if config.enable_cache
          end

          detected_label_map = label_map || @model.label_map
          @decoder = Decoder.new(label_map: detected_label_map)
          @pipeline = Pipeline.new(model: @model, tokenizer: @tokenizer, decoder: @decoder)
        end
      end
    end

    # Load a recognizer from a registered model name
    def self.from_pretrained(name)
      config = NerRuby.configuration
      model_info = config.model_registry.get(name)
      raise Error, "Unknown model: #{name}. Available: #{config.model_registry.available.join(', ')}" unless model_info

      if model_info[:model_path] && model_info[:tokenizer_path]
        new(
          model: model_info[:model_path],
          tokenizer: model_info[:tokenizer_path],
          label_map: model_info[:label_map]
        )
      else
        # API-based fallback
        new(backend: :api, provider: :huggingface)
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

      # Merge adjacent entities of the same type
      if NerRuby.configuration.merge_adjacent
        entities = merge_adjacent_entities(entities)
      end

      # Filter by labels
      if labels
        label_syms = labels.map(&:to_sym)
        entities = entities.select { |e| label_syms.include?(e.label) }
      end

      # Filter by per-type or global min_score
      filter_by_score(entities)
    end

    def recognize_batch(texts, labels: nil)
      texts.map { |text| recognize(text, labels: labels) }
    end

    def self.clear_cache
      @@cache.clear
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

    def merge_adjacent_entities(entities)
      return entities if entities.empty?

      merged = [entities.first]
      entities[1..].each do |entity|
        prev = merged.last
        if prev.label == entity.label && adjacent?(prev, entity)
          # Merge into a new entity
          merged[-1] = Entity.new(
            text: "#{prev.text} #{entity.text}",
            label: prev.label,
            start_offset: prev.start_offset,
            end_offset: entity.end_offset,
            score: ((prev.score + entity.score) / 2.0).round(4)
          )
        else
          merged << entity
        end
      end
      merged
    end

    def adjacent?(a, b)
      return true if a.end_offset && b.start_offset && (b.start_offset - a.end_offset).abs <= 1
      false
    end

    def filter_by_score(entities)
      config = NerRuby.configuration
      per_type = config.min_scores_per_type
      global_min = config.min_score

      entities.select do |e|
        threshold = per_type[e.label] || global_min
        e.score >= threshold
      end
    end
  end
end
