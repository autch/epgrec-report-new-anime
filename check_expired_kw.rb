#!/usr/bin/env ruby
# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'

# do not Bundler.require or Sinatra will take the stage

require 'mysql2'
require 'sequel'

require 'yaml'
require 'logger'

db_config = YAML.load(File.read(File.join(File.dirname(__FILE__), "database.yaml")))

DB = Sequel.connect(db_config["database_url"])
#DB.logger = Logger.new($stderr)
DB["SET CHARACTER SET utf8"]
DB["SET NAMES utf8"]

keywords = DB[:Recorder_keywordTbl].select(:keyword).map{|i| i[:keyword] }
kw_count = Hash[*keywords.zip([0] * keywords.count).flatten]

ignore_kw = DB[:ignore_keywords].where(:enabled => 1).select(:keyword).map{|i| i[:keyword] }
ignore_count = Hash[*ignore_kw.zip([0] * ignore_kw.count).flatten]

DB[:Recorder_programTbl].where("starttime > NOW()").select(:title, :description).each do |row|
  kws = keywords.select{|k| 
    row[:title].include?(k) || row[:description].include?(k)
  }
  kws.each{|kw| kw_count[kw] += 1 } if kws

  kws = ignore_kw.select{|k|
    row[:title].include?(k) || row[:description].include?(k)
  }
  kws.each{|kw| ignore_count[kw] += 1 } if kws
end

# puts "予約キーワード,一致回数"
# kw_count.sort_by{|i| i[1] }.each do |r|
#   printf "%s,%d\n", r[0], r[1]
# end

# puts
# puts "無視キーワード,一致回数"
# ignore_count.sort_by{|i| i[1] }.each do |r|
#   printf "%s,%d\n", r[0], r[1]
# end

#pp kw_count
#pp ignore_count

puts "【一致なし予約キーワード】"
puts kw_count.select{|k, v| v == 0 }.keys.join("\n")

puts
puts "【一致なし無視キーワード】"
puts ignore_count.select{|k, v| v == 0 }.keys.join("\n")

overkill_ignores = []

DB[:Recorder_programTbl].select(:title, :description).each do |row|
  kws = ignore_kw.select{|k|
    row[:title].include?(k) || row[:description].include?(k)
  }
  if kws.count > 1 then
    overkill_ignores << kws
  end
end

puts
puts "【１番組に複数キーワードがマッチ】"
overkill_ignores.uniq.each{|kws| p kws }
