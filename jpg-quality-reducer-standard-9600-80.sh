#!/bin/bash


# run like this:
# find . -type d -exec bash -c 'cd "$1" && pwd && bash /path/to/jpg-quality-reducer-script.sh' _ {} ';'


# exit on empty variables
set -u

# exit on non-zero status
set -e

# if there are no jpg files, the glob in the for loop is null and the loop doesn't run
# (otherwise it would go on creating crazy directories)
shopt -s nullglob



resolution="9600x9600"
quality="80%"

quantization_table="/tmp/jpg-quality-reducer-quantization-table.xml"


cat > "$quantization_table" << EOF

<?xml version="1.0" encoding="windows-1252"?>
<!DOCTYPE quantization-tables [
<!ELEMENT quantization-tables (table)+>
<!ELEMENT table (description , levels)>
<!ELEMENT description (CDATA)>
<!ELEMENT levels (CDATA)>
<!ATTLIST table slot ID #REQUIRED>
<!ATTLIST levels width CDATA #REQUIRED>
<!ATTLIST levels height CDATA #REQUIRED>
<!ATTLIST levels divisor CDATA #REQUIRED>
]>
<!--
  JPEG quantization table created by Dr. Nicolas Robidoux, Senior Research
  Scientist at Phase One (www.phaseone.com) for use with 2x2 Chroma
  subsampling and (IJG-style, hence ImageMagick-style) quality level
  around 75.

  It is based on the one recommended in

    Relevance of human vision to JPEG-DCT compression by Stanley A. Klein,
    Amnon D. Silverstein and Thom Carney. In Human Vision, Visual
    Processing and Digital Display III, 1992.

  for 1 minute per pixel viewing.

  Specifying only one table in this xml file has two effects when used with
  the ImageMagick option
  
    -define jpeg:q-table=PATH/TO/THIS/FILE
  
  1) This quantization table is automatically used for all three channels;

  2) Only one copy is embedded in the JPG file, which saves a few bits
     (only worthwhile for very small thumbnails).
-->
<quantization-tables>
  <table slot="0" alias="luma">
    <description>Luma Quantization Table</description>
    <levels width="8" height="8" divisor="1">
      16,  16,  16,  18,  25,  37,  56,  85,
      16,  17,  20,  27,  34,  40,  53,  75,
      16,  20,  24,  31,  43,  62,  91,  135,
      18,  27,  31,  40,  53,  74,  106, 156,
      25,  34,  43,  53,  69,  94,  131, 189,
      37,  40,  62,  74,  94,  124, 169, 238,
      56,  53,  91,  106, 131, 169, 226, 311,
      85,  75,  135, 156, 189, 238, 311, 418
    </levels>
  </table>
<!--
  If you want to use a different quantization table for Chroma (say), just add 

  <table slot="1" alias="chroma">
    <description>Chroma Quantization Table</description>
    INSERT 64 POSITIVE INTEGERS HERE, COMMA-SEPARATED
    </levels>
  </table>

  here (but outside of these comments).
-->
</quantization-tables>

EOF


if [[ ! -f reduced_quality.txt ]]; then
    files_exist=0
    for f in *.[Jj][Pp]*[Gg]
    do
        files_exist=1
        break
    done
    if (( files_exist == 0 )) ; then
        echo "No action - no pictures."
        exit 0
    fi
    mkdir backup_before_reducing_quality;
    cp -lR -- *.[Jj][Pp]*[Gg] backup_before_reducing_quality/
    echo "Resized (if larger than $resolution) and quality reduced using the following command and the following quantization table, using $(convert --version | head -n 1 | sed 's/http.*//g')." > reduced_quality.txt; 
    cat "$0" >> reduced_quality.txt
    nice -n 16 mogrify -define jpeg:q-table="${quantization_table}" -sampling-factor 4:2:0 -define jpeg:dct-method=float -quality "$quality" -resize "${resolution}"\> -filter Lanczos -interlace Plane -- *.[Jj][Pp]*[Gg] ;
    rm -f -- *.[Jj][Pp]*[Gg]~* ;
    for f in *.[Jj][Pp]*[Gg]
    do
        echo -n "${f}"
        if [[ ! -f "${f}" ]]  # don't care about directories or non-regular files, or when nullglob doesn't work
        then
            echo ": file doesn't exist, skipping"
            continue
        fi
        if [[ ! -s "${f}" ]]
        then
            echo ": file has zero size, skipping"
            continue
        fi
        touch -r "backup_before_reducing_quality/${f}" "${f}" # preserve timestamp
        size_new=$(wc -c < "${f}")
        size_orig=$(wc -c < "backup_before_reducing_quality/${f}")
        if (( size_new > size_orig ))
        then
            echo "the orig file is smaller (${size_orig}) than the new one (${size_new})"
            mv "backup_before_reducing_quality/${f}" "${f}"
        fi
    done
    rm -rf backup_before_reducing_quality;

else
    echo "No action, quality already reduced."
fi
