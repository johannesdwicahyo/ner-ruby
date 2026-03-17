# frozen_string_literal: true

module NerRuby
  class SlidingWindow
    DEFAULT_MAX_LENGTH = 512
    DEFAULT_STRIDE = 128

    def initialize(max_length: DEFAULT_MAX_LENGTH, stride: DEFAULT_STRIDE)
      @max_length = max_length
      @stride = stride
    end

    # Split tokens into overlapping windows
    def split(tokens, ids)
      return [{ tokens: tokens, ids: ids, offset: 0 }] if tokens.length <= @max_length

      windows = []
      start = 0

      while start < tokens.length
        window_end = [start + @max_length, tokens.length].min
        windows << {
          tokens: tokens[start...window_end],
          ids: ids[start...window_end],
          offset: start
        }
        break if window_end >= tokens.length
        start += @max_length - @stride
      end

      windows
    end

    # Merge entities from overlapping windows, preferring higher scores
    def merge_entities(window_results)
      all_entities = []

      window_results.each do |entities|
        entities.each do |entity|
          existing = all_entities.find { |e| overlaps?(e, entity) }
          if existing
            # Keep the one with higher score
            if entity.score > existing.score
              all_entities.delete(existing)
              all_entities << entity
            end
          else
            all_entities << entity
          end
        end
      end

      all_entities.sort_by { |e| e.start_offset || 0 }
    end

    private

    def overlaps?(a, b)
      return false unless a.start_offset && b.start_offset && a.end_offset && b.end_offset
      a.start_offset < b.end_offset && b.start_offset < a.end_offset
    end
  end
end
