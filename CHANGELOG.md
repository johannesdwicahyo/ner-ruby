# Changelog

## 0.1.1 (2026-03-09)

### Fixed
- Wire API backend to Recognizer via `backend: :api` option
- Softmax numerical stability (subtract max before exp, clamp output to 0.0..1.0)
- Empty/nil text input returns empty array instead of crashing

### Added
- Model config auto-detection: reads `config.json` alongside ONNX model for label map
- Entity character span offsets (`start_offset`, `end_offset`) in original text
- Input validation for model path, API key, and labels parameter
- `ValidationError` and `ConfigurationError` error classes

## 0.1.0 (2026-03-09)

- Initial release
- Named Entity Recognition using ONNX models
- IOB/BIO tag decoder with sub-token merging
- Entity result objects with type predicates
- Support for PER, LOC, ORG, MISC entity types
- API backend for OpenAI and HuggingFace
- Configuration DSL
