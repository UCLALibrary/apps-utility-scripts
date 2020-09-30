#!/bin/bash

### This script is for investigating a record and child records in Fedora
### NOT ADVISABLE: A curl command _could_ be added to delete the child records
### There may be thousands of child items
### - deleting manually may be inadvisable and may have unexpected consequences
### - the child records can be deleted with deletion of the parent
### - deletion of the parent should delete the child records as well but may take sevaeral minutes and should be verified
###
### This script operates by reading a file of arks, curling each for information, extracting the child arks for printing to screen or deletion
###
### Example of file containing arks of interest:
###
###   Item ARK
###   ark:/21198/z1g74j17,
###   ark:/21198/z1bg3sbz,
###   ark:/21198/z1z61s9k,
###
### Example curl commands:
###
###   curl -X DELETE http://localhost:9984/fcrepo/rest/prod/zb/s3/gb/1z/zbs3gb1z-89112
###   curl -X DELETE http://localhost:9984/fcrepo/rest/prod/zb/s3/gb/1z/zbs3gb1z-89112/fcr:tombstone
###   curl http://localhost:9983/solr/calursus/update?commit=true -H "Content-Type: text/xml" --data-binary '<delete><query>ark_ssi:"ark:/21198/z1bg3sbz"</query></delete>'
### 

cnt=0
fcnt=0
lcnt=0
while IFS= read -r line
do
  if [[ $line =~ "ark:/" ]]
  then
    cnt=$((cnt+1))
    #echo "${cnt} - ${line}"
    line2=${line#ark:/}
    #echo "2 - ${line2}"
    line3=$(echo $line2 | sed 's/,*$//')
    #  line3=${line2::-1}
    #echo "3 - ${line3}"
    line4=${line3/\//-}
    #echo "4 - ${line4}"
    line5=$(echo $line4 | rev)
    #echo "5 - ${line5}"
    IFS='-' read -ra my_array <<< "$line5"
    #echo "6 - ${my_array[0]}"
    line7=""
    for (( i=0; i<${#my_array[0]}; i++ )); do
      if [ $(( $i % 2 )) -eq 0 ]; then                                
        line7+="/"
      fi
      line7+=${my_array[0]:$i:1}
    done
    line7+="/"
    #echo "7 - ${line7}"
    line8=""
    line8=${line7}${line5}
    #echo "8 - ${line8}"
    line9="http://localhost:9984/fcrepo/rest/prod${line8}"

    echo ""
    echo "Collection ${cnt} - curl ${line9}"
    echo ""
    curl_output="$(curl ${line9} 2>&1)"
  
    if [[ "${curl_output}" =~ ldp:contains.{20}(http://localhost:9984/fcrepo/rest/prod/[a-zA-Z0-9/]+[a-zA-Z0-9]+-[0-9]+/members) ]]; then
      echo "children exist - ${BASH_REMATCH[1]}"

      ### format is retained when saving to a file
      curl ${BASH_REMATCH[1]}>coutput.txt

      ### read the file back in one line at a time
      while IFS= read -r line_inner
      do
        if [[ "${line_inner}" =~ ldp:contains.{18}(http://localhost:9984/fcrepo/rest/prod/[a-zA-Z0-9/]+[a-zA-Z0-9]+-[0-9]+/.*-.*-.*-.*-.*)\>.* ]]; then
          echo "${lcnt} child - ${BASH_REMATCH[1]}"

          ### add curl here to delete child
          ### there may be thousands of child items
          ### - deleting manually may be inadvisable
          ### - deletion of the parent should delete these as well but may take sevaeral minutes

          lcnt=$((lcnt+1))
        fi

        ### alternative string extraction to get url
        string_start_middle_end=${line_inner/ldp*\</}
        string_middle_end=${string_start_middle_end/\> ;/}
        string_middle=${string_middle_end/\> ./}
      done < coutput.txt
    else
      echo 'No comment!'
    fi
  fi
done < sinai_prod.csv

