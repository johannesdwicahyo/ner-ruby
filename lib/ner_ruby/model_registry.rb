# frozen_string_literal: true

module NerRuby
  class ModelRegistry
    BUILT_IN = {
      english: {
        repo_id: "dslim/bert-base-NER",
        model_file: "model.onnx",
        tokenizer: "dslim/bert-base-NER",
        label_map: { 0 => "O", 1 => "B-MISC", 2 => "I-MISC", 3 => "B-PER",
                     4 => "I-PER", 5 => "B-ORG", 6 => "I-ORG", 7 => "B-LOC", 8 => "I-LOC" }
      },
      indonesian: {
        repo_id: "cahya/bert-base-indonesian-NER",
        model_file: "model.onnx",
        tokenizer: "cahya/bert-base-indonesian-NER",
        label_map: { 0 => "O", 1 => "B-PER", 2 => "I-PER", 3 => "B-LOC",
                     4 => "I-LOC", 5 => "B-ORG", 6 => "I-ORG" }
      },
      multilingual: {
        repo_id: "Davlan/bert-base-multilingual-cased-ner-hrl",
        model_file: "model.onnx",
        tokenizer: "Davlan/bert-base-multilingual-cased-ner-hrl",
        label_map: { 0 => "O", 1 => "B-PER", 2 => "I-PER", 3 => "B-ORG",
                     4 => "I-ORG", 5 => "B-LOC", 6 => "I-LOC", 7 => "B-DATE", 8 => "I-DATE" }
      }
    }.freeze

    def initialize
      @custom = {}
    end

    def register(name, repo_id: nil, model_path: nil, tokenizer_path: nil, label_map: nil)
      @custom[name.to_sym] = {
        repo_id: repo_id,
        model_path: model_path,
        tokenizer_path: tokenizer_path,
        label_map: label_map
      }
    end

    def get(name)
      @custom[name.to_sym] || BUILT_IN[name.to_sym]
    end

    def available
      (BUILT_IN.keys + @custom.keys).uniq
    end
  end
end
