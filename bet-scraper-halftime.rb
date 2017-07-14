##!/usr/bin/env ruby
#
# This script scraps "Academia das Apostas" site looking for matches with a high probability of having 1st half goals.
#
# For each daily match, this script will analyse the 10 previous matches of each team and calculate the percentage
# of matches with 1st half goals. If percentage is above a defined trheshold, it will consider this match as a good one
# to bet on 1st half goals market.
#
# Results/tips are sent by e-mail to defined addresses
#
# Marco Ramos, <mramos@29.sapo.pt>, 16/02/2016
# 

require 'nokogiri'
require 'open-uri'
require 'pp'
require 'date'
require 'net/smtp'

# Check if string "empty"
class String
  def is_empty?
    return true if (self == "" or self == " ")
    return false
  end
end

# Mail details
from = 'mail@example.com'
to = 'mail@example.com'
cc = 'mail@example.com'

smtp_server = 'localhost'
port = 25
subject = 'Daily bets'
message = ''
date = Date.today.strftime("%d/%m/%Y")

# Page with daily matches
source = "https://www.academiadasapostas.com/stats/livescores"

# Competitions we want to include (Domestic leagues)
competitions = [ 'co c1', # First Division
                 'co c2', # Second Division
                 'co c3', # Third Division
                 'co c4' ] # Fourth Division


# Check arguments
if ARGV.length != 1 then
  print "usage: #{$0} <percentage>\n"
  exit
end

percentage_thold = ARGV[0].to_i

subject = subject + " #{date} (1st half goals with percentage >= #{percentage_thold}\%)"

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
    [:competicao, 'td[2]/a/ul/li[2]/@class' ]
  ].each do |name, xpath|
    detail[name] = row.at_xpath(xpath).to_s.strip
  end
  detail
end

details.each do |row|
 if (row[:stats] != "" and competitions.include? row[:competicao]) then
    page_game = Nokogiri::HTML(open(row[:stats]))
    page_game.encoding = 'utf-8'

    # 1st goal is divided into tables and starts with:
    #<br><table width="100%" border="0" cellspacing="0" cellpadding="0">
    #<tr>
    #<td colspan="2"><span class="stats-title">Análise classificativa do adversário na condição Casa/Fora » Ligue 1 2015/2016 » Época normal</span></td>
    first_goals = page_game.css('table')[17]


    rows_games = first_goals.search('//table/tbody[1]/tr')

    details_games = rows_games.collect do |row|
      detail = {}
      [
        [:minute_goal, 'td[6]/text()'],
      ].each do |name, xpath|
        detail[name] = row.at_xpath(xpath).to_s.strip
      end
      detail
    end 
   
    total = 0
    first_half = 0
    details_games.each do |key, row|
      key.each do |x, y|
      
        if not y.is_empty? then # if string with possible result is not empty...
         
          if (y =~ /-/ or y =~ /\'\'/) then # then we check if it's really a result or junk
            total = total + 1
           
            if (y =~ /\'\'/ ) then # if there were goals scored, we need to check it it was on fisrt half
               minute = y.split(/\'\'/)
               first_half = first_half + 1 unless minute[0].to_i > 45
            end
          end
        end
     
      end
    end

    # NEED TO CHECK WHY GAMES ARE DUPLICATED!!!
    # NEED TO CHECK WHY GAMES ARE DUPLICATED!!!
    # NEED TO CHECK WHY GAMES ARE DUPLICATED!!!
    result = (first_half.to_f * 100) / total
 
    if (result >= percentage_thold) then
      message = message + "#{row[:casa]} - #{row[:fora]} (%.1f%%)\n" % [result]
    end

  end
end

# If message is empty, we don't need to send mail
exit unless message.length > 0

# Send e-mail with results
msgstr = <<EOF
From: #{from}
To: #{to} 
Cc: #{cc}
Subject: #{subject}
Content-type: text/plain; charset=UTF-8

#{message}
EOF

Net::SMTP.start(smtp_server, port) do |smtp|
  smtp.send_message msgstr, from, to, cc
end
