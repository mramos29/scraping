#!/bin/bash
#set -x

MATCHES_TOMORROW="/tmp/tomorrow_matches.txt"
MATCH="/tmp/match.txt"
BASE_URL="https://www.soccerstats.com"
HOME_TEAM_HOME="/tmp/home_home.txt"
AWAY_TEAM_AWAY="/tmp/away_away.txt"
HOME_TEAM_TOTAL="/tmp/home_total.txt"
AWAY_TEAM_TOTAL="/tmp/away_total.txt"

curl -s "${BASE_URL}/matches.asp?matchday=6" > $MATCHES_TOMORROW

for i in `grep -o "pmatch.asp?[a-zA-Z0-9_-=&]*" $MATCHES_TOMORROW | sed "s/'//"`
do
  TOTAL=0
  
  # Lets get all matches info
  curl -s "${BASE_URL}/${i}" > ${MATCH}

  # echo "Ultimos 3 jogos da equipa da casa"
  grep "<td align='right'" ${MATCH} | head -3 | awk -F"<b>" '{print $3}' | awk -F"</b" '{print $1}' > ${HOME_TEAM_TOTAL}

  # echo "Ultimos 3 jogos da equipa de fora"
  grep "<td align='left'" ${MATCH} | head -3 | awk -F"<b>" '{print $2}' | awk -F"</b>" '{print $1}' > ${AWAY_TEAM_TOTAL}
  
  TOTAL_LINES=`wc -l ${MATCH} | awk '{print $1}'`
  AUX_LINE=`grep -n "Latest at home" ${MATCH} | awk -F":" '{print $1}'`

  if [[ $AUX_LINE == "" ]]
  then 
    continue
  fi
  
  LINES=`expr ${TOTAL_LINES} - ${AUX_LINE}`

  # echo "Ultimos 3 resultados da equipa da casa em casa"
  tail -${LINES} ${MATCH} | grep "<td align='right'" | head -3 | awk -F"<b>" '{print $3}' | awk -F"</b" '{print $1}' > ${HOME_TEAM_HOME}

  # echo "Ultimos 3 resultados da equipa de fora a jogar fora"
  tail -${LINES} ${MATCH} | grep "<td align='left'" | head -3 | awk -F"<b>" '{print $2}' | awk -F"</b>" '{print $1}' > ${AWAY_TEAM_AWAY}

  # Vamos avaliar os criterios
  # H1 - over 2.5 em 2 ou 3 jogos como visitado
  # H2 - 8 ou mais golos no total dos jogos como visitado
  H1=0
  H2=0
  for i in `cat ${HOME_TEAM_HOME}`
  do
    x=`echo $i | cut -d "-" -f 1`
    y=`echo $i | cut -d "-" -f 2`
    z=`expr $x + $y`

    if [[ $z -ge 3 ]]
    then
      H1=`expr $H1 + 1`
    fi

    H2=`expr $H2 + $x + $y`
  done

  # Vamos calclular a probablidade
  if [[ $H1 -eq 2 ]]
  then
    TOTAL=`expr $TOTAL + 10`
  elif [[ $H1 -eq 3 ]]
  then
    TOTAL=`expr $TOTAL + 15`
  fi 

  if [[ $H2 -ge 15 ]]
  then
    TOTAL=`expr $TOTAL + 15`
  else
    TOTAL=`expr $TOTAL + $H2`
  fi

  # H3 - over 2.5 em 2 ou 3 jogos no geral
  # H4 - 8 ou mais golos no total dos jogos no geral
  H3=0
  H4=0
  for i in `cat ${HOME_TEAM_TOTAL}`
  do
    x=`echo $i | cut -d "-" -f 1`
    y=`echo $i | cut -d "-" -f 2`
    z=`expr $x + $y`

    if [[ $z -ge 3 ]]
    then
      H3=`expr $H3 + 1`
    fi

    H4=`expr $H4 + $x + $y`
  done
  
  # Vamos calclular a probablidade
  if [[ $H3 -eq 2 ]]
  then
    TOTAL=`expr $TOTAL + 5`
  elif [[ $H3 -eq 3 ]]
  then
    TOTAL=`expr $TOTAL + 10`
  fi 
  
  if [[ $H4 -ge 15 ]]
  then
    TOTAL=`expr $TOTAL + 10`
  else
    TOTAL=`expr $TOTAL + $H4 - 15 + 10`
  fi

  # H5 - não pode ter havido 0-0 nos ultimos 2 jogos totais
  # H6 - ultimo jogo tem que ter tido pelo menos 2 golos
  H5=0
  H6=0
  for i in `head -2 ${HOME_TEAM_TOTAL}`
  do
    x=`echo $i | cut -d "-" -f 1`
    y=`echo $i | cut -d "-" -f 2`
    z=`expr $x + $y`

    if [[ $z -eq 0 ]]
    then
      H5=`expr $H5 + 1`
    fi
  done

  x=`head -1 ${HOME_TEAM_TOTAL} | cut -d "-" -f 1`
  y=`head -1 ${HOME_TEAM_TOTAL} | cut -d "-" -f 2`
  H6=`expr $x + $y` 
  
  # A1 - over 2.5 em 2 ou 3 jogos como visitante
  # A2 - 8 ou mais golos no total dos jogos como visitado
  A1=0
  A2=0
  for i in `cat ${AWAY_TEAM_AWAY}`
  do
    x=`echo $i | cut -d "-" -f 1`
    y=`echo $i | cut -d "-" -f 2`
    z=`expr $x + $y`

    if [[ $z -ge 3 ]]
    then
      A1=`expr $A1 + 1`
    fi

    A2=`expr $A2 + $x + $y`
  done
  
  # Vamos calclular a probablidade
  if [[ $A1 -eq 2 ]]
  then
    TOTAL=`expr $TOTAL + 10`
  elif [[ $A1 -eq 3 ]]
  then
    TOTAL=`expr $TOTAL + 15`
  fi 

  if [[ $A2 -ge 15 ]]
  then
    TOTAL=`expr $TOTAL + 15`
  else
    TOTAL=`expr $TOTAL + $A2`
  fi

  # A3 - over 2.5 em 2 ou 3 jogos no geral
  # A4 - 8 ou mais golos no total dos jogos no geral
  A3=0
  A4=0
  for i in `cat ${AWAY_TEAM_TOTAL}`
  do
    x=`echo $i | cut -d "-" -f 1`
    y=`echo $i | cut -d "-" -f 2`
    z=`expr $x + $y`

    if [[ $z -ge 3 ]]
    then
      A3=`expr $A3 + 1`
    fi

    A4=`expr $A4 + $x + $y`
  done
  

  # Vamos calclular a probablidade
  if [[ $A3 -eq 2 ]]
  then
    TOTAL=`expr $TOTAL + 5`
  elif [[ $A3 -eq 3 ]]
  then
    TOTAL=`expr $TOTAL + 10`
  fi 
  
  if [[ $A4 -ge 15 ]]
  then
    TOTAL=`expr $TOTAL + 10`
  else
    TOTAL=`expr $TOTAL + $A4 - 15 + 10`
  fi

  # A5 = não pode ter havido 0-0 nos ultimos 3 jogos totais
  # A6 = no utlimo jogo tem que ter havido pelo menos 2 golos
  A5=0
  A6=0
  for i in `head -2 ${AWAY_TEAM_TOTAL}`
  do
    x=`echo $i | cut -d "-" -f 1`
    y=`echo $i | cut -d "-" -f 2`
    z=`expr $x + $y`

    if [[ $z -eq 0 ]]
    then
      A5=`expr $A5 + 1`
    fi
  done
  
  x=`head -1 ${AWAY_TEAM_TOTAL} | cut -d "-" -f 1`
  y=`head -1 ${AWAY_TEAM_TOTAL} | cut -d "-" -f 2`
  A6=`expr $x + $y` 


  # Se houve 0-0, não queremos este jogo...
  if [[ $H5 -ne 0 ]]
  then
    continue
  fi
  
  if [[ $A5 -ne 0 ]]
  then
    continue
  fi

  # Se o ultimo jogo no geral não houve pelo menos 2 golos, não queremos este jogo...
  if [[ "$H6" -lt 2 ]]
  then
    continue
  fi
  
  if [[ "$A6" -lt 2 ]]
  then
    continue
  fi

  # Se H1<2 ou A1<2, não queremos este jogo...
  if [[ "$H1" -lt 2 ]]
  then
    continue
  fi
  
  if [[ "$A1" -lt 2 ]]
  then
    continue
  fi
  
  # Se H2<8 ou A2<8, não queremos este jogo...
  if [[ "$H2" -lt 8 ]]
  then
    continue
  fi
  
  if [[ "$A2" -lt 8 ]]
  then
    continue
  fi
  
  # Se H3<2 ou A3<2, não queremos este jogo...
  if [[ "$H3" -lt 2 ]]
  then
    continue
  fi
  
  if [[ "$A3" -lt 2 ]]
  then
    continue
  fi
  
  # Se H4<8 ou A4<8, não queremos este jogo...
  if [[ "$H4" -lt 8 ]]
  then
    continue
  fi
  
  if [[ "$A4" -lt 8 ]]
  then
    continue
  fi

  if [[ ${TOTAL} -ge 70 ]]
  then 
    # What's the match?
    grep title ${MATCH} | head -1 | awk -F">" '{print $2}' | awk -F"<" '{print $1}'
    echo "TOTAL: ${TOTAL}"
    #echo "H1: $H1; H2: $H2; H3: $H3; H4: $H4; A1: $A1; A2: $A2; A3: $A3; A4: $A4"
    echo
  fi

done

