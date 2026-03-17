# frozen_string_literal: true

require_relative "ner_ruby/version"
require_relative "ner_ruby/error"
require_relative "ner_ruby/configuration"
require_relative "ner_ruby/entity"
require_relative "ner_ruby/decoder"
require_relative "ner_ruby/pipeline"
require_relative "ner_ruby/models/base"
require_relative "ner_ruby/models/onnx"
require_relative "ner_ruby/models/api"
require_relative "ner_ruby/model_registry"
require_relative "ner_ruby/model_cache"
require_relative "ner_ruby/sliding_window"
require_relative "ner_ruby/recognizer"

module NerRuby
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
