#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"

ROOT = File.expand_path("..", __dir__)
TARGETS = %w[
  source/scenarios.jsonl
  data/train.jsonl
  data/validation.jsonl
  data/test.jsonl
  data/train.parquet
  data/validation.parquet
  data/test.parquet
  metadata/schema.json
].freeze

missing = TARGETS.reject { |path| File.file?(File.join(ROOT, path)) }
abort "Missing checksum targets: #{missing.join(', ')}" unless missing.empty?

lines = TARGETS.map do |path|
  "#{Digest::SHA256.file(File.join(ROOT, path)).hexdigest}  #{path}"
end

File.write(File.join(ROOT, "metadata", "checksums.sha256"), lines.join("\n") + "\n")
puts "Updated checksums for #{TARGETS.size} files."
