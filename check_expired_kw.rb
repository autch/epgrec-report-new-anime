#!/usr/bin/env ruby
# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'

# do not Bundler.require or Sinatra will take the stage

require 'mysql2'
require 'sequel'

require 'yaml'
require 'logger'

KEYWORDS_FILE = 'anime-kw.txt'

db_config = YAML.load(File.read(File.join(File.dirname(__FILE__), "database.yaml")))

DB = Sequel.connect(db_config["database_url"])
#DB.logger = Logger.new($stderr)
DB["SET CHARACTER SET utf8"]
DB["SET NAMES utf8"]

keywords = DB[:Recorder_keywordTbl].select(:keyword).map{|i| i[:keyword] }
kw_count = Hash[*keywords.zip([0] * keywords.count).flatten]

ignore_kw = File.open(KEYWORDS_FILE, "rb:UTF-8") do |file|
  file.readlines.map{|i| i.chomp }.reject{|i| i.strip.length == 0 }
end
ignore_count = Hash[*ignore_kw.zip([0] * ignore_kw.count).flatten]

DB[:Recorder_programTbl].select(:title, :description).each do |row|
  kw = keywords.detect{|k| row[:title].include?(k) || row[:description].include?(k) }
  kw_count[kw] += 1 if kw

  kw = ignore_kw.detect{|k| row[:title].include?(k) || row[:description].include?(k) }
  ignore_count[kw] += 1 if kw
end

#puts "予約キーワード,一致回数"
#kw_count.sort_by{|i| i[1] }.each do |r|
#  printf "%s,%d\n", r[0], r[1]
#end

#puts
#puts "無視キーワード,一致回数"
#ignore_count.sort_by{|i| i[1] }.each do |r|
#  printf "%s,%d\n", r[0], r[1]
#end

#pp kw_count
#pp ignore_count

puts "【一致なし予約キーワード】"
puts kw_count.delete_if{|k, v| v > 0 }.keys.join("\n")

puts
puts "【一致なし無視キーワード】"
not_matched = ignore_count.delete_if{|k, v| v > 0 }.keys
puts not_matched.join("\n")

puts
re = Regexp.union(not_matched)
printf "$ sed -i.bak -re '%s{d}' anime-kw.txt\n", re.inspect
