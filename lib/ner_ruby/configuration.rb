# frozen_string_literal: true

module NerRuby
  class Configuration
    attr_accessor :default_model_path, :default_tokenizer_path,
                  :default_labels, :min_score, :batch_size,
                  :min_scores_per_type, :enable_cache,
                  :max_length, :stride, :merge_adjacent

    def initialize
      @default_model_path = nil
      @default_tokenizer_path = nil
      @default_labels = nil
      @min_score = 0.5
      @batch_size = 32
      @min_scores_per_type = {}
      @enable_cache = true
      @max_length = 512
      @stride = 128
      @merge_adjacent = true
    end

    def model_registry
      @model_registry ||= ModelRegistry.new
    end

    def register_model(name, **opts)
      model_registry.register(name, **opts)
    end
  end
end
