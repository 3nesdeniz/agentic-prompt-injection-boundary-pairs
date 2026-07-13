#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "set"

ROOT = File.expand_path("..", __dir__)
SPLITS = %w[train validation test].freeze
EXPECTED_SPLIT_COUNTS = { "train" => 840, "validation" => 120, "test" => 240 }.freeze
EXPECTED_LABEL_COUNTS = { 0 => 600, 1 => 600 }.freeze
EXPECTED_FAMILY_SPLITS = { "train" => 35, "validation" => 5, "test" => 10 }.freeze
EXPECTED_FAMILIES = %w[
  approval_workflow_bypass
  authority_claim_bypass
  direct_instruction_override
  indirect_content_injection
  memory_context_poisoning
  multi_agent_trust_spoofing
  obfuscation_encoding
  rag_context_poisoning
  roleplay_jailbreak
  sensitive_data_exfiltration
  system_prompt_extraction
  tool_action_abuse
].freeze
REQUIRED_FIELDS = %w[
  id pair_id scenario_id text label category attack_family pair_family
  source_context risk_domain target_boundary expected_action source_type language split
].freeze

errors = []
warnings = []

def read_split(root, split, errors)
  path = File.join(root, "data", "#{split}.jsonl")
  unless File.file?(path)
    errors << "Missing split file: #{path}"
    return []
  end

  rows = []
  File.readlines(path, chomp: true).each_with_index do |line, index|
    if line.strip.empty?
      errors << "Blank line in #{split}:#{index + 1}"
      next
    end

    begin
      row = JSON.parse(line)
      row["_line"] = index + 1
      row["_file_split"] = split
      rows << row
    rescue JSON::ParserError => e
      errors << "Invalid JSON in #{split}:#{index + 1}: #{e.message}"
    end
  end
  rows
end

def normalized_text(text)
  text.unicode_normalize(:nfkc).downcase.gsub(/[[:punct:]\s]+/u, " ").strip
end

def tokens(text)
  Set.new(text.unicode_normalize(:nfkc).downcase.scan(/[[:alnum:]_]+/u).reject { |token| token.length < 2 })
end

def jaccard(left, right)
  union = left | right
  return 0.0 if union.empty?

  (left & right).size.to_f / union.size
end

rows_by_split = {}
SPLITS.each { |split| rows_by_split[split] = read_split(ROOT, split, errors) }
all_rows = rows_by_split.values.flatten

EXPECTED_SPLIT_COUNTS.each do |split, expected|
  actual = rows_by_split.fetch(split).size
  errors << "#{split} count: expected #{expected}, found #{actual}" unless actual == expected
end

all_rows.each do |row|
  location = "#{row['_file_split']}:#{row['_line']}"
  missing = REQUIRED_FIELDS.reject { |field| row.key?(field) }
  errors << "#{location} missing fields: #{missing.join(', ')}" unless missing.empty?
  next unless missing.empty?

  extra = row.keys.reject { |field| REQUIRED_FIELDS.include?(field) || field.start_with?("_") }
  errors << "#{location} unexpected fields: #{extra.join(', ')}" unless extra.empty?
  errors << "#{location} empty id" if row["id"].to_s.strip.empty?
  errors << "#{location} empty text" if row["text"].to_s.strip.empty?
  errors << "#{location} text is too short" if row["text"].to_s.length < 45
  errors << "#{location} text exceeds 1,200 characters" if row["text"].to_s.length > 1_200
  errors << "#{location} invalid label #{row['label'].inspect}" unless [0, 1].include?(row["label"])
  errors << "#{location} split field mismatch" unless row["split"] == row["_file_split"]
  errors << "#{location} invalid source_type" unless row["source_type"] == "synthetic_curated"
  errors << "#{location} invalid language" unless row["language"] == "en"
  errors << "#{location} unknown pair_family" unless EXPECTED_FAMILIES.include?(row["pair_family"])
  errors << "#{location} empty source_context" if row["source_context"].to_s.strip.empty?
  errors << "#{location} empty risk_domain" if row["risk_domain"].to_s.strip.empty?
  errors << "#{location} empty target_boundary" if row["target_boundary"].to_s.strip.empty?
  errors << "#{location} contains ASCII control characters" if row["text"].match?(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/)
  errors << "#{location} has a lowercase sentence start" if row["text"].match?(/[.!?]\s+[a-z]/)
  unless row["pair_family"] == "obfuscation_encoding"
    errors << "#{location} contains a repeated adjacent word" if row["text"].match?(/\b([A-Za-z]+)\s+\1\b/i)
    warnings << "#{location} may use the wrong indefinite article" if row["text"].match?(/\ba\s+[aeiou]/i)
  end

  if row["label"] == 1
    errors << "#{location} attack category mismatch" unless row["category"] == "prompt_injection"
    errors << "#{location} attack family mismatch" unless row["attack_family"] == row["pair_family"]
    errors << "#{location} attack expected_action mismatch" unless row["expected_action"] == "block_or_review"
  elsif row["label"] == 0
    errors << "#{location} benign category mismatch" unless row["category"] == "benign_boundary"
    errors << "#{location} benign attack_family must be none" unless row["attack_family"] == "none"
    errors << "#{location} benign expected_action mismatch" unless row["expected_action"] == "allow"
  end
end

ids = all_rows.group_by { |row| row["id"] }
ids.each { |id, matches| errors << "Duplicate id #{id}" if matches.size > 1 }

