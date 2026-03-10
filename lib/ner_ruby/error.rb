# frozen_string_literal: true

module NerRuby
  class Error < StandardError; end
  class ModelNotFoundError < Error; end
  class TokenizerError < Error; end
  class InferenceError < Error; end
  class ConfigurationError < Error; end
  class ValidationError < Error; end
end
