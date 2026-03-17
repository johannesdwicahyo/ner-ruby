# frozen_string_literal: true

require_relative "test_helper"

# --- Model Registry Tests ---

class TestModelRegistry < Minitest::Test
  def test_built_in_models
    registry = NerRuby::ModelRegistry.new
    assert registry.get(:english)
    assert registry.get(:indonesian)
    assert registry.get(:multilingual)
  end

  def test_register_custom_model
    registry = NerRuby::ModelRegistry.new
    registry.register(:custom, model_path: "/path/model.onnx", tokenizer_path: "/path/tokenizer")
    model = registry.get(:custom)
    assert_equal "/path/model.onnx", model[:model_path]
  end

  def test_available_models
    registry = NerRuby::ModelRegistry.new
    available = registry.available
    assert_includes available, :english
    assert_includes available, :indonesian
    assert_includes available, :multilingual
  end

  def test_custom_overrides_builtin
    registry = NerRuby::ModelRegistry.new
    registry.register(:english, model_path: "/custom/model.onnx")
    model = registry.get(:english)
    assert_equal "/custom/model.onnx", model[:model_path]
  end

  def test_unknown_model_returns_nil
    registry = NerRuby::ModelRegistry.new
    assert_nil registry.get(:nonexistent)
  end
end

# --- Model Cache Tests ---

class TestModelCache < Minitest::Test
  def test_set_and_get
    cache = NerRuby::ModelCache.new
    cache.set("key1", { model: "test" })
    assert_equal({ model: "test" }, cache.get("key1"))
  end

  def test_has
    cache = NerRuby::ModelCache.new
    refute cache.has?("key1")
    cache.set("key1", "value")
    assert cache.has?("key1")
  end

  def test_clear
    cache = NerRuby::ModelCache.new
    cache.set("key1", "v1")
    cache.set("key2", "v2")
    assert_equal 2, cache.size
    cache.clear
    assert_equal 0, cache.size
  end
end

# --- Sliding Window Tests ---

class TestSlidingWindow < Minitest::Test
  def test_short_text_single_window
    sw = NerRuby::SlidingWindow.new(max_length: 10, stride: 3)
    tokens = %w[a b c d e]
    ids = [0, 1, 2, 3, 4]
    windows = sw.split(tokens, ids)
    assert_equal 1, windows.size
    assert_equal tokens, windows[0][:tokens]
  end

  def test_long_text_splits
    sw = NerRuby::SlidingWindow.new(max_length: 4, stride: 2)
    tokens = %w[a b c d e f g h]
    ids = (0..7).to_a
    windows = sw.split(tokens, ids)
    assert windows.size > 1
    assert_equal %w[a b c d], windows[0][:tokens]
    assert_equal 0, windows[0][:offset]
  end

  def test_merge_entities_deduplicates
    sw = NerRuby::SlidingWindow.new
    e1 = NerRuby::Entity.new(text: "John", label: "PER", start_offset: 0, end_offset: 4, score: 0.9)
    e2 = NerRuby::Entity.new(text: "John", label: "PER", start_offset: 0, end_offset: 4, score: 0.95)

    merged = sw.merge_entities([[e1], [e2]])
    assert_equal 1, merged.size
    assert_equal 0.95, merged[0].score  # Higher score wins
  end

  def test_merge_non_overlapping
    sw = NerRuby::SlidingWindow.new
    e1 = NerRuby::Entity.new(text: "John", label: "PER", start_offset: 0, end_offset: 4, score: 0.9)
    e2 = NerRuby::Entity.new(text: "London", label: "LOC", start_offset: 20, end_offset: 26, score: 0.8)

    merged = sw.merge_entities([[e1], [e2]])
    assert_equal 2, merged.size
  end
end

# --- Per-Type Thresholds ---

