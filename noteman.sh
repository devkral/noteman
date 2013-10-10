#/usr/bin/env bash
#LICENCE: gpl3

#dependencies: bash, sane, imagemagick, ffmpeg v4l-utils


###variables###

note_folder=~/Notes
default_cam=/dev/video0

#scanimage -L 
default_scan="" #<scanner name>

default_audio_type=ogg
default_picture_type=jpg
default_container_type=webm

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
  local tmp_filepath="$(filetype_override "$note_folder/$1/$2" "$default_container_type")"
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
  echo "delnote <name>: delete note"
  echo "del <notename> <name>: delete note item"
  echo "open <notename> <name>: open note item"
  echo "list [notename]: list note items or notes"
  echo "remind [ <notename> <date compatible string> ]: add reminder to note/look reminders"
  echo "add <notename> <name> <program> <append>: add note item Deprecate?"
  echo "screenshot|screens <notename> <name> <delay>: Shoots a screenshot"
#  echo "guishot <notename> <name> [delay]: Shoots a screenshot of the monitor"
  #echo "cmdshot <notename> <name> [delay]: Shoots a screenshot of commandline"
  echo "camshot <notename> <name> [delay]: Shoots a picture with the default webcam"
  echo "camshotvlc <notename <name>: Shoots a picture with vlc preview"
  echo "camrec <notename> <name>: Record (video+audio) with the default webcam"
  echo "audiorec <notename> <name>: Record only audio"
  echo "scan <notename> <name>: Scan"
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


