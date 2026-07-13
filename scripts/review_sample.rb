#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
SAMPLE_SCENARIOS = %w[
  scn_001 scn_002 scn_003 scn_004 scn_005
  scn_036 scn_037 scn_038 scn_039 scn_040
  scn_046 scn_047 scn_048 scn_049 scn_050
].freeze

rows = Dir[File.join(ROOT, "data", "*.jsonl")].flat_map do |path|
  File.readlines(path, chomp: true).reject(&:empty?).map { |line| JSON.parse(line) }
end

pairs = rows.group_by { |row| row.fetch("pair_id") }
selected = pairs.values.select { |pair| SAMPLE_SCENARIOS.include?(pair.first.fetch("scenario_id")) }

selected.sort_by { |pair| [pair.first.fetch("pair_family"), pair.first.fetch("scenario_id")] }.each do |pair|
  benign = pair.find { |row| row.fetch("label") == 0 }
  attack = pair.find { |row| row.fetch("label") == 1 }
  puts "### #{benign.fetch('pair_family')} / #{benign.fetch('scenario_id')} / #{benign.fetch('pair_id')}"
  puts "BENIGN: #{benign.fetch('text')}"
  puts "ATTACK: #{attack.fetch('text')}"
  puts
end
