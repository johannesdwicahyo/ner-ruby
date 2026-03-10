# frozen_string_literal: true

require_relative "test_helper"

class TestRecognizer < Minitest::Test
  def setup
    NerRuby.reset_configuration!
  end

  def test_recognizer_requires_model
    recognizer = NerRuby::Recognizer.new
    assert_raises(NerRuby::Error) do
      recognizer.recognize("Some text")
    end
  end

  def test_pipeline_integration
    pipeline = Object.new
    def pipeline.call(text)
      [
        NerRuby::Entity.new(text: "Jokowi", label: :PER, score: 0.98),
        NerRuby::Entity.new(text: "Jakarta", label: :LOC, score: 0.95)
      ]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    entities = recognizer.recognize("Jokowi visited Jakarta")
    assert_equal 2, entities.size
    assert_equal "Jokowi", entities[0].text
    assert_equal :PER, entities[0].label
  end

  def test_filter_by_labels
    pipeline = Object.new
    def pipeline.call(text)
      [
        NerRuby::Entity.new(text: "Jokowi", label: :PER, score: 0.98),
        NerRuby::Entity.new(text: "Jakarta", label: :LOC, score: 0.95)
      ]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    entities = recognizer.recognize("text", labels: [:PER])
    assert_equal 1, entities.size
    assert_equal :PER, entities[0].label
  end

  def test_filter_by_min_score
    NerRuby.configure { |c| c.min_score = 0.96 }

    pipeline = Object.new
    def pipeline.call(text)
      [
        NerRuby::Entity.new(text: "Jokowi", label: :PER, score: 0.98),
        NerRuby::Entity.new(text: "Jakarta", label: :LOC, score: 0.95)
      ]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    entities = recognizer.recognize("text")
    assert_equal 1, entities.size
    assert_equal "Jokowi", entities[0].text
  end

  def test_recognize_batch
    pipeline = Object.new
    def pipeline.call(text)
      [NerRuby::Entity.new(text: "Test", label: :PER, score: 0.9)]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    results = recognizer.recognize_batch(["Text 1", "Text 2"])
    assert_equal 2, results.size
    assert results.all? { |r| r.is_a?(Array) }
  end

  # --- Empty / nil text guard ---

  def test_nil_text_returns_empty_array
    pipeline = Object.new
    def pipeline.call(text)
      [NerRuby::Entity.new(text: "Test", label: :PER, score: 0.9)]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    assert_equal [], recognizer.recognize(nil)
  end

  def test_empty_text_returns_empty_array
    pipeline = Object.new
    def pipeline.call(text)
      [NerRuby::Entity.new(text: "Test", label: :PER, score: 0.9)]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    assert_equal [], recognizer.recognize("")
  end

  def test_whitespace_only_text_returns_empty_array
    pipeline = Object.new
    def pipeline.call(text)
      [NerRuby::Entity.new(text: "Test", label: :PER, score: 0.9)]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    assert_equal [], recognizer.recognize("   ")
  end

  # --- API backend initialization ---

  def test_api_backend_initialization
    recognizer = NerRuby::Recognizer.new(backend: :api, provider: :openai, api_key: "test-key")
    api_model = recognizer.instance_variable_get(:@api_model)
    assert_instance_of NerRuby::Models::Api, api_model
  end

  def test_api_backend_requires_api_key
    assert_raises(NerRuby::Error) do
      # Clear env var to ensure no fallback
      original = ENV["OPENAI_API_KEY"]
      ENV["OPENAI_API_KEY"] = nil
      begin
        NerRuby::Recognizer.new(backend: :api, provider: :openai)
      ensure
        ENV["OPENAI_API_KEY"] = original
      end
    end
  end

  def test_api_backend_empty_text_returns_empty_array
    recognizer = NerRuby::Recognizer.new(backend: :api, provider: :openai, api_key: "test-key")
    assert_equal [], recognizer.recognize("")
    assert_equal [], recognizer.recognize(nil)
  end

  # --- Input validation ---

  def test_validate_labels_must_be_array
    pipeline = Object.new
    def pipeline.call(text)
      [NerRuby::Entity.new(text: "Test", label: :PER, score: 0.9)]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    assert_raises(NerRuby::ValidationError) do
      recognizer.recognize("text", labels: "PER")
    end
  end

  def test_validate_labels_must_contain_symbols_or_strings
    pipeline = Object.new
    def pipeline.call(text)
      [NerRuby::Entity.new(text: "Test", label: :PER, score: 0.9)]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    assert_raises(NerRuby::ValidationError) do
      recognizer.recognize("text", labels: [123])
    end
  end

  def test_validate_labels_accepts_strings
    pipeline = Object.new
    def pipeline.call(text)
      [NerRuby::Entity.new(text: "Test", label: :PER, score: 0.9)]
    end

    recognizer = NerRuby::Recognizer.new
    recognizer.instance_variable_set(:@pipeline, pipeline)

    entities = recognizer.recognize("text", labels: ["PER"])
    assert_equal 1, entities.size
  end

  def test_model_not_found_raises_error
    assert_raises(NerRuby::ModelNotFoundError) do
      NerRuby::Recognizer.new(model: "/nonexistent/model.onnx", tokenizer: "/nonexistent/tokenizer.json")
    end
  end
end