texts = all_rows.group_by { |row| normalized_text(row["text"]) }
texts.each do |_text, matches|
  errors << "Duplicate normalized text in IDs #{matches.map { |row| row['id'] }.join(', ')}" if matches.size > 1
end

label_counts = all_rows.group_by { |row| row["label"] }.transform_values(&:size)
errors << "Label counts mismatch: #{label_counts.inspect}" unless label_counts == EXPECTED_LABEL_COUNTS

pairs = all_rows.group_by { |row| row["pair_id"] }
errors << "Expected 600 pair groups, found #{pairs.size}" unless pairs.size == 600

pairs.each do |pair_id, pair_rows|
  errors << "#{pair_id} must contain exactly 2 rows" unless pair_rows.size == 2
  next unless pair_rows.size == 2

  errors << "#{pair_id} must contain labels 0 and 1" unless pair_rows.map { |row| row["label"] }.sort == [0, 1]
  %w[split scenario_id pair_family source_context risk_domain target_boundary].each do |field|
    errors << "#{pair_id} has mismatched #{field}" unless pair_rows.map { |row| row[field] }.uniq.size == 1
  end

  benign = pair_rows.find { |row| row["label"] == 0 }
  attack = pair_rows.find { |row| row["label"] == 1 }
  next unless benign && attack

  overlap = jaccard(tokens(benign["text"]), tokens(attack["text"]))
  warnings << "#{pair_id} has low pair overlap #{format('%.3f', overlap)}" if overlap < 0.08
end

scenario_splits = all_rows.group_by { |row| row["scenario_id"] }
errors << "Expected 50 scenario groups, found #{scenario_splits.size}" unless scenario_splits.size == 50
scenario_splits.each do |scenario_id, scenario_rows|
  split_names = scenario_rows.map { |row| row["split"] }.uniq
  errors << "#{scenario_id} crosses splits: #{split_names.join(', ')}" unless split_names.size == 1
  errors << "#{scenario_id} should contribute 24 rows, found #{scenario_rows.size}" unless scenario_rows.size == 24
end

attack_rows = all_rows.select { |row| row["label"] == 1 }
family_counts = attack_rows.group_by { |row| row["attack_family"] }.transform_values(&:size)
errors << "Unexpected attack families: #{family_counts.keys.sort.inspect}" unless family_counts.keys.sort == EXPECTED_FAMILIES
family_counts.each do |family, count|
  errors << "#{family}: expected 50 attacks, found #{count}" unless count == 50
end

EXPECTED_FAMILIES.each do |family|
  EXPECTED_FAMILY_SPLITS.each do |split, expected|
    actual = rows_by_split.fetch(split).count do |row|
      row["label"] == 1 && row["attack_family"] == family
    end
    errors << "#{family}/#{split}: expected #{expected}, found #{actual}" unless actual == expected
  end
end

all_rows.group_by { |row| [row["label"], row["pair_family"]] }.each do |group, grouped_rows|
  token_sets = grouped_rows.map { |row| [row, tokens(row["text"])] }
  token_sets.combination(2) do |(left_row, left_tokens), (right_row, right_tokens)|
    similarity = jaccard(left_tokens, right_tokens)
    next unless similarity >= 0.94

    warnings << "Near-duplicate #{group.inspect}: #{left_row['id']} / #{right_row['id']} (#{format('%.3f', similarity)})"
  end
end

sensitive_patterns = {
  "email address" => /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i,
  "private IPv4 address" => /\b(?:10\.|192\.168\.|172\.(?:1[6-9]|2\d|3[01])\.)\d{1,3}\.\d{1,3}\b/,
  "credit-card-shaped value" => /\b(?:\d[ -]*?){13,19}\b/,
  "long numeric identifier" => /\b\d{10,19}\b/,
  "AWS access key" => /\bAKIA[0-9A-Z]{16}\b/,
  "OpenAI-style secret" => /\bsk-[A-Za-z0-9_-]{16,}\b/,
  "private key header" => /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/
}
sensitive_patterns.each do |name, pattern|
  matches = all_rows.select { |row| row["text"].match?(pattern) }
  errors << "Potential #{name} in IDs: #{matches.map { |row| row['id'] }.join(', ')}" unless matches.empty?
end

checksums_path = File.join(ROOT, "metadata", "checksums.sha256")
if File.file?(checksums_path)
  File.readlines(checksums_path, chomp: true).reject(&:empty?).each do |line|
    expected, relative_path = line.split(/\s+/, 2)
    full_path = File.join(ROOT, relative_path)
    if !File.file?(full_path)
      errors << "Checksum target missing: #{relative_path}"
    elsif Digest::SHA256.file(full_path).hexdigest != expected
      errors << "Checksum mismatch: #{relative_path}"
    end
  end
else
  errors << "Missing metadata/checksums.sha256"
end

puts "Validated #{all_rows.size} rows across #{SPLITS.size} splits."
puts "Labels: #{label_counts.sort.to_h.inspect}"
puts "Pairs: #{pairs.size}; scenarios: #{scenario_splits.size}"
puts "Attack families: #{family_counts.sort.to_h.inspect}"

unless warnings.empty?
  puts "Warnings (#{warnings.size}):"
  warnings.first(100).each { |warning| puts "  - #{warning}" }
  puts "  - ... #{warnings.size - 100} additional warnings omitted" if warnings.size > 100
end

unless errors.empty?
  warn "Validation failed with #{errors.size} error(s):"
  errors.each { |error| warn "  - #{error}" }
  exit 1
end

puts "Validation passed."
