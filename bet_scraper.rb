
require 'nokogiri'
require 'open-uri'
require 'pp'

#str_friendly="Mundo - Amigáveis Clubes"

page = Nokogiri::HTML(open("https://www.academiadasapostas.com/stats/livescores"))
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

# puts details 

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

    # puts last_games

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
        # puts y
        if (y != '' and y != '-') then
          goals = y.split(/-/)
          if (goals[0].to_i + goals[1].to_i >= 3) then
            aux = aux + 1
          end
        end
      end
    end

    if ((aux * 10)/2 >= 70) then
      puts row[:casa]
      puts row[:fora]
      puts aux
      print "YES!\n\n"
    end

  end
end


#pp details
