#/usr/bin/env bash
#LICENCE: gpl3

#dependencies: bash, sane, imagemagick, ffmpeg v4l-utils, (vlc),(vimdiff)


###variables###

note_folder=~/Notes
default_diffprogram=vimdiff

default_cam=/dev/video0

#scanimage -L 
default_scan="" #<scanner name>


default_picture_type=jpg
default_video_type=webm
default_audio_type=ogg

tmp_folder=/tmp/$UID-noteman

#env variables
#NOM_NOTE_FOLDER
#NOM_DEFAULT_CAM
#NOM_DEFAULT_SCAN

### commands ###

# $1 note name, $2 save name, $3 (optional) waittime to trigger in seconds
nom_screenshot_imagemagick()
{
  local tmp_filepath="$(filetype_override "$note_folder/$1/$2" "$default_picture_type")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  if [ "$3" != "" ]; then
    sleep "$3"
  fi
  import -window root "$tmp_filepath"
}

# $1 note name, $2 save name, $3 (optional) waittime to trigger in seconds
nom_screenshot_ffmpeg() 
{
  local tmp_filepath="$(filetype_override "$note_folder/$1/$2" "$default_picture_type")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  [ -e "$tmp_filepath" ] && rm "$tmp_filepath"
  if [ "$3" != "" ]; then
    sleep "$3"
  fi
  ffmpeg -loglevel warning -f x11grab -vframes 1 "$tmp_filepath"
}

nom_screenshot()
{
#  if [ "$DISPLAY" = "" ]; then
#    
#  else
   nom_screenshot_imagemagick $@
   #nom_screenshot_ffmpeg $@
#  fi
}

# $1 note name, $2 save name
nom_camshot_vlc_preview()
{
  local tmp_filepath="$(filetype_override "$note_folder/$1/$2" "$default_picture_type")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  [ -e "$tmp_filepath" ] && rm "$tmp_filepath"
  vlc "v4l://$default_cam" > /dev/null &
  vlc_pid="$!"
  echo "Press \"Enter\" for shot"
  read shall_continue
  kill "$vlc_pid"
  ffmpeg -loglevel warning -f v4l2 -i "$default_cam" -vframes 1 "$tmp_filepath" > /dev/null
}


# $1 note name, $2 save name, $3 (optional) waittime to trigger in seconds
nom_camshot_ffmpeg() 
{
  local tmp_filepath="$(filetype_override "$note_folder/$1/$2" "$default_picture_type")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  [ -e "$tmp_filepath" ] && rm "$tmp_filepath"
  if [ "$3" != "" ]; then
    sleep "$3"
  fi
  ffmpeg -loglevel warning -f v4l2 -i "$default_cam" -vframes 1 "$tmp_filepath"
}


# $1 note name, $2 save name, $3 (optional) waittime to trigger in seconds 
nom_camshot()
{
  nom_camshot_ffmpeg $@
}

# $1 note name, $2 save name
nom_camrec_ffmpeg()
{
  local tmp_filepath="$(filetype_override "$note_folder/$1/$2" "$default_video_type")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  [ -e "$tmp_filepath" ] && rm "$tmp_filepath"
  #if [ "$3" != "" ]; then
  #  sleep "$3"
  #fi
  echo "Enter q to stop recording"
  ffmpeg -loglevel warning -f alsa -i default -f v4l2 -i /dev/video0 -acodec libvorbis -vcodec libvpx "$tmp_filepath"
}

# $1 note name, $2 save name
nom_camrec()
{
  nom_camrec_ffmpeg $@
}


# $1 note name, $2 save name
nom_audiorec_ffmpeg()
{
  local tmp_filepath="$(filetype_override "$note_folder/$1/$2" "$default_audio_type")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  [ -e "$tmp_filepath" ] && rm "$tmp_filepath"
  #if [ "$3" != "" ]; then
  #  sleep "$3"
  #fi
  echo "Enter q to stop recording"
  ffmpeg -loglevel warning -f alsa -i default -acodec libvorbis "$tmp_filepath"
}

# $1 note name, $2 save name
nom_audiorec_pulse()
{
  local tmp_filepath="$(allowed_filetypes "$note_folder/$1/$2" "wav")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  parecord -r "$tmp_filepath"&
  pulserec_pid="$!"
  echo "Press \"Enter\" to stop"
  read shall_continue
  kill -TERM "$pulserec_pid"
}

