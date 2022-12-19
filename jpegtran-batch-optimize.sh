#!/bin/bash

# edit lineage:
# 170801
# 170803
# 180603
# 210917

# exit on empty variables
set -u

# exit on non-zero status
set -e

# if there are no jpg files, the glob in the for loop is null and the loop doesn't run
# (otherwise it would go on creating crazy directories)
shopt -s nullglob

# performs lossless optimization on all jpeg file in the directory (non-recursive)
# no warranty, use at your own risk
# always test before use on important data

# to run recursively,
# find . -type d -exec bash -c 'cd "$1" && pwd && bash /path/to/jpegtran-batch-optimize.sh' _ {} ';'

command -v jpegtran >/dev/null 2>&1 || { echo >&2 "jpegtran not installed, aborting."; exit 1; }

errors=0
total_bytes_saved=$((0))
total_bytes_orig=$((0))

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
    size_orig=$(wc -c < "${f}")
    total_bytes_orig=$(( total_bytes_orig + size_orig ))
    jpegtran_error=0
    mkdir "${f}-o"
    jpegtran -copy all -perfect -optimize -outfile "${f}-o/${f}" "${f}" || jpegtran_error=1
    touch -r "${f}" "${f}-o/${f}" # preserve timestamp
    mkdir "${f}-op"
    jpegtran -copy all -perfect -optimize -progressive -outfile "${f}-op/${f}" "${f}" || jpegtran_error=1
    touch -r "${f}" "${f}-op/${f}" # preserve timestamp
    mkdir "${f}-p"
    jpegtran -copy all -perfect -progressive -outfile "${f}-p/${f}" "${f}" || jpegtran_error=1
    touch -r "${f}" "${f}-p/${f}" # preserve timestamp
    if (( jpegtran_error ))
    then
        echo "jpegtran exited with non-zero error code, please check the source file, skipping"
        errors=1
        rm -f "${f}-o/${f}" || true
        rm -f "${f}-op/${f}" || true
        rm -f "${f}-p/${f}" || true
        rmdir "${f}-o" || true
        rmdir "${f}-op" || true
        rmdir "${f}-p" || true
    else
        size_o=$(wc -c < "${f}-o/${f}")
        size_op=$(wc -c < "${f}-op/${f}")
        size_p=$(wc -c < "${f}-p/${f}")
        size_orig_third=$(( size_orig / 3 ))
        smallest_file_name="${f}"
        smallest_size="${size_orig}"
        if (( smallest_size > size_o ))
        then
            smallest_size="${size_o}"
            smallest_file_name="${f}-o/${f}"
        fi
        if (( smallest_size > size_op ))
        then
            smallest_size="${size_op}"
            smallest_file_name="${f}-op/${f}"
        fi
        if (( smallest_size > size_p ))
        then
            smallest_size="${size_p}"
            smallest_file_name="${f}-p/${f}"
        fi
        # sanity check - if it is too small, it is most probably wrong
        if (( smallest_size < size_orig_third ))
        then
            echo -n >&2 ": sanity check error, please inspect the file"
            smallest_file_name="${f}"
            smallest_size="${size_orig}"
            echo -n ": size_o=${size_o} size_op=${size_op} size_p=${size_p} size_orig_third=${size_orig_third} size_orig=${size_orig} smallest_size=${smallest_size} smallest_file_name=${smallest_file_name}"
        fi

        if [[ "${smallest_file_name}" != "${f}" ]]
        then
            # if the smallest file is not the original, move the new one in place of the orig
            mv "${smallest_file_name}" "${f}"
            percent_saved=$(( ( ( size_orig - smallest_size ) * 100 ) / size_orig ))
            bytes_saved=$(( ( size_orig - smallest_size ) ))
            echo ": ${percent_saved} percent saved, ${bytes_saved} bytes saved, ${size_orig} -> ${smallest_size}"
            total_bytes_saved=$(( total_bytes_saved + bytes_saved ))
        else
            echo ": no change"
        fi
        rm -f "${f}-o/${f}"
        rm -f "${f}-op/${f}"
        rm -f "${f}-p/${f}"
        rmdir "${f}-o"
        rmdir "${f}-op"
        rmdir "${f}-p"
    fi
done

if (( total_bytes_orig > 0 )) # prevent division by zero, don't print uninteresting stats
then
    echo "total bytes orig: ${total_bytes_orig}"
    echo "total bytes saved: ${total_bytes_saved}"
    total_mib_orig=$(( total_bytes_orig * 100 / 1024 / 1024 ))
    total_mib_orig="${total_mib_orig%??}.${total_mib_orig:(-2)}" # convert to a string that looks like a number with two decimal places
    total_mib_saved=$(( total_bytes_saved * 100 / 1024 / 1024 ))
    total_mib_saved="${total_mib_saved%??}.${total_mib_saved:(-2)}" # convert to a string that looks like a number with two decimal places
    echo "total MiB orig: ${total_mib_orig}"
    echo "total MiB saved: ${total_mib_saved}"
    total_percent_saved=$(( ( ( total_bytes_saved ) * 100 * 10 ) / total_bytes_orig ))
    total_percent_saved="${total_percent_saved%?}.${total_percent_saved:(-1)}" # convert to a string that looks like a number with one decimal place
    echo "percent saved: ${total_percent_saved}"
fi
if (( errors ))
then
    echo "There were errors. The original faulty files were preserved and not overwritten so as not to lose additional data."
fi
