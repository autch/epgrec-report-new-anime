#!/usr/bin/env ruby
# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler'

Bundler.require

require './lib/liquid-patch'
require 'yaml'

KEYWORDS_FILE = 'anime-kw.txt'

configure do
  db_config = YAML.load(File.read(File.join(File.dirname(__FILE__), "database.yaml")))
  set :database, db_config["database_url"]

  database["SET CHARACTER SET utf8"]
  database["SET NAMES utf8"]

  programs = database[Sequel.as(:Recorder_programTbl, :p)].
    join(Sequel.as(:Recorder_channelTbl, :ch), :p__channel_id => :ch__id).
    join(Sequel.as(:Recorder_categoryTbl, :c), :p__category_id => :c__id).
    left_join(Sequel.as(:Recorder_reserveTbl, :r), :r__program_id => :p__id).
    where(:c__name_en => :$category_name).where{p__starttime > :$starttime}.
    order(Sequel.desc(:p__starttime), Sequel.asc(:ch__channel_disc)).
    select(:ch__name, :ch__channel_disc, :p__starttime, :p__title, :p__description, :r__id).
    prepare(:select, :select_programs)
  set :programs, programs

  conditions_re = File.open(KEYWORDS_FILE, "rb:UTF-8") do |file|
    keywords = file.readlines.map{|i| i.chomp }.reject{|i| i.strip.length == 0 }
    Regexp.union(*keywords.map{|kw| Regexp.quote(kw) })
  end
  set :conditions_re, conditions_re
end

get "/" do
  conditions_re = settings.conditions_re

  locals = { "rows" => [], "baseuri" => request.script_name }

  settings.programs.call({:category_name => "anime", :starttime => Time.now}).each do |row|
    keys = row.keys.map{|k| k.to_s }
    res = Hash[*keys.zip(row.values).flatten]

    locals["rows"] << { 
      "res" => res,
      "reserved" => !row[:id].nil?,
      "filtered" => !conditions_re.match(row[:title]).nil?,
      "matched" => row[:title].gsub(conditions_re){|m| "<span class=\"q\">#{m}</span>" }
    }
  end
  liquid :index, :locals => locals
end
