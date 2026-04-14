# ner-ruby — Milestones

> **Source of truth:** https://github.com/johannesdwicahyo/ner-ruby/milestones
> **Last synced:** 2026-04-14

This file mirrors the GitHub milestones for this repo. Edit the milestone or issues on GitHub and re-sync, do not hand-edit.

## v1.0.0 (**open**)

_Production Ready_

- [ ] #34 API stability guarantee
- [ ] #35 Pre-trained model distribution strategy
- [ ] #36 Performance benchmarks (entities/sec on CPU vs GPU)
- [ ] #37 Accuracy benchmarks on CoNLL-2003 and OntoNotes 5.0
- [ ] #38 Thread-safe model inference

## v0.4.0 (**open**)

_Rails & Advanced_

- [ ] #27 Add Rails Railtie for auto-loading NER models
- [ ] #28 Add ActiveRecord concern: acts_as_ner_extractable
- [ ] #29 Add background job for batch NER on new records
- [ ] #30 Add coreference resolution
- [ ] #31 Add nested entity support
- [ ] #32 Add entity normalization
- [ ] #33 Add fine-tuning API

## v0.3.0 (**open**)

_Ecosystem Integration_

- [ ] #15 Integrate pattern-ruby: entity slot filling
- [ ] #16 Integrate pattern-ruby: auto-extract entity slots from user messages
- [ ] #17 Integrate guardrails-ruby: PII detection via NER
- [ ] #18 Integrate guardrails-ruby: NER-based redactor
- [ ] #19 Integrate rag-ruby: entity-enriched metadata during ingestion
- [ ] #20 Integrate rag-ruby: entity-filtered retrieval
- [ ] #21 Add entity linking to knowledge base IDs
- [ ] #22 Add relation extraction between entities
- [ ] #23 Add custom entity types support
- [ ] #24 Test pattern-ruby integration: slot filling with NER
- [ ] #25 Test guardrails PII detection accuracy vs regex-only
- [ ] #26 Test RAG entity-filtered retrieval end-to-end

## v0.2.0 (**closed**)

_Indonesian NER & Batch Processing_

- [x] #1 Add from_pretrained support for auto-downloading models from HuggingFace Hub
- [x] #2 Add Indonesian NER model support
- [x] #3 Add multilingual NER support
- [x] #4 Add model registry for custom model configuration
- [x] #5 Add batch processing for multiple texts
- [x] #6 Add sliding window for texts longer than 512 tokens
- [x] #7 Add entity merging for adjacent tokens
- [x] #8 Add per-entity-type confidence thresholds
- [x] #9 Add model caching to avoid reload per request
- [x] #10 Improve tokenizer alignment for character span mapping
- [x] #11 Test Indonesian NER accuracy
- [x] #12 Test batch processing correctness and performance
- [x] #13 Test long text with sliding window
- [x] #14 Test model download and caching

## v0.1.1 (**closed**)

_Bug Fixes & Robustness_

_No issues._ (0 open, 0 closed reported)