# $1 note name, $2 save name
nom_audiorec_alsa()
{
  local tmp_filepath="$(allowed_filetypes "$note_folder/$1/$2" "wav")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  arecord -r -fdat "$tmp_filepath"&
  alsarec_pid="$!"
  echo "Press \"Enter\" to stop"
  read shall_continue
  kill -TERM "$alsarec_pid"

}

# $1 note name, $2 save name
nom_audiorec()
{
  nom_audiorec_ffmpeg $@
  #nom_audiorec_pulse $@
  #nom_audiorec_alsa $@
  
}

# $1 note name, $2 save name
nom_scan_single()
{
  local tmp_filepath="$(allowed_filetypes "$note_folder/$1/$2" "tiff")"
  file_exist_reserved_check "$tmp_filepath" "$note_folder/$1/$2"
  scanimage --device "$default_scan" --format tiff > "$tmp_filepath"

}



### commands-end ###

#environment replacement
if [ ! -z $NOM_NOTE_FOLDER ]; then
  note_folder="$NOM_NOTE_FOLDER"
fi
if [ ! -z $NOM_DEFAULT_CAM ]; then
  default_cam="$NOM_DEFAULT_CAM"  
fi
if [ ! -z $NOM_DEFAULT_SCAN ]; then
  default_scan="$NOM_DEFAULT_SCAN"  
fi
#EDITOR

#intern variable names, please don't change
trash_name=trash
text_name=notetext.txt
timestamp_name=timestamp.txt
#mode=


usage()
{
  echo "$0 <action> <options…>"
  echo "Actions:"
  echo "addnote <name>: add note"
  echo "delnote <name/$trash_name>: delete note/purge note trash"
  echo "del <notename> <name/$trash_name>: delete note item/purge note item trash"
  echo "open <notename> <name>: open note item"
  echo "list [notename]: list note items or notes"
  echo "remind [notename] [date compatible string]: 0 arguments: get reminders,"
  echo "    1 argument: get reminder of note, 2 arguments: add reminder to note"
  echo "    date string example: \"2013-2-2 23:33:11\" here: \"\" important!"
  echo "remindtest: test date strings"
  echo "move <notename start> <notename end> <note item name>: move note item"
  echo "restore [note]: restore note/note item"
  echo "screenshot|screens <notename> <name> <delay>: Shoots a screenshot"
#  echo "guishot <notename> <name> [delay]: Shoots a screenshot of the monitor"
  #echo "cmdshot <notename> <name> [delay]: Shoots a screenshot of commandline"
  echo "camshot <notename> <name> [delay]: Shoots a picture with the default webcam"
  echo "camshotvlc <notename <name>: Shoots a picture with vlc preview"
  echo "camrec <notename> <name>: Record (video+audio) with the default webcam"
  echo "audiorec <notename> <name>: Record only audio"
  echo "scan <notename> <name>: Scan"
  echo "add <notename> <name> <program> <append>: add note item Deprecate?"
  echo "delay is in seconds"
  #echo "Press q to stop recording"


}

#$1 path to check return 0 if ok 
nom_path_exist_check()
{
  local n_base_name="$(basename "$1")"
  local tmp_dir_name="$(dirname "$1")"
  
  if [ "$1" = "$note_folder" ]; then
    echo "Error: given path is note folder" >&2
    return 1
  fi
  if [ "$1" = "" ]; then
    echo "Error: given path is empty" >&2
    return 1
  fi
  if echo "$1" | grep -q "//"; then
    echo "Error: No note specified" >&2
    return 1
  fi
  if [ ! -d "$tmp_dir_name" ]; then
    echo "Error: note ($(basename "$tmp_dir_name")) doesn't exist" >&2
    return 1
  fi

  if [ "$note_folder" = "$tmp_dir_name" ] && [ ! -d "$1" ]; then
    return 2
  fi
  return 0
}

#$1 path to check, $2 original file path (without suffix)  return 0 if ok 
is_not_nom_reserved()
{
  local n_base_name="$(basename "$1")"
  local tmp_dir_name="$(dirname "$1")"
  if [[ $n_base_name != *[!0-9]* ]]; then #only digits conflict with id 
    echo "Error: Name must contain a non-digit: $n_base_name" >&2
    return 1
  fi
  
  if [ "$n_base_name" = "$trash_name" ] || [ "$n_base_name" = "$text_name" ] ||
    [ "$n_base_name" = "$timestamp_name" ]; then	
    echo "Error: Use of reserved name: $n_base_name" >&2
    return 1
  fi
  
  if [ "$2" != "" ]; then
    nom_path_exist_check "$2"
  else
    nom_path_exist_check "$1"
  fi
  status=$?
  return $status
}

