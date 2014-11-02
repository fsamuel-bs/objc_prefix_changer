#!/bin/bash

#CLOSE XCODE BEFORE RUNNING THE SCRIPT. IT ALSO HAS GIT PRIVELEGES AND MESSES UP 
# GIT MV EXECUTED IN THIS PROJECT

#set -e

all_extensions=".m .h .xib"
prefix_from=`# PUT OLD PREFIX HERE`
prefix_to=`# PUT NEW PREFIX HERE`
project_name=`# PUT PROJECT NAME HERE`
test_name=`# PUT TEST PROJECT NAME HERE`

project=`find ${project_name}.xcodeproj -name "project.pbxproj"`
storyboard=`find . -name "MainStoryboard.storyboard"`

#replace_filename_in_file $file_name $new_file_name $file_to_replace_pattern
replace_filename_in_file () {
  sed -e "s/\([^a-zA-Z]\)$1\([^a-zA-Z]\)/\1$2\2/g" \
      -e "s/^$1\([^a-zA-Z]\)/$2\1/g" \
      -e "s/\([^a-zA-Z]\)$1$/\1$2/g" \
      -e "s/^$1$/$2/g" -i '' $3
}
export -f replace_filename_in_file

#replace_filename_in_all_files $file_name $new_file_name
replace_filename_in_all_files() {
  files_with_m=()
  files_with_m=`find $project_name -type f -name "*.m" -exec grep -l [^a-zA-Z]$1[^a-zA-Z] {} ";"`
  files_with_m=(${files_with_m[@]} `find $test_name -type f -name "*.m" -exec grep -l [^a-zA-Z]$1[^a-zA-Z] {} ";"`)

  files_with_h=()
  files_with_h=`find $project_name -type f -name "*.h" -exec grep -l [^a-zA-Z]$1[^a-zA-Z] {} ";"`
  files_with_h=(${files_with_h[@]} `find $test_name -type f -name "*.h" -exec grep -l [^a-zA-Z]$1[^a-zA-Z] {} ";"`)

  files_with_xib=()
  files_with_xib=`find $project_name -type f -name "*.xib" -exec grep -l [^a-zA-Z]$1[^a-zA-Z] {} ";"`
  files_with_xib=(${files_with_xib[@]} `find $test_name -type f -name "*.xib" -exec grep -l [^a-zA-Z]$1[^a-zA-Z] {} ";"`)

  stack=()

  ( for file_m in ${files_with_m[@]}; do
    replace_filename_in_file $1 $2 $file_m
  done )& stack[0]=$!

  ( for file_h in ${files_with_h[@]}; do
    replace_filename_in_file $1 $2 $file_h
  done )& stack[1]=$!

  ( for file_xib in ${files_with_xib[@]}; do
    replace_filename_in_file $1 $2 $file_xib
  done )& stack[2]=$!

  ( replace_filename_in_file $1 $2 $project
  )& stack[3]=$!

  ( replace_filename_in_file $1 $2 $storyboard
  )& stack[4]=$!

  for job in ${stack[@]}; do
    wait $job
  done
}
export -f replace_filename_in_all_files

#replace_path $file_name $new_file_name $extension
replace_path () {
  all_old_paths=()
  all_old_paths=`find $project_name -type f -name "$1*$3"`
  all_old_paths=(${all_old_paths[@]} `find $test_name -type f -name "$1*$3"`)
  for old_path in ${all_old_paths[@]}
  do
    new_path=`echo $old_path | sed "s/$1/$2/g"`
    echo "Old path: $old_path"
    echo "New path: $new_path"
    git mv $old_path $new_path
  done
}
export -f replace_path


main () {
  files_already_updated=()
  for extension in $all_extensions
  do
    files=()
    files=`find $project_name -type f -name "*$extension" | grep -o "\/\w*$extension*$" |
    sed "s/^\/\([a-zA-Z]*\)$extension$/\1/g"`
    files=(${files[@]} `find $test_name -type f -name "*$extension" | grep -o "\/\w*$extension*$" |
    sed "s/^\/\([a-zA-Z]*\)$extension$/\1/g"`)

    for file_name in ${files[@]}
    do
      if [[ "$file_name" == *"$prefix_from"* ]]; then
        file_name_without_prefix="${file_name:${#prefix_from}}"
        new_file_name="$prefix_to$file_name_without_prefix"
      else
        new_file_name="$prefix_to$file_name"
      fi

      echo "Current file name: $file_name"
      echo "New file name: $new_file_name"

      replace_path $file_name $new_file_name $extension

      echo '---------------------------------------------'

      echo "Rename file reference with name ending in *$extension"

      #${files_already_updated[*]/%$file_name/}: for-each on files_already_updated executing sed s/$file_name$//
      if [ "${files_already_updated[*]/%$file_name/}" == "${files_already_updated[*]}" ]
      then
        replace_filename_in_all_files $file_name $new_file_name
        files_already_updated+=($file_name)
      fi
    done
  done

  #Corrects possible changes in main.m
  replace_path "${prefix_to}main" "main" ".m"
  replace_filename_in_all_files "${prefix_to}main" "main"

  #Sets standard header to new one
  sed -i "" -l "s/\(CLASSPREFIX = \)${prefix_from}/\1${prefix_to}/g" $project
}

main
git cm -m 'Renames all the files to new class prefix'
git add .
git reset HEAD refactor.sh
git cm -m 'Modifies prefix of classes inside all files to new class prefix'