#!/usr/bin/env ruby
# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'

# do not Bundler.require or Sinatra will take the stage

require 'mysql2'
require 'sequel'
require 'erubis'
require 'mail'

require 'yaml'
require 'logger'
require 'nkf'

require_relative 'mail-setup.rb'

db_config = YAML.load(File.read(File.join(File.dirname(__FILE__), "database.yaml")))

DB = Sequel.connect(db_config["database_url"])
# DB.logger = Logger.new($stderr)
DB["SET CHARACTER SET utf8"]
DB["SET NAMES utf8"]

programs = DB[Sequel.as(:Recorder_programTbl, :p)].
  join(Sequel.as(:Recorder_channelTbl, :ch), :p__channel_id => :ch__id).
  join(Sequel.as(:Recorder_categoryTbl, :c), :p__category_id => :c__id).
  left_join(Sequel.as(:Recorder_reserveTbl, :r), :r__program_id => :p__id).
  where(:c__name_en => "anime").where{p__starttime >= Time.now}.
  where(:p__title.like('%【新】%')).
  order(Sequel.desc(:p__starttime), Sequel.asc(:ch__channel_disc)).
  select(:ch__name, :ch__channel_disc, :p__starttime, :p__title, :p__description, :r__id)

exit if programs.count == 0

eruby = Erubis::Eruby.new(DATA.read)

mail = Mail.new do
  content_type 'text/plain; charset=UTF-8'
  from	  'autch@mizuho.autch.net'
  to	  'autch@autch.net'
  subject '[epgrec] 今週の新番組'
  body	  eruby.result(:programs => programs)
end

mail.delivery_method :smtp, MAIL_DELIVERY_METHOD_DEFAULT
mail.deliver!

__END__
<% programs.each do |row| %>
<%= row[:starttime].strftime("%m/%d %H:%M") %> <%= row[:name] %> <%= row[:id] ? "【予約済】" : "" %>
<%= row[:title] %>

<%= NKF.nkf("-w -f74", row[:description]) %>
<%= "-" * 76 %>
<% end %>
