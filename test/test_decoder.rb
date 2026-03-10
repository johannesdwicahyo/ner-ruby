# frozen_string_literal: true

require_relative "test_helper"

class TestDecoder < Minitest::Test
  def setup
    @decoder = NerRuby::Decoder.new
  end

  def test_decode_simple_entities
    tokens = ["[CLS]", "Barack", "Obama", "visited", "Jakarta", "[SEP]"]
    predictions = [0, 3, 4, 0, 7, 0]
    scores = [0.1, 0.98, 0.97, 0.99, 0.95, 0.1]

    entities = @decoder.decode(tokens, predictions, scores: scores)

    assert_equal 2, entities.size

    per = entities.find { |e| e.label == :PER }
    assert per
    assert_equal "Barack Obama", per.text

    loc = entities.find { |e| e.label == :LOC }
    assert loc
    assert_equal "Jakarta", loc.text
  end

  def test_decode_no_entities
    tokens = ["[CLS]", "Hello", "world", "[SEP]"]
    predictions = [0, 0, 0, 0]

    entities = @decoder.decode(tokens, predictions)
    assert_equal 0, entities.size
  end

  def test_decode_skips_special_tokens
    tokens = ["[CLS]", "[SEP]", "[PAD]"]
    predictions = [3, 3, 3]

    entities = @decoder.decode(tokens, predictions)
    assert_equal 0, entities.size
  end

  def test_decode_adjacent_entities
    tokens = ["[CLS]", "John", "visited", "London", "[SEP]"]
    predictions = [0, 3, 0, 7, 0]

    entities = @decoder.decode(tokens, predictions)
    assert_equal 2, entities.size
    assert_equal "John", entities[0].text
    assert_equal :PER, entities[0].label
    assert_equal "London", entities[1].text
    assert_equal :LOC, entities[1].label
  end

  def test_decode_wordpiece_tokens
    tokens = ["[CLS]", "Jakarta", "##n", "[SEP]"]
    predictions = [0, 7, 8, 0]

    entities = @decoder.decode(tokens, predictions)
    assert_equal 1, entities.size
    assert_equal "Jakartan", entities[0].text
  end

  # --- Entity character span offsets ---

  def test_entity_offsets_with_original_text
    tokens = ["[CLS]", "Barack", "Obama", "visited", "Jakarta", "[SEP]"]
    predictions = [0, 3, 4, 0, 7, 0]
    scores = [0.1, 0.98, 0.97, 0.99, 0.95, 0.1]
    original_text = "Barack Obama visited Jakarta"

    entities = @decoder.decode(tokens, predictions, scores: scores, original_text: original_text)

    per = entities.find { |e| e.label == :PER }
    assert_equal 0, per.start_offset
    assert_equal 12, per.end_offset
    assert_equal "Barack Obama", original_text[per.start_offset...per.end_offset]

    loc = entities.find { |e| e.label == :LOC }
    assert_equal 21, loc.start_offset
    assert_equal 28, loc.end_offset
    assert_equal "Jakarta", original_text[loc.start_offset...loc.end_offset]
  end

  def test_entity_offsets_nil_without_original_text
    tokens = ["[CLS]", "John", "[SEP]"]
    predictions = [0, 3, 0]

    entities = @decoder.decode(tokens, predictions)
    assert_equal 1, entities.size
    assert_nil entities[0].start_offset
    assert_nil entities[0].end_offset
  end

  # --- Score clamping ---

  def test_score_clamping
    tokens = ["[CLS]", "Test", "[SEP]"]
    predictions = [0, 3, 0]
    scores = [0.0, 1.0, 0.0]

    entities = @decoder.decode(tokens, predictions, scores: scores)
    assert_equal 1, entities.size
    assert_operator entities[0].score, :<=, 1.0
    assert_operator entities[0].score, :>=, 0.0
  end
end
