# frozen_string_literal: true

module NerRuby
  class Decoder
    LABEL_MAPS = {
      "bert-base-NER" => {
        0 => "O",
        1 => "B-MISC",
        2 => "I-MISC",
        3 => "B-PER",
        4 => "I-PER",
        5 => "B-ORG",
        6 => "I-ORG",
        7 => "B-LOC",
        8 => "I-LOC"
      }
    }.freeze

    def initialize(label_map: nil)
      @label_map = label_map || LABEL_MAPS["bert-base-NER"]
    end

    def decode(tokens, predictions, scores: nil, original_text: nil)
      entities = []
      current_entity = nil

      tokens.each_with_index do |token, i|
        next if special_token?(token)

        label = @label_map[predictions[i]] || "O"
        score = scores ? scores[i] : 1.0

        if label.start_with?("B-")
          entities << build_entity(current_entity, original_text) if current_entity
          entity_type = label.sub("B-", "")
          current_entity = { raw_tokens: [token], label: entity_type, scores: [score] }
        elsif label.start_with?("I-") && current_entity
          entity_type = label.sub("I-", "")
          if entity_type == current_entity[:label]
            current_entity[:raw_tokens] << token
            current_entity[:scores] << score
          else
            entities << build_entity(current_entity, original_text)
            current_entity = nil
          end
        else
          entities << build_entity(current_entity, original_text) if current_entity
          current_entity = nil
        end
      end

      entities << build_entity(current_entity, original_text) if current_entity
      entities
    end

    private

    def special_token?(token)
      token == "[CLS]" || token == "[SEP]" || token == "[PAD]" ||
        token == "<s>" || token == "</s>" || token == "<pad>"
    end

    def clean_token(token)
      token.sub(/^##/, "")
    end

    def build_entity(entity_data, original_text = nil)
      text = merge_tokens(entity_data[:raw_tokens])
      avg_score = entity_data[:scores].sum / entity_data[:scores].size
      avg_score = avg_score.clamp(0.0, 1.0)

      start_offset = nil
      end_offset = nil

      if original_text
        idx = original_text.index(text)
        if idx
          start_offset = idx
          end_offset = idx + text.length
        end
      end

      Entity.new(
        text: text,
        label: entity_data[:label],
        start_offset: start_offset,
        end_offset: end_offset,
        score: avg_score.round(4)
      )
    end

    def merge_tokens(raw_tokens)
      result = clean_token(raw_tokens.first) || ""
      raw_tokens[1..].each do |token|
        if wordpiece?(token)
          result += clean_token(token)
        else
          result += " #{token}"
        end
      end
      result
    end

    def wordpiece?(token)
      token.start_with?("##")
    end
  end
end
