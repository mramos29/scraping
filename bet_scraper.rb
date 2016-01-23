#!/usr/bin/env ruby
#
# This script scrapes "Academia das Apostas" site looking for matches with a high probability of many goals.
#
# For each daily match, this script will analyse the 10 previous matches of each team and calculate the percentage
# of matches with more than X goals. If percentage is above Y%, that match is considered a good match to bet
# on goals market.
#
# Results/tips are sent by e-mail to defined addresses
#
# Marco Ramos, <mramos@29.sapo.pt>, 22/01/2016
# 

require 'nokogiri'
require 'open-uri'
require 'pp'
require 'date'
require 'net/smtp'

# Mail details
from = 'admin@bat-cave.eu'
to = 'admin@bat-cave.eu'
smtp_server = 'localhost'
port = 25
subject = 'Daily bets'
message = ''
date = Date.today.strftime("%d/%m/%Y")

# Page with daily matches
source = "https://www.academiadasapostas.com/stats/livescores"

# Check arguments
if ARGV.length != 2 then
  print "usage: #{$0} <goals> <percentage>\n"
  exit
end

goals_thold = ARGV[0].to_i
percentage_thold = ARGV[1].to_i

subject = subject + " #{date} (>= #{goals_thold} goals with percentage >= #{percentage_thold}\%)"

# Let the scrap begin...
page = Nokogiri::HTML(open(source))
page.encoding = 'utf-8'

# Games' table starts with:
# <table width="100%" class="competition-today">
games = page.css('table')[0]

# Individual games start with:
# <tbody>
# <tr class="odd separator live-subscription" type="match" eventid="2188337" competitionid="138">
rows = games.search('//table/tbody/tr')
details = rows.collect do |row|
  detail = {}
  [
    [:casa, 'td[6]/p/text()'],
    [:fora, 'td[8]/p/text()'],
    [:stats, 'td[10]/a/@href'],
    [:bet, 0]
  ].each do |name, xpath|
    detail[name] = row.at_xpath(xpath).to_s.strip
  end
  detail
end

details.each do |row|
 if (row[:stats] != "") then
    page_game = Nokogiri::HTML(open(row[:stats]))
    page_game.encoding = 'utf-8'
  
    # Last 10 games start with:
    #<table width="100%" border="0" cellspacing="0" cellpadding="0">
    #<tr>
    #<td colspan="2">
    #                                <span class="stats-title">Últimos 10 jogos em todas as competições
    last_games = page_game.css('table')[4]

    rows_games = last_games.search('//table[starts-with(@class, "stat-last10")]/tbody/tr')

    details_games = rows_games.collect do |row|
      detail = {}
      [
        [:result, 'td[4]/a/text()'],
      ].each do |name, xpath|
        detail[name] = row.at_xpath(xpath).to_s.strip
      end
      detail
    end
   
    aux = 0
    details_games.each do |key, row|
      key.each do |x, y|
        if (y != '' and y != '-') then
          goals = y.split(/-/)
          if (goals[0].to_i + goals[1].to_i >= goals_thold) then
            aux = aux + 1
          end
        end
      end
    end

    if (aux * 5 >= percentage_thold) then
      message = message + "#{row[:casa]} - #{row[:fora]} (#{aux*5}\%)\n"
    end

  end
end

# Send e-mail with results
msgstr = <<EOF
From: #{from}
To: #{to}
Subject: #{subject}
Content-type: text/plain; charset=UTF-8

#{message}
EOF

Net::SMTP.start(smtp_server, port) do |smtp|
  smtp.send_message msgstr, from, to
end