class TestPerTypeThresholds < Minitest::Test
  def setup
    NerRuby.reset_configuration!
  end

  def test_per_type_min_score
    NerRuby.configure do |c|
      c.min_score = 0.5
      c.min_scores_per_type = { PER: 0.9, LOC: 0.3 }
    end

    config = NerRuby.configuration
    assert_equal 0.9, config.min_scores_per_type[:PER]
    assert_equal 0.3, config.min_scores_per_type[:LOC]
  ensure
    NerRuby.reset_configuration!
  end
end

# --- Configuration Extensions ---

class TestConfigurationV020 < Minitest::Test
  def setup
    NerRuby.reset_configuration!
  end

  def test_defaults
    config = NerRuby.configuration
    assert_equal true, config.enable_cache
    assert_equal 512, config.max_length
    assert_equal 128, config.stride
    assert_equal true, config.merge_adjacent
    assert_equal({}, config.min_scores_per_type)
  end

  def test_model_registry_accessible
    config = NerRuby.configuration
    assert_instance_of NerRuby::ModelRegistry, config.model_registry
  end

  def test_register_model
    NerRuby.configure do |c|
      c.register_model(:test_model, model_path: "/test.onnx")
    end

    model = NerRuby.configuration.model_registry.get(:test_model)
    assert_equal "/test.onnx", model[:model_path]
  ensure
    NerRuby.reset_configuration!
  end
end

# --- Entity Merging ---

class TestEntityMerging < Minitest::Test
  def test_merge_adjacent_same_type
    entities = [
      NerRuby::Entity.new(text: "New", label: "LOC", start_offset: 0, end_offset: 3, score: 0.8),
      NerRuby::Entity.new(text: "York", label: "LOC", start_offset: 4, end_offset: 8, score: 0.85)
    ]

    # Test the merge logic directly via a temporary recognizer instance with API backend
    recognizer = NerRuby::Recognizer.new(backend: :api, api_key: "test")
    merged = recognizer.send(:merge_adjacent_entities, entities)
    assert_equal 1, merged.size
    assert_equal "New York", merged[0].text
    assert_equal :LOC, merged[0].label
  end

  def test_no_merge_different_types
    entities = [
      NerRuby::Entity.new(text: "John", label: "PER", start_offset: 0, end_offset: 4, score: 0.9),
      NerRuby::Entity.new(text: "London", label: "LOC", start_offset: 10, end_offset: 16, score: 0.8)
    ]

    recognizer = NerRuby::Recognizer.new(backend: :api, api_key: "test")
    merged = recognizer.send(:merge_adjacent_entities, entities)
    assert_equal 2, merged.size
  end

  def test_merge_empty_list
    recognizer = NerRuby::Recognizer.new(backend: :api, api_key: "test")
    merged = recognizer.send(:merge_adjacent_entities, [])
    assert_equal [], merged
  end
end

# --- From Pretrained ---

class TestFromPretrained < Minitest::Test
  def test_unknown_model_raises
    NerRuby.reset_configuration!
    assert_raises(NerRuby::Error) do
      NerRuby::Recognizer.from_pretrained(:nonexistent)
    end
  ensure
    NerRuby.reset_configuration!
  end

  def test_built_in_models_exist_in_registry
    NerRuby.reset_configuration!
    registry = NerRuby.configuration.model_registry
    assert registry.get(:english)
    assert registry.get(:indonesian)
    assert registry.get(:multilingual)
  ensure
    NerRuby.reset_configuration!
  end
end

# --- Batch Processing ---

class TestBatchProcessing < Minitest::Test
  def setup
    NerRuby.reset_configuration!
    NerRuby.configure { |c| c.min_score = 0.0 }
  end

  def teardown
    NerRuby.reset_configuration!
  end

  def test_batch_with_nil_and_empty
    # Use API backend to avoid ONNX model loading
    recognizer = NerRuby::Recognizer.new(backend: :api, api_key: "test")
    results = recognizer.recognize_batch([nil, ""])
    assert_equal 2, results.size
    assert_equal [], results[0]
    assert_equal [], results[1]
  end
end

# --- Cache ---

class TestRecognizerCache < Minitest::Test
  def test_clear_cache
    NerRuby::Recognizer.clear_cache
    # Should not raise
    assert true
  end
end
