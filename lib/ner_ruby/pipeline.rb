# frozen_string_literal: true

module NerRuby
  class Pipeline
    def initialize(model:, tokenizer:, decoder: nil)
      @model = model
      @tokenizer = tokenizer
      @decoder = decoder || Decoder.new
    end

    def call(text)
      encoding = @tokenizer.encode(text)
      tokens = encoding[:tokens] || encoding["tokens"]
      input_ids = encoding[:ids] || encoding["ids"]

      logits = @model.predict(input_ids)

      predictions = logits.map { |row| row.each_with_index.max_by { |v, _| v }.last }
      scores = logits.map { |row| softmax(row).max }

      @decoder.decode(tokens, predictions, scores: scores, original_text: text)
    end

    private

    def softmax(logits)
      max = logits.max
      exps = logits.map { |x| Math.exp(x - max) }
      sum = exps.sum
      exps.map { |x| (x / sum).clamp(0.0, 1.0) }
    end
  end
end