# $1 filepath
file_exist_quest()
{
  if [ -e "$1" ]; then
    echo "File name exists already. Overwrite?"
    local question_an
    read question_an
    if ! echo "$question_an" | grep -q "y"; then 
      exit 0
    else
      rm -r "$1"
    fi
  fi
}


#$1 filepath, $2 original file path (without suffix)
file_exist_reserved_check()
{
  is_not_nom_reserved "$1" "$2"
  status="$?"
  if [ "$status" = "1" ] ; then
    exit 1
  elif [ "$status" != "0" ]; then
    echo "Error: note ($(basename "$2")) doesn't exist" >&2
    exit 1
  fi
  file_exist_quest "$1"
}




#$1 filepath
note_exist_reserved_check()
{
  is_not_nom_reserved "$1"
  status="$?"
  if [ "$status" = "1" ] ; then
    exit 1
  elif [ "$status" != "0" ] && [ "$status" != "2" ]; then
    echo "Error: note ($(basename "$1")) doesn't exist" >&2
    exit 1
  fi
  file_exist_quest "$1"
}

#$1 folder $2 id  returns 0 exist, 1 not exist
get_name_by_id()
{
  if [ "$2" = "0" ]; then
    echo "$trash_name"
    return 0
  elif  [ "$2" = "1" ]; then
    echo "$text_name"
    return 0
  fi
  nidcount=1
  for tmp_file_n in $(ls "$1")
  do
    if [ "$tmp_file_n" != "$trash_name" ] && [ "$tmp_file_n" != "$text_name" ]; then
      ((nidcount+=1))
      if [ "$nidcount" = "$2" ]; then
        echo "$tmp_file_n"
        return 0
      fi
    fi
  done  
  echo "ID ($2) not found" >&2
  return 1
}

#$1 folder $2 name  returns 0 exist, 1 not exist
get_id_by_name()
{
  if [ "$2" = "$trash_name" ]; then
    echo "0"
    return 0
  elif  [ "$2" = "$text_name" ]; then
    echo "1"
    return 0
  fi
  nidcount=1
  for tmp_file_n in $(ls "$1")
  do
    if [ "$tmp_file_n" != "$trash_name" ] && [ "$tmp_file_n" != "$text_name" ]; then
      ((nidcount+=1))
      if [ "$tmp_file_n" = "$2" ]; then
        echo "$nidcount"
        return 0
      fi
    fi
  done
  echo "Name ($2) not found" >&2
  return 1
}

#$1 folder, $2 name/id  returns 0 exist, 1 not exist 2 id not exist/empty
get_by_ni()
{
  if [ "$2" = "" ]; then
    echo "Error: name/id empty" >&2
    return 2
  elif [[ "$2" != *[!0-9]* ]]; then
    tmp_collect_status="$(get_name_by_id "$1" "$2")"
    status="$?"
    echo "$tmp_collect_status"
    if [ "$status" != "0" ]; then 
      return 2
    elif [ -e "$1/$tmp_collect_status" ]; then
      return 0
    else
      return 1
    fi
  else
    echo "$2"
    if [ -e "$1/$2" ]; then
      return 0
    else
      return 1
    fi
  fi
}


#$1 folder
list_id_name()
{
  if [ -e "$1/$trash_name" ]; then
    echo "id 0: $trash_name"
    echo "Trash contains: $(ls "$1/$trash_name" | tr "\n" " ")"
  fi
  if  [ -e "$1/$text_name" ]; then
    echo "id 1: $text_name"
  fi
  nidcount=1
  for tmp_file_n in $(ls "$1")
  do
    if [ "$tmp_file_n" != "$trash_name" ] && [ "$tmp_file_n" != "$text_name" ]; then
      ((nidcount+=1))
      echo "id $nidcount: $tmp_file_n"
    fi
  done
  return 0
}

