# ner-ruby

Named Entity Recognition for Ruby using ONNX models.

## Installation

```ruby
gem "ner-ruby", "~> 0.1"
```

## Usage

```ruby
require "ner_ruby"

ner = NerRuby::Recognizer.new(
  model: "path/to/ner.onnx",
  tokenizer: "path/to/tokenizer.json"
)

entities = ner.recognize("Jokowi visited Jakarta on Monday")
# => [Entity(text: "Jokowi", label: :PER), Entity(text: "Jakarta", label: :LOC)]

entities = ner.recognize(text, labels: [:PER, :ORG])

results = ner.recognize_batch(["Text one", "Text two"])
```

## License

MIT
