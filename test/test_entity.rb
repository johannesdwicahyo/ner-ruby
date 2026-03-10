# frozen_string_literal: true

require_relative "test_helper"

class TestEntity < Minitest::Test
  def test_entity_creation
    entity = NerRuby::Entity.new(text: "Jakarta", label: :LOC, score: 0.95)
    assert_equal "Jakarta", entity.text
    assert_equal :LOC, entity.label
    assert_equal 0.95, entity.score
  end

  def test_entity_predicates
    per = NerRuby::Entity.new(text: "Jokowi", label: :PER, score: 0.98)
    assert per.person?
    refute per.location?
    refute per.organization?

    loc = NerRuby::Entity.new(text: "Jakarta", label: :LOC, score: 0.95)
    assert loc.location?

    org = NerRuby::Entity.new(text: "Google", label: :ORG, score: 0.92)
    assert org.organization?
  end

  def test_to_h
    entity = NerRuby::Entity.new(text: "Google", label: :ORG, score: 0.92)
    hash = entity.to_h
    assert_equal "Google", hash[:text]
    assert_equal :ORG, hash[:label]
    assert_equal 0.92, hash[:score]
  end

  def test_to_s
    entity = NerRuby::Entity.new(text: "Jakarta", label: :LOC, score: 0.95)
    assert_equal "Jakarta [LOC] (95.0%)", entity.to_s
  end

  def test_string_label_coerced_to_symbol
    entity = NerRuby::Entity.new(text: "Test", label: "PER", score: 0.9)
    assert_equal :PER, entity.label
  end
end
