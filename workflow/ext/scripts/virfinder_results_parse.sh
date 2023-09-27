
# snakemake doesn't like awk =(
# this is a provisory script to just move things forward. 
# a more elegant solution will be sought!

#cat "$1" | awk -F'\t' '{ if ($4 <= 0.01) print }' | awk -F'_' '{ if ($4 >= 1000) print }' | cut -f2 | sed 's/\"//g' > "$2"

cat $1 | awk -F'\t' '{ if ($4 <= 0.01) print }' |  awk -F'_' '{ if ($4 >= 1000) print }' | cut -f2 | sed 's/\"//g' > $2


#cat  $1 | awk -F'\t' "{ if ( $4 <= 0.01) print }" | awk -F'_' "{ if ( $4 >= 1000) print }" | cut -f2 | sed "s/\"//g" > $2 


