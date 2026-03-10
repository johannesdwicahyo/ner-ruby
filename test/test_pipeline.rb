# frozen_string_literal: true

require_relative "test_helper"

class TestPipeline < Minitest::Test
  def test_softmax_numerical_stability_large_logits
    pipeline = NerRuby::Pipeline.new(
      model: stub_model,
      tokenizer: stub_tokenizer,
      decoder: NerRuby::Decoder.new
    )

    # Access private softmax method via send
    large_logits = [1000.0, 1001.0, 999.0, 998.0, 1000.5, 999.5, 1000.2, 999.8, 1001.5]
    result = pipeline.send(:softmax, large_logits)

    # No NaN or Infinity values
    result.each do |val|
      refute val.nan?, "softmax produced NaN for large logits"
      refute val.infinite?, "softmax produced Infinity for large logits"
      assert_operator val, :>=, 0.0
      assert_operator val, :<=, 1.0
    end

    # Should sum to approximately 1.0
    assert_in_delta 1.0, result.sum, 1e-6
  end

  def test_softmax_all_zeros
    pipeline = NerRuby::Pipeline.new(
      model: stub_model,
      tokenizer: stub_tokenizer,
      decoder: NerRuby::Decoder.new
    )

    result = pipeline.send(:softmax, [0.0, 0.0, 0.0])
    assert_in_delta 1.0, result.sum, 1e-6
    result.each { |v| assert_in_delta 1.0 / 3, v, 1e-6 }
  end

  def test_softmax_all_same_value
    pipeline = NerRuby::Pipeline.new(
      model: stub_model,
      tokenizer: stub_tokenizer,
      decoder: NerRuby::Decoder.new
    )

    result = pipeline.send(:softmax, [5.0, 5.0, 5.0, 5.0])
    assert_in_delta 1.0, result.sum, 1e-6
    result.each { |v| assert_in_delta 0.25, v, 1e-6 }
  end

  def test_softmax_negative_logits
    pipeline = NerRuby::Pipeline.new(
      model: stub_model,
      tokenizer: stub_tokenizer,
      decoder: NerRuby::Decoder.new
    )

    result = pipeline.send(:softmax, [-1000.0, -999.0, -1001.0])
    result.each do |val|
      refute val.nan?, "softmax produced NaN for negative logits"
      refute val.infinite?, "softmax produced Infinity for negative logits"
    end
    assert_in_delta 1.0, result.sum, 1e-6
  end

  def test_pipeline_passes_original_text_for_offsets
    # Use a custom model that returns known logits for a B-PER prediction
    model = Object.new
    def model.predict(input_ids)
      # Return logits where index 1 (Barack) gets B-PER (idx 3), index 2 (Obama) gets I-PER (idx 4),
      # others get O (idx 0)
      input_ids.map.with_index do |_, i|
        logits = Array.new(9, -10.0)
        case i
        when 1 then logits[3] = 10.0  # B-PER
        when 2 then logits[4] = 10.0  # I-PER
        else logits[0] = 10.0         # O
        end
        logits
      end
    end

    tokenizer = Object.new
    def tokenizer.encode(text)
      tokens = ["[CLS]"] + text.split(/\s+/) + ["[SEP]"]
      ids = tokens.each_with_index.map { |_, i| i }
      { tokens: tokens, ids: ids }
    end

    pipeline = NerRuby::Pipeline.new(model: model, tokenizer: tokenizer, decoder: NerRuby::Decoder.new)
    entities = pipeline.call("Barack Obama lives here")

    per = entities.find { |e| e.label == :PER }
    assert per
    assert_equal "Barack Obama", per.text
    assert_equal 0, per.start_offset
    assert_equal 12, per.end_offset
  end

  private

  def stub_model
    model = Object.new
    def model.predict(input_ids)
      input_ids.map { Array.new(9, 0.0) }
    end
    model
  end

  def stub_tokenizer
    tokenizer = Object.new
    def tokenizer.encode(text)
      tokens = ["[CLS]"] + text.split(/\s+/) + ["[SEP]"]
      ids = tokens.each_with_index.map { |_, i| i }
      { tokens: tokens, ids: ids }
    end
    tokenizer
  end
end
