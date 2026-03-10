# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Stub onnx_ruby and tokenizer_ruby so tests run without native dependencies
module OnnxRuby
  class Session
    def initialize(path); end

    def run(**inputs)
      seq_len = inputs[:input_ids][0].length
      [Array.new(seq_len) { Array.new(9, 0.0) }]
    end
  end
end

module TokenizerRuby
  class Tokenizer
    def initialize(path); end

    def encode(text)
      tokens = ["[CLS]"] + text.split(/\s+/) + ["[SEP]"]
      ids = tokens.each_with_index.map { |_, i| i }
      { tokens: tokens, ids: ids }
    end
  end
end

require "ner_ruby"
require "minitest/autorun"
require "json"
