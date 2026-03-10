# frozen_string_literal: true

module NerRuby
  class Configuration
    attr_accessor :default_model_path, :default_tokenizer_path,
                  :default_labels, :min_score, :batch_size

    def initialize
      @default_model_path = nil
      @default_tokenizer_path = nil
      @default_labels = nil
      @min_score = 0.5
      @batch_size = 32
    end
  end
end
