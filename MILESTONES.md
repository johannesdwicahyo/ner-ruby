# ner-ruby Milestones

## Current State (v0.1.0)

- ONNX model backend via onnx-ruby + tokenizer-ruby
- IOB/BIO tag decoder with wordpiece sub-token merging
- API backend stubs for OpenAI and HuggingFace
- Entity result objects with PER/LOC/ORG/MISC predicates
- 15 tests, 37 assertions — all passing (with stubbed dependencies)

---

## v0.1.1 — Bug Fixes & Robustness

### Fix
- [x] **API backend not connected to Recognizer** — `Recognizer.new` only supports ONNX models; add `Recognizer.from_api(provider:, api_key:)` factory method
- [x] **Decoder assumes bert-base-NER label map** — Custom models with different label orders silently produce wrong entities; require label map parameter or auto-detect from model config
- [x] **Pipeline softmax numerical instability** — Large logit values can overflow `Math.exp`; implement log-sum-exp trick
- [x] **Empty text handling** — `recognizer.recognize("")` passes empty tokens to model; add early return
- [x] **Entity score clamping** — Softmax should guarantee 0.0..1.0 but floating point errors can exceed; clamp output

### Add
- [x] **Model config loader** — Read `config.json` alongside ONNX model to auto-detect label map, max sequence length
- [x] **Graceful dependency errors** — Better error messages when onnx-ruby or tokenizer-ruby are missing
- [x] **Entity span offsets** — Track character-level `start_offset` and `end_offset` in original text (currently nil)
- [x] **Overlapping entity resolution** — When sub-tokens produce overlapping entities, merge by highest confidence

### Test
- [x] API backend with WebMock (OpenAI + HuggingFace responses)
- [x] Empty text, single-word text, very long text (>512 tokens)
- [x] Malformed tokenizer output (missing tokens, extra tokens)
- [x] Label map with different entity types (DATE, TIME, MONEY)
- [x] Softmax edge cases (all zeros, all same value, very large values)

---

## v0.2.0 — Indonesian NER & Batch Processing

### Add: Models
- [ ] **from_pretrained support** — `NerRuby::Recognizer.from_pretrained("dslim/bert-base-NER")` auto-downloads ONNX model + tokenizer from HuggingFace Hub
- [ ] **Indonesian NER** — Bundle or auto-download `cahya/bert-base-indonesian-NER` model
- [ ] **Multilingual NER** — Support `Davlan/bert-base-multilingual-cased-ner-hrl` for 10+ languages
- [ ] **Model registry** — `NerRuby.configure { |c| c.register_model(:indonesian, model_path:, tokenizer_path:, label_map:) }`

### Add: Features
- [ ] **Batch processing** — True batch inference: `recognizer.recognize_batch(texts)` sends batch to ONNX model in single call
- [ ] **Sliding window** — Handle texts >512 tokens by sliding window with overlap and entity dedup
- [ ] **Entity merging** — `merge_adjacent: true` option to combine "New" + "York" → "New York"
- [ ] **Confidence per entity type** — Different thresholds per type: `min_score: { PER: 0.9, LOC: 0.8 }`

### Refine
- [ ] **Model caching** — Cache loaded ONNX models in memory to avoid reload per request
- [ ] **Tokenizer alignment** — Map sub-token predictions back to original character spans

### Test
- [ ] Indonesian NER accuracy (10 sentences with known entities)
- [ ] Batch processing correctness and performance
- [ ] Long text with sliding window
- [ ] Model download and caching

---

## v0.3.0 — Ecosystem Integration

### Integrate: pattern-ruby
- [ ] **Entity slot filling** — Pattern "Book flight to {LOC}" fills `{LOC}` with NER-extracted locations
- [ ] `PatternRuby::Pattern.new("Remind {PER} about {event}", entity_extractor: NerRuby)`
- [ ] Auto-extract entity slots from user messages before pattern matching

### Integrate: guardrails-ruby
- [ ] **PII detection via NER** — `GuardrailsRuby::Checks::PiiNerCheck` uses NER for names/addresses that regex misses
- [ ] Combine with existing regex-based PII: NER catches "John Smith" while regex catches emails/phones
- [ ] `GuardrailsRuby::Redactors::NerRedactor` — Redact NER-detected entities

### Integrate: rag-ruby
- [ ] **Entity-enriched metadata** — Extract entities during document ingestion, store in metadata
- [ ] **Entity-filtered retrieval** — `rag.search("Who visited Jakarta?", entity_filter: { LOC: "Jakarta" })`

### Add: Features
- [ ] **Entity linking** — Link extracted entities to knowledge base IDs
- [ ] **Relation extraction** — Extract relations between entities: `(PER, visited, LOC)`
- [ ] **Custom entity types** — Define domain-specific types (PRODUCT, DISEASE, GENE)

### Test
- [ ] Pattern-ruby integration: slot filling with NER
- [ ] Guardrails PII detection accuracy vs regex-only
- [ ] RAG entity-filtered retrieval end-to-end

---

## v0.4.0 — Rails & Advanced

### Add: Rails
- [ ] `NerRuby::Rails::Railtie` — Auto-load models from `config/ner_models/`
- [ ] ActiveRecord concern: `acts_as_ner_extractable` for model text fields
- [ ] Background job for batch NER on new records

### Add: Features
- [ ] **Coreference resolution** — Link pronouns to entities: "Jokowi... He visited" → He = Jokowi
- [ ] **Nested entities** — "Bank of America" → ORG containing LOC
- [ ] **Entity normalization** — "NYC", "New York City", "New York" → canonical form
- [ ] **Fine-tuning API** — Export training data, fine-tune ONNX model on domain data

---

## v1.0.0 — Production Ready

- [ ] API stability guarantee
- [ ] Pre-trained model distribution strategy (separate gem or auto-download)
- [ ] Performance benchmarks (entities/sec on CPU vs GPU)
- [ ] Accuracy benchmarks on CoNLL-2003, OntoNotes 5.0
- [ ] Thread-safe model inference
