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



resolution="6400x6400"
quality="70%"



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
    nice -n 16 mogrify -sampling-factor 4:2:0 -define jpeg:dct-method=float -quality "$quality" -resize "${resolution}"\> -filter Lanczos -interlace Plane -- *.[Jj][Pp]*[Gg] ;
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
