# frozen_string_literal: true

module NerRuby
  class Entity
    attr_reader :text, :label, :start_offset, :end_offset, :score

    LABELS = %i[PER LOC ORG MISC DATE TIME MONEY PERCENT QUANTITY].freeze

    def initialize(text:, label:, start_offset: nil, end_offset: nil, score: 0.0)
      @text = text
      @label = label.to_sym
      @start_offset = start_offset
      @end_offset = end_offset
      @score = score
    end

    def person?
      label == :PER
    end

    def location?
      label == :LOC
    end

    def organization?
      label == :ORG
    end

    def to_h
      {
        text: @text,
        label: @label,
        start_offset: @start_offset,
        end_offset: @end_offset,
        score: @score
      }
    end

    def to_s
      "#{@text} [#{@label}] (#{(@score * 100).round(1)}%)"
    end
  end
end
