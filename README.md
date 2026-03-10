# ner-ruby

Named Entity Recognition for Ruby. Extract entities (people, places, organizations) from text using ONNX models or API backends.

## Installation

```ruby
gem "ner-ruby"
```

## Usage

```ruby
require "ner_ruby"

# ONNX backend
recognizer = NerRuby::Recognizer.new(
  model_path: "path/to/model.onnx",
  labels: [:PER, :LOC, :ORG, :MISC]
)

entities = recognizer.recognize("John works at Google in Mountain View")
entities.each do |e|
  puts "#{e.text} (#{e.label}) [#{e.start_offset}:#{e.end_offset}] score=#{e.score}"
end

# API backend
recognizer = NerRuby::Recognizer.new(
  backend: :api,
  provider: :openai,
  api_key: ENV["OPENAI_API_KEY"]
)
```

## Features

- ONNX Runtime inference with auto label map from config.json
- API backend support (OpenAI, etc.)
- IOB/BIO tag decoding with wordpiece token merging
- Character span offsets (start_offset, end_offset)
- Numerically stable softmax
- Empty/nil text guards

## License

MIT
