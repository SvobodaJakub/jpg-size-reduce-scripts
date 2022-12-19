#!/bin/bash


scriptdir="$(dirname "$0")"
# get absolute path
scriptdir="$( realpath "$scriptdir" || readlink -f "$scriptdir" || { cd "$scriptdir" >/dev/null 2>&1 || exit 2 ; pwd || exit 2 ; cd - >/dev/null 2>&1  || exit 2 ; } )"


# run like this:
# find . -type d -exec bash -c 'cd "$1" && pwd && bash /path/to/jpg-quality-reducer-script.sh' _ {} ';'


# exit on empty variables
set -u

# exit on non-zero status
set -e

# if there are no jpg files, the glob in the for loop is null and the loop doesn't run
# (otherwise it would go on creating crazy directories)
shopt -s nullglob



resolution="4800x4800"
quality="64"

# TODO skip files that are not larger than $resolution - https://unix.stackexchange.com/questions/38943/use-mogrify-to-resize-large-files-while-ignoring-small-ones
# NOTE but mogrify performs chroma subsampling which I actually want

command -v "$scriptdir"/mozjpeg/cjpeg-static >/dev/null 2>&1 || { echo >&2 "mozjpeg not installed, aborting."; exit 1; }
command -v "$scriptdir"/mozjpeg/jpegtran-static >/dev/null 2>&1 || { echo >&2 "jpegtran not installed, aborting."; exit 1; }
command -v exiftool >/dev/null 2>&1 || { echo >&2 "exiftool not installed, aborting."; exit 1; }
command -v identify >/dev/null 2>&1 || { echo >&2 "identify (imagemagick) not installed, aborting."; exit 1; }
command -v mogrify >/dev/null 2>&1 || { echo >&2 "mogrify (imagemagick) not installed, aborting."; exit 1; }

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
    if [[ "$( basename "$( readlink -f . )" )" == backup_before_reducing_quality ]] ; then
        echo "No action - preventing recursion loops."
        exit 0
    fi
    mkdir backup_before_reducing_quality;
    cp -R -- *.[Jj][Pp]*[Gg] backup_before_reducing_quality/
    echo "Resized (if larger than $resolution) and quality reduced using the following command and the following quantization table, using $(convert --version | head -n 1 | sed 's/http.*//g')." > reduced_quality.txt; 
    cat "$0" >> reduced_quality.txt
    for f in *.[Jj][Pp]*[Gg]
    do
        echo "${f}"
        if [[ ! -f "${f}" ]]  # don't care about directories or non-regular files, or when nullglob doesn't work
        then
            echo ": file doesn't exist, skipping"
            continue
        fi

        width="$(identify "$f" | sed -r 's/.* JPEG ([0-9]+x[0-9]+) [0-9]+.*/\1/g' | sed -r 's/([0-9]+)x([0-9]+)/\1/g')"
        height="$(identify "$f" | sed -r 's/.* JPEG ([0-9]+x[0-9]+) [0-9]+.*/\1/g' | sed -r 's/([0-9]+)x([0-9]+)/\2/g')"
        quality=80
        smoothing=0
        highres=0
        if (( ( height > 3600 ) && ( width > 3600 ) && ( height * width > 17000000 ) )) ; then
            quality=74
            highres=2
            echo "resolution higher than 17MPix"
        elif (( ( height > 3000 ) && ( width > 3000 ) && ( height * width > 12000000 ) )) ; then
            quality=75
            highres=2
            echo "resolution higher than 12MPix"
        elif (( ( height > 2400 ) && ( width > 2400 ) && ( height * width > 7680000 ) )) ; then
            quality=75
            highres=1
            echo "resolution higher than 7.6MPix"
        elif (( ( height > 1920 ) && ( width > 1920 ) && ( height * width > 4915200 ) )) ; then
            quality=79
            echo "resolution higher than 4.9MPix"
        else
            quality=85
            echo "resolution lower than 4.9MPix"
        fi

        size_jr=0
        if (( highres == 1 )) ; then
            convert -quality "$quality" -resize "${resolution}"\> -filter Lanczos -interlace Plane -- "${f}" "${f}_qualmeasure"
            size_jr=$(wc -c < "${f}_qualmeasure")
            if (( size_jr < 200000 )) ; then
                quality="$(( quality + 4 ))"
            elif (( size_jr < 300000 )) ; then
                quality="$(( quality + 3 ))"
            elif (( size_jr < 400000 )) ; then
                quality="$(( quality + 2 ))"
            elif (( size_jr < 500000 )) ; then
                quality="$(( quality + 1 ))"
            elif (( size_jr < 600000 )) ; then
                :
            elif (( size_jr < 700000 )) ; then
                smoothing=4
            elif (( size_jr < 800000 )) ; then
                smoothing=8
            elif (( size_jr > 3600000 )) ; then
                quality="$(( quality - 6 ))"
                smoothing=56
            elif (( size_jr > 3100000 )) ; then
                quality="$(( quality - 5 ))"
                smoothing=48
            elif (( size_jr > 2600000 )) ; then
                quality="$(( quality - 5 ))"
                smoothing=40
            elif (( size_jr > 2100000 )) ; then
                quality="$(( quality - 5 ))"
                smoothing=32
            elif (( size_jr > 1700000 )) ; then
                quality="$(( quality - 4 ))"
                smoothing=28
            elif (( size_jr > 1400000 )) ; then
                quality="$(( quality - 3 ))"
                smoothing=24
            elif (( size_jr > 1200000 )) ; then
                quality="$(( quality - 2 ))"
                smoothing=20
            elif (( size_jr > 1000000 )) ; then
                quality="$(( quality - 1 ))"
                smoothing=16
            elif (( size_jr > 800000 )) ; then
                smoothing=12
            fi
            rm -f "${f}_qualmeasure"
        fi
        if (( highres == 2 )) ; then
            convert -quality "$quality" -resize "${resolution}"\> -filter Lanczos -interlace Plane -- "${f}" "${f}_qualmeasure"
            size_jr=$(wc -c < "${f}_qualmeasure")
            if (( size_jr < 200000 )) ; then
                quality="$(( quality + 7 ))"
            elif (( size_jr < 300000 )) ; then
                quality="$(( quality + 6 ))"
            elif (( size_jr < 400000 )) ; then
                quality="$(( quality + 5 ))"
            elif (( size_jr < 500000 )) ; then
                quality="$(( quality + 4 ))"
            elif (( size_jr < 600000 )) ; then
                quality="$(( quality + 3 ))"
            elif (( size_jr < 700000 )) ; then
                quality="$(( quality + 2 ))"
            elif (( size_jr < 800000 )) ; then
                quality="$(( quality + 1 ))"
            elif (( size_jr > 3600000 )) ; then
                quality="$(( quality - 5 ))"
                smoothing=48
            elif (( size_jr > 3100000 )) ; then
                quality="$(( quality - 4 ))"
                smoothing=40
            elif (( size_jr > 2600000 )) ; then
                quality="$(( quality - 3 ))"
                smoothing=32
            elif (( size_jr > 2100000 )) ; then
                quality="$(( quality - 2 ))"
                smoothing=24
            elif (( size_jr > 1700000 )) ; then
                quality="$(( quality - 1 ))"
                smoothing=20
            elif (( size_jr > 1400000 )) ; then
                smoothing=16
            elif (( size_jr > 1200000 )) ; then
                smoothing=12
            elif (( size_jr > 1000000 )) ; then
                smoothing=8
            elif (( size_jr > 800000 )) ; then
                smoothing=4
            fi
            rm -f "${f}_qualmeasure"
        fi
        echo "highres=$highres  quality=$quality  smoothing=$smoothing  testsize=$(( size_jr / 1000 )) kb"
        
        convert -define jpeg:dct-method=float -quality "100" -resize "${resolution}"\> -filter Lanczos -interlace Plane -- "${f}" "${f}_resized"

        # NOTE: it seems qt3 is always the smallest, and also the default choice of mozjpeg, probably for a good reason

        # smallest_size=$(( 1000 * 1000 * 1000 ))
        # smallest_qt=0
        # for qt in {0..5} ; do
        #     if (( smoothing > 0 )) ; then
        #         "$scriptdir"/mozjpeg/cjpeg-static -quality "$quality" -quant-table "$qt" -dct float -smooth "$smoothing" "${f}_resized" > "$f".TMPMOZ."${qt}"
        #     else
        #         "$scriptdir"/mozjpeg/cjpeg-static -quality "$quality" -quant-table "$qt" -dct float "${f}_resized" > "$f".TMPMOZ."${qt}"
        #     fi
        #     size_current=$(wc -c < "$f".TMPMOZ."${qt}" )
        #     echo "qt $qt  size $(( size_current / 1000 )) kB"
        #     if (( size_current < smallest_size )) ; then
        #         smallest_size="${size_current}"
        #         smallest_qt="$qt"
        #     fi
        # done
        # cat "$f".TMPMOZ."${smallest_qt}" > "$f"

        if (( smoothing > 0 )) ; then
            "$scriptdir"/mozjpeg/cjpeg-static -quality "$quality" -dct float -smooth "$smoothing" "${f}_resized" > "$f".TMPMOZ
        else
            "$scriptdir"/mozjpeg/cjpeg-static -quality "$quality" -dct float "${f}_resized" > "$f".TMPMOZ
        fi
        cat "$f".TMPMOZ > "$f"
        rm -f "$f".TMPMOZ* "${f}_resized"

        if [[ ! -s "${f}" ]]
        then
            echo ": file has zero size, stopping"
            continue
        fi
        exiftool -TagsFromFile "backup_before_reducing_quality/${f}" -all:all "${f}" || exiftool -TagsFromFile "backup_before_reducing_quality/${f}" "${f}" || exiftool -TagsFromFile "backup_before_reducing_quality/${f}" -all:all "${f}" || true
        rm -f "$f"_original
        touch -r "backup_before_reducing_quality/${f}" "${f}" # preserve timestamp
        size_new=$(wc -c < "${f}")
        size_orig=$(wc -c < "backup_before_reducing_quality/${f}")
        if (( size_new > ( ( 90 * size_orig ) / 100 ) ))  # actually, it has to reduce the size at least 10% to be worth it
        then
            echo "the orig file is smaller (${size_orig}) than the new one (${size_new})"
            mv "backup_before_reducing_quality/${f}" "${f}"
        fi
    done
    rm -f -- *.[Jj][Pp]*[Gg]~* ;
    rm -rf backup_before_reducing_quality;

else
    echo "No action, quality already reduced."
fi
