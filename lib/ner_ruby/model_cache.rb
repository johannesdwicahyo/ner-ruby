# frozen_string_literal: true

module NerRuby
  class ModelCache
    def initialize
      @cache = {}
      @mutex = Mutex.new
    end

    def get(key)
      @mutex.synchronize { @cache[key] }
    end

    def set(key, value)
      @mutex.synchronize { @cache[key] = value }
    end

    def has?(key)
      @mutex.synchronize { @cache.key?(key) }
    end

    def clear
      @mutex.synchronize { @cache.clear }
    end

    def size
      @mutex.synchronize { @cache.size }
    end
  end
end