#$1 filepath, $2 original file path (without suffix)
file_exist_reserved_check()
{
  is_not_nom_reserved "$1" "$2"
  status="$?"
  if [ "$status" = "1" ] ; then
    exit 1
  elif [ "$status" != "0" ] ; then
    echo "Error: note ($(basename "$2")) doesn't exist" >&2
    exit 1
  fi
  if [ -e "$1" ]; then
    echo "File name exists already. Overwrite?"
    local question_an
    read question_an
    if ! echo "$question_an" | grep -q "y"; then 
      exit 0
    fi
  fi
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
#$1 notename, $2 date compatible string
note_reminder()
{
  if [ "$#" = "0" ]; then
    nom_housekeeping   
  else
    if [ -d "$note_folder/$1" ]; then
      local temp_time="$(date --date="$2" +%s)"
      echo "$temp_time" > "$note_folder/$1/$timestamp_name"
      date --date="@$temp_time"
    else
      echo "Error: invalid note" >&2
    fi
  fi
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
  if [ ! -e "$note_folder/$1" ]; then
    if [ "$1" = "$trash_name" ]; then
      echo "Trash (notes) already purged"
      return 0
    else
      echo "Error: Note not found" >&2
      return 1
    fi
    
  fi
  if [ "$1" = "$trash_name" ]; then
    echo "Purge trash bin for notes"
    rm -r "$note_folder/$trash_name"
  else
    if [ -e "$note_folder/$trash_name" ]; then
      rm -r "$note_folder/$trash_name"
    fi
    mkdir "$note_folder/$trash_name"
    mv "$note_folder/$1" "$note_folder/$trash_name"
  fi
}

#$1 notename
list_note_items()
{
  if [ "$1" = "" ]; then
    echo "notename empty" >&2
    return 1
  fi
  nidcount=0
  for tmp_file_n in $(ls "$note_folder/$1")
  do
    ((nidcount+=1))
    if [ "$tmp_file_n" != "$trash_name" ]; then
      echo "id $nidcount: $tmp_file_n"
    else
      echo "id $nidcount (trash): $(ls "$note_folder/$1/$trash_name" | tr "\n" " ")"
    fi
  done
}

list_notes()
{
  nidcount=0
  for tmp_file_n in $(ls "$note_folder")
  do
    ((nidcount+=1))
    if [ "$tmp_file_n" != "$trash_name" ]; then
      echo "$tmp_file_n"
    else
      echo "(trash) $(ls "$note_folder/$trash_name" | tr "\n" " ")"
    fi
    #echo "id $nidcount: $tmp_file_n"
  done
}

#$1 notename, $2 (optional) item name or id, $3 (optional) program
# default: open text
open_note_item()
{ 
  if [ "$1" = "" ]; then
    echo "notename empty" >&2
    return 1
  fi
  nom_housekeeping
  nom_housekeeping_note "$1"
  status=$?
  if [ "$status" != "0" ]; then
   return $status
  fi
  if [ "$2" = "" ]; then
    nom_open "$note_folder/$1/$text_name"
    return 0
  fi
  	
  if [[ "$2" != *[!0-9]* ]]; then
    nidcount=0
    for tmp_file_n in $(ls "$note_folder/$1")
    do
      ((nidcount+=1))
      if [ "$nidcount" = "$2" ]; then
        nom_open "$note_folder/$1/$tmp_file_n" "$3" "$4"
        return 0
      fi
    done
    if [ -e "$note_folder/$1/$2" ]; then
      echo "the item needs a non numeral. Try to fix it…"
      mv "$note_folder/$1/$2" "$note_folder/$1/_$2"
      echo "Finished"
    else
      echo "ID ($2) not found"
    fi
    return 1
  fi
  if [ -f "$note_folder/$1/$2" ]; then
    nom_open "$note_folder/$1/$2"
    return 0
  else
    for tmp_file_n in $(ls "$note_folder/$1")
    do
      ((nidcount+=1))
      if echo "$tmp_file_n" | grep -q "$2"; then
        nom_open "$note_folder/$1/$tmp_file_n" "$3" "$4"
        return 0
      fi
    done
  
    echo "File ($2) not found"
    return 1
  fi  
}




#deprecate?
#$1 notename, $2 item name (id not allowed), $3 program,$4 for program after filepath
add_note_item()
{
  file_exist_reserved_check "$note_folder/$1/$2"
  nom_open "$note_folder/$1/$2" "$3" "$4"
}


#$1 notename, $2 item name or id
delete_note_item()
{
  if [ "$1" = "" ]; then
    echo "notename empty" >&2
    return 1
  fi
  if [ "$2" = "" ]; then
    echo "item identifier empty" >&2
    return 1
  fi
  if [ "$2" = "$trash_name" ]; then
    if [ -e "$note_folder/$1/$trash_name" ]; then 
      echo "Purge trash bin for note items…"
      rm -r "$note_folder/$1/$trash_name"
    else
      echo "Trash (note items) already purged"
    fi
    return 0
  fi
  	
  if [[ "$2" != *[!0-9]* ]]; then
    nidcount=0
    for tmp_file_n in $(ls "$note_folder/$1")
    do
      ((nidcount+=1))
      if [ "$nidcount" = "$2" ]; then
        [ -e "$note_folder/$1/$trash_name" ] && rm -r "$note_folder/$1/$trash_name"
        if [ "$tmp_file_n" = "$trash_name" ]; then
          echo "Purged trash bin for note items"
        else
          [ -e "$note_folder/$1/$trash_name" ] && rm -r "$note_folder/$1/$trash_name"
          mkdir "$note_folder/$1/$trash_name"
          mv "$note_folder/$1/$tmp_file_n" "$note_folder/$1/$trash_name"
        fi
        return 0
      fi
    done  
    echo "ID ($2) not found"
    return 1
  fi
  if [ -f "$note_folder/$1/$2" ]; then
    [ -e "$note_folder/$1/$trash_name" ] && rm -r "$note_folder/$1/$trash_name"
    [ -e "$note_folder/$1/$trash_name" ] && rm -r "$note_folder/$1/$trash_name"
    mkdir "$note_folder/$1/$trash_name"
    mv "$note_folder/$1/$2" "$note_folder/$1/$trash_name"
    return 0
  else
    echo "File ($2) not found"
    local collect_string=""
    for tmp_file_n in $(ls "$note_folder/$1")
    do
      ((nidcount+=1))
      if echo "$tmp_file_n" | grep -q "$2"; then
        collect_string="$collect_string\n$tmp_file_n"
      fi
    done
    if [ "$collect_string" != "" ]; then
      if [[ "$(echo -e "$collect_string" | wc -l)" -le "1" ]]; then
        echo -e "Do you meant: $(echo $collect_string | sed -e 's/^\\n//')?"
      else
        echo -e "Corrections:$collect_string"
      fi
      
    fi
    return 1
  fi  
}


#main

if [ ! -e "$note_folder" ]; then
  mkdir "$note_folder"
fi

#rm -r "$tmp_folder"
#mkdir -m700 "$tmp_folder"


sel_option="$1"
shift

case "$sel_option" in
  "addnote")add_note $@;;
  "delnote")del_note $@;;
  "remind")note_reminder $@;;
  "add")add_note_item $@;;
  "screenshot"|"screens")nom_screenshot $@;;
 # "guishot") nom_screenshot $@;;
 # "cmdshot") nom_screenshot_cmd $@;;
  "camshot") nom_camshot $@;;
  "camshotvlc") nom_camshot_vlc_preview $@;;
  "camrec") nom_camrec $@;;
  "audiorec") nom_audiorec $@;;
  "scan") nom_scan_single $@;;
  "del")delete_note_item $@;;
  "open")open_note_item $@;;
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

exit 0
