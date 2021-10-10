#!/bin/bash

# Check and get args
if [[ -z "$1" ]]; then
	printf 'WARNING: this script is not intended to be executed directly. Please use sync_pio_to_cube.sh or sync_cube_to_pio.sh instead.\nERROR: Missing arguments.\nUSAGE: ./sync.sh input.txt output.txt\n\toutput.txt is optional'
	exit
fi

input="$1"
output="$2"
if [[ -z "$2" ]]; then
	output="/dev/null"
fi

files_regex=".*\.[hcHC]"
printf 'Sync using conf file: %s\nLog synced files into: %s\nFor folders, will sync all files matching regex: %s\n\n' "$input" "$output" "$files_regex"

# Init new output file
now=$(date)
printf '# sync.sh generated this file on the: %s \n' "$now" >"$output"

while IFS= read -r line; do
	# Skip comments and empty lines
	if [[ ${line:0:1} == "#" || -z "$line" ]]; then
		continue
	fi

	# File syntax: "source folder/file":"target folder/file"
	IFS=':'
	split=($line)
	unset IFS
	source=${split[0]}
	target=${split[1]}

	if [[ -d ${source} ]]; then
		printf 'DIR  %-100s => %s\n' "${source}" "${target}"
		# find ${source} -regex ${files_regex} -exec cp {} ${target} \; -exec printf '%s/%s:%s\n' "${target}" $(basename {}) {} \; >>"$output"
		find ${source} -regex ${files_regex} -print0 |
			while IFS= read -r -d '' file; do
				cp ${file} ${target}
				printf '%s/%s:%s\n' "${target}" $(basename $file) ${file} >>"$output"
			done
	elif [[ -f ${source} ]]; then
		printf 'FILE %-100s => %s\n' "${source}" "${target}"
		cp ${source} ${target}
		printf '%s:%s' "${target}" "${source}" >>"$output"
	else
		printf 'ERROR NOT FOUND: %s\n' "${source}"
	fi

done <"$input"