#$1 filepath, $2 default filetype; echos refined path, speaks to user via debug
filetype_override()
{
  if ! basename "$1" | grep -q "\."; then
    echo "$1.$2"
  elif [ "$(basename "$1" | sed "s/^.*\.//")" != "$2" ]; then
    echo "Override filetype?" >&2
    echo "y[es] for using the new file-ending" >&2
    echo "r for replacing the wrong file-ending" >&2
    echo "n for appending the right file-ending" >&2
    local question_an
    read question_an
    if echo "$question_an" | grep -q "y"; then 
      echo "$1"
    elif echo "$question_an" | grep -q "r"; then 
      echo "$(echo "$1" | sed "s/^\(.*\)\..*$/\1/").$2"
    else
      echo "$1.$2"
    fi
  else
    echo "$1"
  fi
}

#$1 filepath $2 default file type $@ allowed filetypes
allowed_filetypes()
{
  local tmp_file_path="$1"
  shift 1
  local default_filetype="$1"
  shift 1
  local tmp_file_path_type="$(basename "$tmp_file_path" | sed "s/^.*\.//")"
  #local tmp_file_path_name="$(dirname "$tmp_file_path")/$(basename "$tmp_file_path" | sed "s/\..*$//")"

  local is_an_allowed_filetype="false"
  if [ "$default_filetype" = "$tmp_file_path_type" ]; then
    is_an_allowed_filetype="true"
  elif [ "$#" != "0" ] && [ "$tmp_file_path_type" = "" ]; then
    for cur_file_type in $@
    do
      if [ "$tmp_file_path_type" = "$cur_file_type" ]; then
        is_an_allowed_filetype="true"
        break
      fi
    done
  fi
  if [ "$is_an_allowed_filetype" = "true" ]; then
    echo "$tmp_file_path"
  else
    echo "$tmp_file_path.$default_filetype"
  fi
}




#$1 path, $2 (optional) program, $3 (optional)
nom_open()
{
  if [ "$2" = "" ]; then
    if ! xdg-open "$1" && [ "$EDITOR" != "" ]; then
      "$EDITOR" "$1"
    fi
    return 0
  else
    eval "$2 \"$1\"$3"
    return 0
  fi
}

nom_housekeeping()
{
  #date +%s
  nidcount=0
  local reminder_string=""
  for tmp_file_n in $(ls "$note_folder")
  do
    if [[ "$tmp_file_n" != *[!0-9]* ]]; then
      local tmp_file_n_new="$tmp_file_n"
      while [ -e "$note_folder/$tmp_file_n_new" ];
      do
        tmp_file_n_new="_$tmp_file_n_new"        
      done
      mv "$note_folder/$tmp_file_n" "$note_folder/$tmp_file_n_new"
      tmp_file_n="$tmp_file_n_new"
    fi
    
    if [ ! -d "$note_folder/$tmp_file_n" ]; then
      mv "$note_folder/$tmp_file_n" "$tmp_folder"
      mkdir "$note_folder/$tmp_file_n"
      mv "$tmp_folder/$tmp_file_n" "$note_folder/$tmp_file_n"      
    fi

    if [ ! -e "$note_folder/$tmp_file_n/$text_name" ]; then
      touch "$note_folder/$tmp_file_n/$text_name"
    fi
    if [ "$tmp_file_n" != "$trash_name" ] && [ -e "$note_folder/$tmp_file_n/$timestamp_name" ] &&
      [[  "$(cat "$note_folder/$tmp_file_n/$timestamp_name")" -le "$(date +%s)"  ]]; then
      reminder_string="$reminder_string\n  $tmp_file_n: $(date --date="@$(cat "$note_folder/$tmp_file_n/$timestamp_name")")"
    fi
  done
  if [ "$reminder_string" != "" ]; then
    echo -e "\033[36;1mRemind [Now: $(date)]:\n\033[31;1m$(echo $reminder_string | sed -e 's/^\\n//')\033[0m\n" 
  fi
}

# -  get reminders
#$1 date compatible string (for tests)
#$1 notename, $2 date compatible string
note_reminder()
{
  if [ "$#" = "0" ]; then
    nom_housekeeping
    return 0
  elif [ "$#" = "2" ]; then
    decoded_notename="$(get_by_ni "$note_folder" "$1")"
    status=$?
    if [ "$status" = "1" ]; then
      echo "Error: \"$decoded_notename\" not found" >&2
      return 1
    elif  [ ! -d "$note_folder/$decoded_notename" ]; then
      echo "Error: \"$decoded_notename\" isn't a directory" >&2
      return 1
    elif [ "$status" != "0" ]; then
      return 1
    fi
    
    if [ -d "$note_folder/$decoded_notename" ]; then
      local temp_time="$(date --date="$2" +%s)"
      echo "$temp_time" > "$note_folder/$decoded_notename/$timestamp_name"
      date --date="@$temp_time"
    else
      echo "Error: invalid note" >&2
    fi
    return 0
  elif [ "$#" = "1" ]; then
    decoded_notename="$(get_by_ni "$note_folder" "$1")"
    status=$?
    if [ "$status" = "1" ]; then
      echo "Error: \"$decoded_notename\" not found" >&2
      return 1
    elif  [ ! -d "$note_folder/$decoded_notename" ]; then
      echo "Error: \"$decoded_notename\" isn't a directory" >&2
      return 1
    elif [ "$status" != "0" ]; then
      return 1
    fi
    if [ -f "$note_folder/$decoded_notename/$timestamp_name" ]; then
      echo "$(date --date="@$(cat "$note_folder/$decoded_notename/$timestamp_name")")"
    else
      echo "Note has no reminder"
    fi
    return 0
  fi
  return 1
}

remindtest()
{
  echo "Test date mode. Nothing will be saved. Don't forget \"\"!"
  echo "Normal: $(date --date="$1")"
  echo "ISO-8601: $(date --iso-8601 --date="$1")"
  echo "RFC-2822: $(date --rfc-2822 --date="$1")"
  echo "RFC-3339 ?:"
  #echo "$(date --rfc-3339 --date="$1" 2>&1)"
  echo ""
  local temp_time="$(date --date="$1" +%s)"
  echo "$temp_time -> $(date --date="@$temp_time")"
}


# $1 note
nom_housekeeping_note()
{
  if [ "$1" = "" ] || [ ! -e "$note_folder/$1" ]; then
    echo "Error: Note doesn't exist" >&2
    return 1
  fi
  for tmp_file_n in $(ls "$note_folder/$1")
  do
    if [[ "$tmp_file_n" != *[!0-9]* ]]; then
      local tmp_file_n_new="$tmp_file_n"
      while [ -e "$note_folder/$tmp_file_n_new" ];
      do
        tmp_file_n_new="_$tmp_file_n_new"        
      done
      mv "$note_folder/$tmp_file_n" "$note_folder/$tmp_file_n_new"
    fi
  done
}

#$1 notename start, $2 notename end, $3 note item
move_note_item()
{
  if [ "$#" -lt "3" ]; then
    echo "Error: too few parameters" >&2
    return 1
  fi

  decoded_notenamesrc="$(get_by_ni "$note_folder" "$1")"
  status=$?
  if [ "$status" = "1" ]; then
    echo "Error: Note name ($decoded_notenamesrc) not found" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi
  decoded_notenamedest="$(get_by_ni "$note_folder" "$2")"
  status=$?
  if [ "$status" = "1" ]; then
    echo "Error: Note name ($decoded_notenamedest) not found" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi
  decoded_name="$(get_by_ni "$note_folder/$decoded_notenamesrc" "$3")"
  status=$?
  if [ "$decoded_name" = "$trash_name" ]; then
    echo "Error: can't move trash" >&2
    return 1
  elif [ "$status" = "1" ]; then
    echo "Error: Note item name ($decoded_name) not found" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi


#  nom_path_exist_check "$note_folder/$2/$3"
#  if [ "$?" != "0" ]; then
#    exit 1
#  fi
  
  if [ "$decoded_name" != "$text_name" ]; then
    file_exist_quest "$note_folder/$decoded_notenamedest/$decoded_name"
    mv "$note_folder/$decoded_notenamesrc/$decoded_name" "$note_folder/$decoded_notenamedest"
  else
    $default_diffprogram "$note_folder/$decoded_notenamedest/$text_name" "$note_folder/$decoded_notenamesrc/$text_name"
  fi
  return 0
}

#$1 (optional) notename
restore_trash()
{
  if [ "$1" = "" ]; then
    if [ ! -d "$note_folder/$trash_name" ] ||  [ "$(ls "$note_folder/$trash_name" | wc -l)" = "0" ]; then
      echo "Note trash is empty"
      return 0 
    elif [ "$(ls "$note_folder/$trash_name" | wc -l)" = "1" ]; then
      note_exist_reserved_check "$note_folder/$(ls "$note_folder/$trash_name")"
      mv "$note_folder/$trash_name/$(ls "$note_folder/$trash_name")" "$note_folder/"
      rm -r "$note_folder/$trash_name/"
      return 0
    else
      echo "Error: trash has multiple items" >&2
      return 1
    fi
  fi
  if [ -d "$note_folder/$1" ]; then
    if [ ! -d "$note_folder/$1/$trash_name" ] ||  [ "$(ls "$note_folder/$1/$trash_name" | wc -l)" = "0" ]; then
      echo "Note item trash is empty"
      return 0
    elif [ "$(ls "$note_folder/$1/$trash_name" | wc -l)" = "1" ]; then
      note_exist_reserved_check "$note_folder/$1/$(ls "$note_folder/$1/$trash_name")"
      mv "$note_folder/$1/$trash_name/$(ls "$note_folder/$1/$trash_name")" "$note_folder/$1/"
      rm -r "$note_folder/$1/$trash_name/"
      return 0
    else
      echo "Error: trash has multiple items" >&2
      return 1
    fi
  else
    echo "Error: Note doesn't exist" >&2
  fi
}


#$1 notename
add_note()
{
  if [ "$1" = "" ]; then
    echo "Error: tried to add empty note" >&2
    return 1
  fi
  is_not_nom_reserved "$note_folder/$1"
  status=$?
  if [ "$?" = 1 ] ; then
    return 1
  fi
  if [ -e "$note_folder/$1" ]; then
    echo "Error: note already exists" >&2
    return 1
  fi

  mkdir "$note_folder/$1"
  touch "$note_folder/$1/$text_name"
  return 0
}

#$1 notename
del_note()
{
  if [ "$1" = "" ]; then
    echo "Error: tried to delete empty note" >&2
    return
  fi
  decoded_notename="$(get_by_ni "$note_folder" "$1")"
  status=$?
  if [ "$status" = "1" ]; then
    if [ "$decoded_notename" = "$trash_name" ]; then
      echo "Trash (notes) already purged"
      return 0
    else
      echo "Error: Note name ($decoded_notename) not found" >&2
      return 1
    fi
  elif [ "$status" != "0" ]; then
    return 1
  fi
  if [ "$decoded_notename" = "$trash_name" ]; then
    echo "Purge trash bin for notes"
    rm -r "$note_folder/$trash_name"
  else
    if [ -e "$note_folder/$trash_name" ]; then
      rm -r "$note_folder/$trash_name"
    fi
    mkdir "$note_folder/$trash_name"
    mv "$note_folder/$decoded_notename" "$note_folder/$trash_name"
  fi
}

#$1 notename
list_note_items()
{
  decoded_notename="$(get_by_ni "$note_folder" "$1")"
  status=$?
  if [ "$status" = "1" ]; then
    echo "Error: \"$decoded_notename\" not found" >&2
    return 1
  elif  [ ! -d "$note_folder/$decoded_notename" ]; then
    echo "Error: \"$decoded_notename\" isn't a directory" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi
  list_id_name "$note_folder/$decoded_notename"
}

list_notes()
{
  list_id_name "$note_folder"
}

#$1 notename, $2 (optional) item name or id, $3 (optional) program
# default: open text
open_note_item()
{ 
  if [ "$1" = "" ]; then
    echo "Error: notename empty" >&2
    return 1
  fi
  decoded_notename="$(get_by_ni "$note_folder" "$1")"
  status=$?
  if [ "$status" = "1" ]; then
    echo "Error: \"$decoded_notename\" not found" >&2
    return 1
  elif  [ ! -d "$note_folder/$decoded_notename" ]; then
    echo "Error: \"$decoded_notename\" isn't a directory" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi


  nom_housekeeping
  nom_housekeeping_note "$decoded_notename"
  status=$?
  if [ "$status" != "0" ]; then
   return $status
  fi
  if [ "$2" = "" ]; then
    nom_open "$note_folder/$decoded_notename/$text_name"
    return 0
  fi
  decoded_name="$(get_by_ni "$note_folder/$decoded_notename" "$2")"
  status=$?
  if [ "$status" = "0" ]; then
    if [ "$decoded_notename" = "$trash_name" ]; then
      tmp_notename="$trash_name/$(ls $note_folder/$trash_name | tr "\n" "/" | sed "s|/.*$||" )"
    else
      tmp_notename="$decoded_notename"
    fi

    if [ "$decoded_name" = "$trash_name" ]; then
      tmp_noteitemname="$trash_name/$(ls $note_folder/$tmp_notename/$trash_name | tr "\n" "/" | sed "s|/.*$||" )"
    else
      tmp_noteitemname="$decoded_name"
    fi
    nom_open "$note_folder/$tmp_notename/$tmp_noteitemname" "$3" "$4"
    return $?
  elif [ "$status" = "1" ]; then
    for tmp_file_n in $(ls "$note_folder/$decoded_notename")
    do
      if echo "$tmp_file_n" | grep -q "$decoded_name"; then
        nom_open "$note_folder/$decoded_notename/$tmp_file_n" "$3" "$4"
        return 0
      fi
    done
    echo "File ($decoded_name) not found"
    return 1
  elif [ "$status" = "2" ]; then
    echo "ID ($2) not found"
    return 2
  fi
}




#deprecate?
#$1 notename, $2 item name (id not allowed), $3 program,$4 for program after filepath
add_note_item()
{
  file_exist_reserved_check "$note_folder/$1/$2"
  touch "$note_folder/$1/$2"
  nom_open "$note_folder/$1/$2" "$3" "$4"
}


#$1 notename, $2 item name or id
delete_note_item()
{
  decoded_notename="$(get_by_ni "$note_folder" "$1")"
  status="$?"
  if [ "$status" = "1" ]; then
    echo "Error: \"$decoded_notename\" not found" >&2
    return 1
  elif  [ ! -d "$note_folder/$decoded_notename" ]; then
    echo "Error: \"$decoded_notename\" isn't a directory" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi

  if [ "$2" = "" ]; then
    echo "item identifier empty" >&2
    return 1
  fi

  decoded_name="$(get_by_ni "$note_folder/$decoded_notename" "$2")"
  status="$?"
  if [ "$status" = "0" ]; then
    if [ "$decoded_name" = "$trash_name" ]; then
      echo "Purge trash bin for note items…"
      rm -r "$note_folder/$decoded_notename/$trash_name"
      return 0
    fi

    [ -e "$note_folder/$decoded_notename/$trash_name" ] && rm -r "$note_folder/$decoded_notename/$trash_name"
    mkdir "$note_folder/$decoded_notename/$trash_name"
    mv "$note_folder/$decoded_notename/$decoded_name" "$note_folder/$decoded_notename/$trash_name"
    return 0
  elif [ "$status" = "1" ]; then
    if [ "$decoded_name" = "$trash_name" ]; then
      echo "Trash (note items) already purged"
      return 0
    fi

    echo "File ($decoded_name) not found"
    local collect_string=""
    for tmp_file_n in $(ls "$note_folder/$decoded_notename")
    do
      if echo "$tmp_file_n" | grep -q "$decoded_name"; then
        collect_string="$collect_string\n$tmp_file_n"
      fi
    done
    if [ "$collect_string" != "" ]; then
      if [[ "$(echo -e "$collect_string" | wc -l)" = "1" ]]; then
        echo -e "Do you meant: $(echo $collect_string | sed -e 's/^\\n//')?"
      else
        echo -e "Corrections:$collect_string"
      fi      
    fi
    return 1
  else # status=2
    return 1
  fi
   
}


#main

if [ ! -e "$note_folder" ]; then
  mkdir "$note_folder"
fi

rm -r "$tmp_folder"
mkdir -m700 "$tmp_folder"


sel_option="$1"
shift

case "$sel_option" in
  "addnote")add_note "$@";;
  "delnote")del_note "$@";;
  "remind")note_reminder "$@";;
  "remindtest")remindtest "$@";;
  "move")move_note_item "$@";;
  "restore")restore_trash "$@";;
  "add")add_note_item "$@";;
  "screenshot"|"screens")nom_screenshot "$@";;
 # "guishot") nom_screenshot $@;;
 # "cmdshot") nom_screenshot_cmd "$@";;
  "camshot") nom_camshot "$@";;
  "camshotvlc") nom_camshot_vlc_preview "$@";;
  "camrec") nom_camrec "$@";;
  "audiorec") nom_audiorec "$@";;
  "scan") nom_scan_single "$@";;
  "del")delete_note_item "$@";;
  "open")open_note_item "$@";;
  "list")
  if [ "$#" = "0" ]; then
    list_notes
  else
    list_note_items "$1"
  fi ;;
  "--help" | "help"| "-h" )usage;;
  *)usage
  exit 1;;
esac
status=$?

exit $status
