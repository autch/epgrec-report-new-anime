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

no_reserve_kws = DB[:Recorder_keywordTbl].select(:keyword).
	left_join(:Recorder_reserveTbl, :autorec => :id){|j, lj, js|
		Sequel.qualify(j, :starttime) >= Sequel.function(:now) }.
	where(:autorec => nil).order(:keyword)

no_match_ignores = DB[:ignore_keywords].select(:keyword).
	left_join(:Recorder_programTbl){|j, lj, js|
		Sequel.ilike(:title, Sequel.join(['%', :keyword, '%'])) || 
		Sequel.ilike(:description, Sequel.join(['%', :keyword, '%'])) }.
	where(:id => nil).order(:keyword)

overkill_ignores = DB[:Recorder_programTbl].
	select(Sequel.function(:count, :keyword).as(:c)).distinct.
	select_more{group_concat(Sequel.lit("keyword ORDER BY keyword ASC SEPARATOR '|'")).as(:kw)}.
	join(:ignore_keywords).
	where{ 
		Sequel.ilike(:title, Sequel.join(['%', :keyword, '%'])) || 
		Sequel.ilike(:description, Sequel.join(['%', :keyword, '%'])) }.
	group(:id).having{count(:c) > 1}

puts "【一致なし予約キーワード】"
puts no_reserve_kws.map(:keyword).join("\n")

puts
puts "【一致なし無視キーワード】"
puts no_match_ignores.map(:keyword).join("\n")

puts
puts "【１番組に複数キーワードがマッチ】"
puts overkill_ignores.map{|i| i[:kw].gsub(/[|]/, "\t") }.join("\n") 

