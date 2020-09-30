#!/bin/bash

### For a CSV of arks, remove item from Production
###   - Remove from Fedora, remove any Tombstone and remove from SOLR
###
###   - Note: Run each section separately by uncommenting and re-commenting each curl command in turn.
###           The curl operation can take several minutes to complete depending on the number of children
###             that are automatically created by Hyrax and other operations.
###
### Example CSV:
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
### Usage
### 
### 1. To delete items from Fedora
### 
###   - Set the ssh tunnel:
### 
### ssh -p 31926 darrowco@jump.library.ucla.edu -L 9984:p-u-californicafedora01.library.ucla.edu:80  
### 
###   - uncomment the two lines starting with:
### 
### ###curl -X DELETE
###
###   - make sure that the other curl line is commented:
### 
### ###curl http://localhost:9983
### 
###   - run the script
### 
### ./rt.sh
### 
### 
### 2. To delete items from SOLR
### 
###   - Set the ssh tunnel:
### 
### ssh -p 31926 darrowco@jump.library.ucla.edu -L 9983:p-u-californicasolr01.library.ucla.edu:80
### 
###   - uncomment the line starting with:
### 
### ###curl http://localhost:9983
### 
###   - make sure that the other 2 curl lines are commented:
### 
### ###curl -X DELETE A
### ###curl -X DELETE B
### 
###   - run the script
### 
### ./rt.sh
### 

cnt=0
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
    echo ""
    echo "9 - ${line9}"
    ### query status item with current ark
    curl ${line9}

    ### delete item from Fedora using the current ark
    #echo "curl -X DELETE ${line9}"
    #echo ""
    #curl -X DELETE ${line9}

    ### delete tombstone from Fedora using the current ark
    #line10="${line9}/fcr:tombstone"
    #echo "curl -X DELETE ${line10}"
    #curl -X DELETE "${line10}"
    
    ### delete item from Solr using the current ark
    #line11="curl http://localhost:9983/solr/calursus/update?commit=true -H \"Content-Type: text/xml\" --data-binary \'<delete><query>ark_ssi:\"${line2}\"</query></delete>\'"
    #curl http://localhost:9983/solr/calursus/update?commit=true -H \"Content-Type: text/xml\" --data-binary \'<delete><query>ark_ssi:\"${line2}\"</query></delete>\'
    #echo "11 - ${line11}"
  fi

  ### This delay did not always work as sometimes the curl aommand took many minutes to complete
  #sleep 240

done < sinai_prod.csv
###done < sinai_prod_test.csv

