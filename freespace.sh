#!/bin/sh

timeOut=48
recursive=false
files_list=""

is_file_compressed() {
	filename=$1
	postfix="${filename##*.}"
	if [[ $postfix == "zip" ]] || [[ $postfix  == "cmpr" ]] || [[ $postfix == "tgz" ]] || [[ $postfix == "bz2" ]]; then
		return 0
	else 
		return 1
	fi
}

while getopts "rt::" opt; do
	case ${opt} in
	      r)
	         recursive=true;;
	      t)
	        timeOut=${OPTARG};;
	esac

done
shift $((OPTIND -1))

files_list=$@

if [[ $files_list == "" ]]; then
	echo file is missing
	exit 1
fi

echo recursive:$recursive
echo tineOut:$timeOut
echo $files_list

files=()
for file in $files_list; do
	if [ -d "$file" ]; then
		if [ $recursive = true ]; then
             		files+=$(find $file -type f)
     		else
             		files+=$(find $file -maxdepth 1 -type f)
     		fi
     	else
     		files+=($file)
	fi
done

echo files: ${files[*]}

for file_path in $files; do
	echo file_path: $file_path

	filename=$(basename -- "$file_path")
	echo $filename
	if [[ $filename == fc-* ]]; then
		file_created_time=$(stat -f%c $file_path)
		now=$(date +%s)
		diff=$(((now-file_created_time)/60/60))
		if [[ $diff > $timeOut ]]; then
			rm -f $file_path
			continue
		elif is_file_compressed $file_path; then continue
		fi
	elif is_file_compressed $file_path; then
		new_file_path=$(dirname "$file_path")/fc-$(basename "$file_path")
		mv $file_path $new_file_path
		touch $new_file_path
	else
		zip $(dirname "$file_path")/fc-$(basename "$file_path") $file_path
	fi
done
