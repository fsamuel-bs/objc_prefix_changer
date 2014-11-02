#!/bin/bash
set -e 

replace_filename_in_file () {
    sed  -i '' -l "s/\([\.\"\* ]\)$1\([\.\"\* ]\)/\1$2\2/g" $3
}
export -f replace_filename_in_file


all_postfix=".m .h .xib"
prefix_from=`# PUT OLD PREFIX HERE`
prefix_to=`# PUT NEW PREFIX HERE`
project_name=`# PUT PROJECT NAME HERE`

for postfix in $all_postfix
do
  files=`find $project_name -type f -name "*$postfix" | grep -oh "\/\w*$postfix*$" | sed "s/^\/\([a-zA-Z]*\)$postfix$/\1/g"`

  for file_name in $files
  do
    if [[ "$file_name" == *"$prefix_from"* ]]; then
      file_name_without_prefix="${file_name:${#prefix_from}}"
      new_file_name="$prefix_to$file_name_without_prefix"
    else
      new_file_name="$prefix_to$file_name"
    fi

    echo "Current file name: $file_name"
    echo "New file name: $new_file_name"

    all_old_paths=`find $project_name -type f -name "$file_name*$postfix"`
    for old_path in $all_old_paths
    do
      new_path=`echo $old_path | sed "s/$file_name/$new_file_name/g"`
      echo "Old path: $old_path"
      echo "New path: $new_path"
      git mv $old_path $new_path
    done

    echo '---------------------------------------------'

    stack=()
    echo "Rename file reference with name ending in *$postfix"
    files_with_m=`find $project_name -type f -name "*.m"`
    files_with_h=`find $project_name -type f -name "*.h"`
    files_with_xib=`find $project_name -type f -name "*.xib"`
    project=`find . -name "project.pbxproj"`
    storyboard=`find . -name "MainStoryboard.storyboard"`
    ( for file_m in $files_with_m; do
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name\([^a-zA-Z]\)/\1$new_file_name\2/g" $file_m &&
        sed  -i '' -l "s/^$file_name\([^a-zA-Z]\)/$new_file_name\1/g" $file_m &&
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name$/\1$new_file_name/g" $file_m &&
        sed  -i '' -l "s/^$file_name$/$new_file_name/g" $file_m
      done )& stack[0]=$!
    
    ( for file_h in $files_with_h; do
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name\([^a-zA-Z]\)/\1$new_file_name\2/g" $file_h &&
        sed  -i '' -l "s/^$file_name\([^a-zA-Z]\)/$new_file_name\1/g" $file_h &&
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name$/\1$new_file_name/g" $file_h &&
        sed  -i '' -l "s/^$file_name$/$new_file_name/g" $file_h
      done )& stack[1]=$!

    ( for file_xib in $files_with_xib; do
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name\([^a-zA-Z]\)/\1$new_file_name\2/g" $file_xib &&
        sed  -i '' -l "s/^$file_name\([^a-zA-Z]\)/$new_file_name\1/g" $file_xib &&
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name$/\1$new_file_name/g" $file_xib &&
        sed  -i '' -l "s/^$file_name$/$new_file_name/g" $file_xib
      done )& stack[2]=$!
    
    (   sed  -i '' -l "s/\([^a-zA-Z]\)$file_name\([^a-zA-Z]\)/\1$new_file_name\2/g" $project &&
        sed  -i '' -l "s/^$file_name\([^a-zA-Z]\)/$new_file_name\1/g" $project &&
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name$/\1$new_file_name/g" $project &&
        sed  -i '' -l "s/^$file_name$/$new_file_name/g" $project
    )& stack[3]=$!
   
    (   sed  -i '' -l "s/\([^a-zA-Z]\)$file_name\([^a-zA-Z]\)/\1$new_file_name\2/g" $storyboard &&
        sed  -i '' -l "s/^$file_name\([^a-zA-Z]\)/$new_file_name\1/g" $storyboard &&
        sed  -i '' -l "s/\([^a-zA-Z]\)$file_name$/\1$new_file_name/g" $storyboard &&
        sed  -i '' -l "s/^$file_name$/$new_file_name/g" $storyboard
    )& stack[4]=$!
    
    for job in ${stack[@]}; do
      wait $job
    done
#    find . -name "project.pbxproj" -exec sed  -i '' -l "s/\([\.\"\* ^a-z^A-Z]\)$file_name\([\.\"\* ]*\)/\1$new_file_name\2/g" {} ";" 
#    
#    if $file_name && $new_word; then
#      #Executed ${#all_postfix} times. REFACTOR!
#      find $project_name -type f -exec sed  -i '' -l "s/\([\.\"\* ]\)$file_name\([\.\"\* ]\)/\1$new_word\2/g" {} ";"
#      find $project_name.xcodeproj -type f -exec sed  -i '' -l "s/\([\.\"\* ]\)$file_name\([\.\"\* ]\)/\1$new_word\2/g" {} ";"
#    fi
  done
done