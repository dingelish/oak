cat output.txt | grep label  | cut -d ',' -f 2 | cut -d '"' -f 1 | awk '{s+=$1} END {print s}'
