#
# This script scraps "Academia das Apostas" site looking for matches with a high probability of many or few goals.
#
# For each daily match, this script will analyse the 10 previous matches of each team and calculate the percentage
# of matches with more or less than X goals. If percentage is above Y%, that match is considered a good match to bet
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

# Check if string is an integer
class String
  def is_integer?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end
end

# Mail details
from = 'admin@bat-cave.eu'
to = 'admin@bat-cave.eu'
cc = 'ricardup@gmail.com'

smtp_server = 'localhost'
port = 25
subject = 'Daily bets'
message = ''
date = Date.today.strftime("%d/%m/%Y")

# Page with daily matches
source = "https://www.academiadasapostas.com/stats/livescores"

# Competitions we want to ignore (friendlies, etc)
ignore = [ 'co cfriendly', 
           'co cfriendly-w' ]

# Check arguments
if ARGV.length != 3 and ARGV[0] != "over" and ARGV[0] != "under" then
  print "usage: #{$0} <over|under> <goals> <percentage>\n"
  exit
end

over_under = ARGV[0]
goals_thold = ARGV[1].to_i
percentage_thold = ARGV[2].to_i

subject = subject + " #{date} (>= #{goals_thold} goals with percentage >= #{percentage_thold}\%)" unless over_under == "under"
subject = subject + " #{date} (<= #{goals_thold} goals with percentage >= #{percentage_thold}\%)" unless over_under == "over"

# Let the scrap begin...
page = Nokogiri::HTML(open(source))
page.encoding = 'utf-8'

# Games' table starts with:
# <table width="100%" class="competition-today">
games = page.css('table')[0]

# Get daily matches list
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
    [:competicao, 'td[2]/a/ul/li/@class' ]
  ].each do |name, xpath|
    detail[name] = row.at_xpath(xpath).to_s.strip
  end
  detail
end

# For each daily match, lets get the list of previous 10 games of each team...
details.each do |row|
  if (row[:stats] != "" and not ignore.include? row[:competicao] ) then
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
   
    # Now that we have the games list, lets do the math...
    jogos = 0
    details_games.each do |key, row|
      aux = 1
      key.each do |x, y|
        if (y != '' and y != '-') then
          goals = y.split(/-/) 

          if goals[0].is_integer? then
            if ( over_under == "over" ) then
              jogos = jogos + 1 unless (goals[0].is_integer? and (goals[0].to_i + goals[1].to_i) < goals_thold)
            else
              jogos = jogos + 1 unless (goals[0].is_integer? and (goals[0].to_i + goals[1].to_i) > goals_thold)
            end
          end

        end
      end
    end

    message = message + "#{row[:casa]} - #{row[:fora]} (#{jogos*5}\%)\n" unless (jogos * 5 < percentage_thold)

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
