#!/usr/bin/env ruby
# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler'

Bundler.require

require './lib/liquid-patch'
require 'yaml'
require 'json'

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
    where(:ch__skip => 0).
    order(Sequel.asc(:p__starttime), Sequel.asc(:ch__channel_disc)).
    select(:ch__name, :ch__channel_disc, :p__starttime, :p__endtime, :p__title, :p__description, :r__id, :ch__type).
    prepare(:select, :select_programs)
  set :programs, programs

  ignore_keywords = database[:ignore_keywords].where(:enabled => 1).select(:keyword).prepare(:select, :select_ignore_keywords)
  set :ignore_keywords, ignore_keywords
end

def determine_classes(row)
  classes = []

  classes << "a" if row["available"]
  classes << "f" if row["filtered"]
  classes << "r" if row["reserved"]
  classes << "prog-#{row['res']['type']}"
  classes << "n" if row["new"]
  classes << "l" if row["last"]
  classes << "nl" if (row["new"] || row["last"])

  classes.join(' ')
end

def determine_captions(row)
  captions = []

  #captions << { class: ""} if row["available"]
  captions << { "class"=> "glyphicon glyphicon-remove", "caption"=> "無視" } if row["filtered"]
  captions << { "class"=> "glyphicon glyphicon-ok", "caption"=> "予約済" } if row["reserved"]
  captions << { "class"=> "glyphicon glyphicon-step-backward", "caption"=> "新番組" } if row["new"]
  captions << { "class"=> "glyphicon glyphicon-step-forward", "caption"=> "最終回" } if row["last"]

  captions
end

get "/" do
  conditions_re = Regexp.union(settings.ignore_keywords.call().map{|row| Regexp.quote(row[:keyword]) })

  locals = { "rows" => [], "baseuri" => request.script_name }

  settings.programs.call({:category_name => "anime", :starttime => Time.now}).each do |row|
    keys = row.keys.map{|k| k.to_s }
    res = Hash[*keys.zip(row.values).flatten]

    row = { 
      "res" => res,
      "reserved" => !row[:id].nil?,
      "filtered" => !conditions_re.match(row[:title]).nil?,
      "available" => row[:id].nil? && conditions_re.match(row[:title]).nil?,
      "matched" => row[:title].gsub(conditions_re){|m| "<span class=\"q\">#{m}</span>" },
      "new" => /【新】/ =~ row[:title],
      "last" => /【終】/ =~ row[:title],
    }
    row["new_or_last"] = row["new"] || row["last"]
    row["classes"] = determine_classes(row)
    row["captions"] = determine_captions(row)
    locals["rows"] << row
  end
  locals["count"] = {
    "all" => locals["rows"].count,
    "reserved" => locals["rows"].count{|i| i["reserved"] },
    "filtered" => locals["rows"].count{|i| i["filtered"] },
    "available" => locals["rows"].count{|i| i["available"] },
    "new_or_last" => locals["rows"].count{|i| i["new_or_last"] },
    "by_type" => {
      "BS" => locals["rows"].count{|i| i["res"]["type"] == "BS" },
      "CS" => locals["rows"].count{|i| i["res"]["type"] == "CS" },
      "GR" => locals["rows"].count{|i| i["res"]["type"] == "GR" },
    },
  }
  liquid :index, :locals => locals
end

post "/add-ignore-keyword" do
  content_type "application/javascript"

  keyword = params[:keyword]
  values = { "keyword" => keyword, "enabled" => 1 }

  database[:ignore_keywords].insert(values)
end
