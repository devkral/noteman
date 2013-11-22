#/usr/bin/env bash
#LICENCE: gpl3

#dependencies: bash, sane, imagemagick, ffmpeg v4l-utils, (vlc),(vimdiff)


###variables###

note_folder=~/Notes
remote_ssh=
remote_noteman="noteman"
default_diffprogram=vimdiff

default_cam=/dev/video0

#scanimage -L 
default_scan="" #<scanner name>


default_picture_type=jpg
default_video_type=webm
default_audio_type=ogg
default_text_type=txt
#should not contain . but is replaced anyway
default_save="$(date +%F_%T)"

tmp_folder=/tmp/$UID-noteman

#env variables
#NOM_NOTE_FOLDER
#NOM_DEFAULT_CAM
#NOM_DEFAULT_SCAN
#NOM_REMOTE_SSH
#NOM_REMOTE_NOTEMAN

### commands ###

# $1 note name, $2 save name, $3 (optional) waittime to trigger in seconds
nom_screenshot_imagemagick()
{
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "$default_picture_type")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi

  if [ "$3" != "" ]; then
    sleep "$3"
  fi
  import -window root "$tmp_filepath"
}

# $1 note name, $2 save name, $3 (optional) waittime to trigger in seconds
nom_screenshot_ffmpeg() 
{
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "$default_picture_type")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi

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
   nom_screenshot_imagemagick "$@"
   #nom_screenshot_ffmpeg $@
#  fi
}

# $1 note name, $2 save name
nom_camshot_vlc_preview()
{
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "$default_picture_type")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi

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
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "$default_picture_type")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi
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
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "$default_video_type")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi
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
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "$default_audio_type")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi
  #if [ "$3" != "" ]; then
  #  sleep "$3"
  #fi
  echo "Enter q to stop recording"
  ffmpeg -loglevel warning -f alsa -i default -acodec libvorbis "$tmp_filepath"
}

# $1 note name, $2 save name
nom_audiorec_pulse()
{
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "wav" "wav")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi
  parecord -r "$tmp_filepath"&
  pulserec_pid="$!"
  echo "Press \"Enter\" to stop"
  read shall_continue
  kill -TERM "$pulserec_pid"
}

# $1 note name, $2 save name
nom_audiorec_alsa()
{
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "wav" "wav")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi
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
  local tmp_filepath="$(file_create_quest_new "$1" "$2" "tiff" "tiff")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi
  scanimage --device "$default_scan" --format tiff > "$tmp_filepath"

}



### commands-end ###

#environment replacement
if [ ! -z $NOM_NOTE_FOLDER ]; then
  note_folder="$NOM_NOTE_FOLDER"
fi
if [ ! -z $NOM_REMOTE_SSH ]; then
  remote_ssh="$NOM_REMOTE_SSH"
fi
if [ ! -z $NOM_REMOTE_NOTEMAN ]; then
  remote_noteman="$NOM_REMOTE_NOTEMAN"
fi
if [ ! -z $NOM_DEFAULT_CAM ]; then
  default_cam="$NOM_DEFAULT_CAM"  
fi
if [ ! -z $NOM_DEFAULT_SCAN ]; then
  default_scan="$NOM_DEFAULT_SCAN"  
fi
#EDITOR

#intern variable names, please don't change
default_name=default
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
  echo "open <notename> <name/default>: open note item/default note item ($text_name)"
  echo "list [notename]: list note items or notes"
  echo "remind [notename] [date compatible string]: 0 arguments: get reminders,"
  echo "    1 argument: get reminder of note, 2 arguments: add reminder to note"
  echo "    date string example: \"2013-2-2 23:33:11\" here: \"\" important!"
  echo "remindtest: test date strings"
  echo "move <notename start> <notename end> <note item name>: move note item"
  echo "restore [note]: restore note/note item"
  echo "screenshot|screens <notename> <name/default> <delay>: Shoots a screenshot"
#  echo "guishot <notename> <name/default> [delay]: Shoots a screenshot of the monitor"
  #echo "cmdshot <notename> <name/default> [delay]: Shoots a screenshot of commandline"
  echo "camshot <notename> <name/default> [delay]: Shoots a picture with the default webcam"
  echo "camshotvlc <notename <name/default>: Shoots a picture with vlc preview"
  echo "camrec <notename> <name/default>: Record (video+audio) with the default webcam"
  echo "audiorec <notename> <name/default>: Record only audio"
  echo "scan <notename> <name/default>: Scan"
  echo "add <notename> <name/default> [<program> <append>]: add note item (text/by program)"
  echo "pick <file> <notename> [noteitem]: copy file into notefolder"
  echo "remote_pick|rpick <file> <notename> [noteitem|""] [n]: copy file into notefolder on remote pc,n: don't ask if file should be deleted"
  echo "synch  <notename> <noteitem>: transfer noteitem on other pc"
  echo "remote: execute command on default remote pc"
  echo "[...] optional"
  echo "delay is in seconds"
  echo "default: open default/ save to a generated name (e.g. date)"
  #echo "Press q to stop recording"


}


#$1 localfilepath, $2 notename or id, $3 (optional) item name or id or "", $4 (optional) n for removing delete dialog
remote_transfer_send()
{
  if [ -z $remote_ssh ]; then
    echo "Error: remote_ssh has not been set" >&2
    return 1
  elif [ -z $remote_noteman ]; then
    echo "Error: remote_noteman has not been set" >&2
    return 1
  fi

  if [ "$3" = "" ]; then
    b_name="$(basename "$1")"
  else
    b_name="$3"
  fi
  #RANDOM="$(date +%s)"
  #NOM_sensitive="$tmp_folder/nomsend$RANDOM"
  if ! ps -C "ssh-agent" &> /dev/null ; then
    ssh-agent 2> /dev/null #-a "$NOM_sensitive"
  fi
  #SSH_AUTH_SOCK="$NOM_sensitive" 
  ssh-add -t 40
  rem_tmp_filepath="$(ssh $remote_ssh "$remote_noteman remote_file_receive \"$2\" \"$b_name\"")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi  
  #SSH_AUTH_SOCK="$NOM_sensitive"
  scp "$1" "$remote_ssh:$rem_tmp_filepath"
  status=$?
  #SSH_AUTH_SOCK="$NOM_sensitive" 
  #ssh-add -D
  #ssh-agent -k -a "$NOM_sensitive"
  if [ "$4" != "n" ] && [ "$status" = "0" ]; then
    echo "Shall the file be purged?" >&2
    local question_an
    read question_an
    if echo "$question_an" | grep -q "y"; then 
      rm "$1"
    fi
  fi
}

#$1 notename or id, $2 item name
remote_transfer_receive()
{
  tmp_filepath="$(file_create_quest_new "$1" "$2")"
  status=$?
  if [ "$status" = "2" ]; then
    exit 0
  elif [ "$status" != "0" ]; then
    exit 1
  elif [ "$tmp_filepath" = "" ]; then
    echo "Fatal Error: filepath empty and not status!=0, status $status" >&2
    exit 1
  fi
  #mv "$tmpfolder_bad/baddidea" "$tmp_filepath"
  exit 0

#  echo ""tar -cf - source_dir | 
#ssh user@desktop 'cat > dest.tar'
}

#$@ execute commands remote
remote_command()
{
  ssh "$remote_ssh" "$remote_noteman $@"
}

#$1 note, $2 (optional) y note creation menu, returns 0 on success and echos decoded note
note_exist_echo()
{
  decoded_notename="$(get_by_ni "$note_folder" "$1")"
  status="$?"
  if [ "$status" = "1" ] && [ "$2" = "y" ]; then
    echo "Note doesn't exist. Shall a note named \"$decoded_notename\" be created?" >&2
    local question_an
    read question_an
    if ! echo "$question_an" | grep -q "y"; then 
      return 2
    else
      mkdir "$note_folder/$decoded_notename"
      if [ "$?" = "0" ]; then
        return 1
      fi
    fi
  elif [ "$status" = "1" ]; then
    echo "Error: note \"$decoded_notename\" not found" >&2
    return 1
  elif  [ ! -e "$note_folder/$decoded_notename" ] && [ ! -e "$note_folder/$trash_name/$decoded_notename" ]; then
    echo "Error: \"$decoded_notename\" isn't a note" >&2
    return 1
  elif  [ ! -d "$note_folder/$decoded_notename" ] && [ ! -d "$note_folder/$trash_name/$decoded_notename" ]; then
    echo "Error: \"$decoded_notename\" isn't a directory" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi
  echo "$decoded_notename"
  return 0
}


#$1 basename  returns 0 if an allowed name, not 0, hint for the rename logic to rename the item
name_reserved_rename_check()
{
  if [[ $1 != *[!0-9]* ]] || [ "$1" = "$default_name" ]; then #only digits conflict with id 
    echo "$1 is not an allowed name" >&2
    return 1
  fi
  return 0
}

#$1 basename 
name_reserved_check()
{
  if [[ $1 != *[!0-9]* ]]; then #only digits conflict with id 
    echo "Error: Name must contain a non-digit: $n_base_name" >&2
    return 1
  fi
  
  if [ "$1" = "$trash_name" ] || [ "$1" = "$text_name" ] ||
    [ "$1" = "$timestamp_name" ] || [ "$1" = "$default_name" ]; then
    echo "Error: Use of reserved name: $1" >&2
    return 1
  fi
}

#$1 note, $2 (optional) noteitem, returns 0 if not exist, 1 if error, 2 if exists
nonoi_create_check()
{
  if [ "$#" = "1" ]; then
    if ! name_reserved_check "$1"; then
      return 1
    fi
    if [ -e "$note_folder/$1" ]; then
      return 2
    else
      return 0
    fi
  elif [ "$#" = "2" ]; then
    decoded_notename="$(note_exist_echo "$1")"
    status=$?
    if [ "$status" != "0" ]; then
      return 1
    fi

    if ! name_reserved_check "$2"; then
      return 1
    fi
    if [ -e "$note_folder/$decoded_notename/$2" ]; then
      return 2
    else 
      return 0
    fi
  fi
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
  if [ "$1" = "" ]; then
    echo "Error: folder empty" >&2
    return 2
  elif [ "$2" = "" ]; then
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

# $1 decoded note, $2 decoded noteitem
give_corrections()
{
  ! create_noteitem_test "$1" "$2" && return 1
  local collect_string=""
  for tmp_file_n in $(ls "$note_folder/$1")
  do
    if echo "$tmp_file_n" | grep -q "$2"; then
      collect_string="$collect_string\n$tmp_file_n"
    fi
  done
  collect_string="$(echo $collect_string | sed -e 's/^\\n//')"
  if [ "$collect_string" != "" ]; then
    if [ "$(echo -e "$collect_string" | wc -l)" = "1" ]; then
      echo "$collect_string"
      return 0
    else
      echo -e "Corrections:\n$collect_string" >&2
      return 1
    fi
  else
    echo "Error: noteitem ($2) not found" >&2
    return 1
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


# $1 filename, $2 default file-type suffix, $@ (optional) allowed file endings
file_ending()
{
  local tmp_file="$1"
  shift 1
  local default_filetype="$1"
  shift 1
  
  if [ "$tmp_file" = "" ]; then
    echo "Error: filename empty" >&2
    return 1
  fi
  if [ "$default_filetype" = "" ]; then
    echo "Error: default file-type suffix empty" >&2
    return 1
  fi

  local tmp_file_type="$(basename "$tmp_file" | sed "s/^.*\.//")"
  local tmp_file_basename="$(basename "$tmp_file")"
  #local tmp_file_path_name="$(dirname "$tmp_file_path")/$(basename "$tmp_file_path" | sed "s/\..*$//")"

  local is_an_allowed_filetype="false"
  if ! echo "$tmp_file" | grep -q "\."; then
    echo "$tmp_file.$default_filetype"
    return 0
  elif [ "$default_filetype" = "$tmp_file_type" ]; then
    echo "$tmp_file"
    return 0
  elif [ "$#" != "0" ] && [ "$tmp_file_type" = "" ]; then
    for cur_file_type in $@
    do
      if [ "$tmp_file_type" = "$cur_file_type" ]; then
        is_an_allowed_filetype="true"
        break
      fi
    done
  elif [ "$#" = "0" ]; then
    is_an_allowed_filetype="true"
  fi
  if [ "$is_an_allowed_filetype" = "true" ]; then
    echo "Override filetype?" >&2
    echo "y[es] for using the own file-type suffix" >&2
    echo "r for replacing the file-type suffix by the default" >&2
    echo "n for appending the default  file-type suffix" >&2
    local question_an
    read question_an
    if echo "$question_an" | grep -q "y"; then 
      echo "$tmp_file"
    elif echo "$question_an" | grep -q "r"; then 
      echo "$tmp_file_basename.$default_filetype"
    else
      echo "$tmp_file.$default_filetype"
    fi
  else
    echo "Fix filetype:" >&2
    echo "r for replacing the wrong file-type suffix" >&2
    echo "n for appending the right file-type suffix" >&2
    local question_an
    read question_an
    if echo "$question_an" | grep -q "r"; then 
      echo "$tmp_file_basename.$default_filetype"
    else
      echo "$tmp_file.$default_filetype"
    fi
  fi
}



# $1 note, $2 (optional) noteitem, $3 (optional) default filending, $@ (optional) allowed types  echos path
#Warning: quote note and note item elsewise check if empty will fail
file_create_quest_new()
{
  if [ "$#" = "0" ]; then
    echo "Error: note empty" >&2
    return 1
  elif [ "$#" = "1" ]; then
    nonoi_create_check "$1"
    status=$?
    if [ "$status" = "2" ]; then
      return 2
#don't offer such a dangerous option
      #echo "File name exists already. Overwrite?" >&2
      #local question_an
      #read question_an
      #if ! echo "$question_an" | grep -q "y"; then 
      #  return 2
      #else
      #  rm -r "$note_folder/$1" 
      #  echo "$note_folder/$1"
      #fi    
    elif [ "$status" != "0" ]; then
      return 1
    else
      echo "$note_folder/$1"
      return 0
    fi

  else
    ! create_noteitem_test "$1" "$2" && return 1
    decoded_notename="$(note_exist_echo "$1" y)"
    status=$?
#todo: note creation menu
    if [ "$status" != "0" ]; then
      return 1
    fi
    shift 1
    tmp_noteitemname="$1"
    
    shift 1
    if [ "$tmp_noteitemname" = "$default_name" ]; then
      decoded2_name="$(file_ending "$(echo "$default_save" | sed "s/\./,/g")" "$@")"
    elif [ "$1" != "" ]; then
      decoded2_name="$(file_ending "$tmp_noteitemname" "$@")"
    else
      decoded2_name="$tmp_noteitemname"
    fi
    nonoi_create_check "$decoded_notename" "$decoded2_name" 
    status=$?
    if [ "$status" = "2" ]; then
      echo "File name exists already. Overwrite?" >&2
      local question_an
      read question_an
      if ! echo "$question_an" | grep -q "y"; then 
        return 2
      else
        rm -r "$note_folder/$decoded_notename/$decoded2_name"
        echo "$note_folder/$decoded_notename/$decoded2_name"
      fi
    elif [ "$status" != "0" ]; then
      return 1
    else
      echo "$note_folder/$decoded_notename/$decoded2_name"
      return 0
    fi
  fi
  return 1
}

#$1 note, $2 note item
create_noteitem_test()
{
  if [ "$#" = "0" ] || [ "$1" = "" ]; then
    echo "Error: note name/id empty" >&2
    return 1
  elif [ "$#" = "1" ] || [ "$2" = "" ]; then
    echo "Error: note item name/id empty" >&2
    return 1
  fi
  return 0
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

    if [ ! -e "$note_folder/$tmp_file_n/$text_name" ] && [ "$tmp_file_n" != "$trash_name" ]; then
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
      echo -e "\033[36;1mNote has reminder[Now: $(date)]:\n\033[31;1m$(date --date="@$(cat "$note_folder/$decoded_notename/$timestamp_name")")\033[0m"
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
    if ! name_reserved_rename_check "$tmp_file_n"; then
      local tmp_file_n_new="$tmp_file_n"
      while [ -e "$note_folder/$tmp_file_n_new" ];
      do
        tmp_file_n_new="_$tmp_file_n_new"        
      done
      mv "$note_folder/$tmp_file_n" "$note_folder/$tmp_file_n_new"
      echo "Debug: Renamed \"$tmp_file_n\" to \"$tmp_file_n_new\"" >&2
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
    echo "Error: Note item name \"$decoded_name\" not found" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi
  
  if [ "$decoded_name" != "$text_name" ]; then
    decoded_path="$(file_create_quest_new "$decoded_notename" "$decoded_name")"
    status=$?
    if [ "$status" = "2" ]; then
      return 0
    elif [ "$status" != "0" ]; then
      return 1
    fi
    mv "$note_folder/$decoded_notenamesrc/$decoded_name" "$decoded_path"
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
      decoded_path="$(file_create_quest_new "$(ls "$note_folder/$trash_name")")"
      status=$?
      if [ "$status" = "2" ] ; then
        return 0
      elif [ "$status" != "0" ] ; then
        return 1
      fi

      mv "$note_folder/$trash_name/$(ls "$note_folder/$trash_name")" "$note_folder/"
      rm -r "$note_folder/$trash_name/"
      return 0
    else
      echo "Error: trash has multiple items" >&2
      return 1
    fi
  else
    decoded_notename="$(get_by_ni "$note_folder" "$1")"
    status=$?
    if [ "$status" = "1" ]; then
      echo "Error: Note doesn't exist" >&2
      return 1
    elif [ "$status" != "0" ]; then
      return 1
    fi
    if [ ! -d "$note_folder/$decoded_notename/$trash_name" ] ||  [ "$(ls "$note_folder/$decoded_notename/$trash_name" | wc -l)" = "0" ]; then
      echo "Note item trash is empty"
      return 0
    elif [ "$(ls "$note_folder/$decoded_notename/$trash_name" | wc -l)" = "1" ]; then
      decoded_path="$(file_create_quest_new "$decoded_notename" "$(ls "$note_folder/$decoded_notename/$trash_name")")"
      status=$?
      if [ "$status" = "2" ]; then
        return 0
      elif [ "$status" != "0" ]; then
        return 1
      fi
      mv "$note_folder/$decoded_notename/$trash_name/$(ls "$note_folder/$1/$trash_name")" "$decoded_path"
      rm -r "$note_folder/$decoded_notename/$trash_name/"
      return 0
    else
      echo "Error: trash has multiple items" >&2
      return 1
    fi
    return 1
  fi
}


#$1 notename
add_note()
{
  decoded_path="$(file_create_quest_new "$1")"
  status=$?
  if [ "$status" = "2" ] ; then
    return 0
  elif [ "$status" != "0" ] ; then
    return 1
  fi
  mkdir "$decoded_path"
  touch "$decoded_path/$text_name"
  return 0
}

#$1 notename
del_note()
{
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
  if [ "$2" = "" ] || [ "$2" = "$default_name" ]; then
    tmp_noteitem="$text_name"
  else
    tmp_noteitem="$2"
  fi

  ! create_noteitem_test "$1" "$tmp_noteitem" && return 1

  decoded_notename="$(get_by_ni "$note_folder" "$1")"
  status=$?
  if [ "$status" = "1" ]; then
    echo "Error: Note \"$decoded_notename\" not found" >&2
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

  if [ "$decoded_notename" = "$trash_name" ]; then
    tmp_notename="$trash_name/$(ls $note_folder/$trash_name | tr "\n" "/" | sed "s|/.*$||" )"
  else
    tmp_notename="$decoded_notename"
  fi


  decoded_name="$(get_by_ni "$note_folder/$tmp_notename" "$tmp_noteitem")"
  status=$?
  if [ "$status" = "0" ]; then
    if [ "$decoded_name" = "$trash_name" ]; then
      tmp_noteitemname="$trash_name/$(ls $note_folder/$tmp_notename/$trash_name | tr "\n" "/" | sed "s|/.*$||" )"
    else
      tmp_noteitemname="$decoded_name"
    fi
    nom_open "$note_folder/$tmp_notename/$tmp_noteitemname" "$3" "$4"
    return $?
  elif [ "$status" = "1" ]; then
    collect_string="$(give_corrections "$decoded_notename" "$decoded_name")"
    status2=$?
    if [ "$status2" = "0" ]; then
      nom_open "$note_folder/$decoded_notename/$collect_string" "$3" "$4"
    fi
  elif [ "$status" = "2" ]; then
    return 2
  fi
}




#$1 notename, $2 item name (id not allowed), $3 program,$4 for program after filepath
add_note_item()
{
  

  decoded_path="$(file_create_quest_new "$1" "$2" "$default_text_type")"
  status=$?
  if [ "$status" = "2" ] ; then
    return 0
  elif [ "$status" != "0" ] ; then
    return 1
  fi
  if [ "$3" = "" ]; then
    touch "$decoded_path"
  fi
  nom_open "$decoded_path" "$3" "$4"
}

#$1 notename, $2 item name or id
delete_note_item()
{
  ! create_noteitem_test "$1" "$2" && return 1
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

    echo "Note item \"$decoded_name\" not found"
    collect_string="$(give_corrections "$decoded_notename" "$decoded_name")"
    status=$?
    if [ "$status" = "0" ]; then
      echo -e "Do you meant: \"$collect_string\" ?"
    fi
    return 1
  else # status=2
    return 1
  fi
   
}

#$1 filepath, $2 notename or id, $3 noteitem
pick_file()
{
  b_name="$(basename "$1")"
  if [ "$#" = "3" ]; then
    b_name="$3"
  fi
  local tmp_filepath="$(file_create_quest_new "$2" "$b_name" "$default_picture_type")"
  status=$?
  if [ "$status" = "2" ]; then
    return 2
  elif [ "$status" != "0" ]; then
    return 1
  fi
  cp "$1" "$tmp_filepath"
  echo "Shall $1 be eradicated?" >&2
  local question_an
  read question_an
  if echo "$question_an" | grep -q "y"; then 
    rm "$1"
  fi    
}

#source: $1 notename or id, $2 noteitemname or id, $3 (optional) remote
synchronize()
{

  ! create_noteitem_test "$1" "$2" && return 1

  decoded_notename="$(get_by_ni "$note_folder" "$1")"
  status=$?
  if [ "$status" = "1" ]; then
    echo "Error: Note \"$decoded_notename\" not found" >&2
    return 1
  elif  [ ! -d "$note_folder/$decoded_notename" ]; then
    echo "Error: \"$decoded_notename\" isn't a directory" >&2
    return 1
  elif [ "$status" != "0" ]; then
    return 1
  fi


  decoded_name="$(get_by_ni "$note_folder/$decoded_notename" "$2")"
  status=$?
  if [ "$status" = "0" ]; then
    remote_transfer_send "$note_folder/$decoded_notename/$decoded_name" "$decoded_notename" "" "y"
    status2=$?
    if [ "$status2" = "2" ]; then
       #todo
      return 2
    elif [ "$status2" != "0" ]; then
#todo
      return 1
    fi
  elif [ "$status" = "1" ]; then
    echo "Error: Note \"$decoded_name\" not found" >&2
    return 1
  else
    return 1
  fi
  
}


#main

if [ ! -e "$note_folder" ]; then
  mkdir "$note_folder"
fi

[ -e "$tmp_folder" ] && rm -r "$tmp_folder"
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
  "pick")pick_file "$@";;
  "remote_pick"|"rpick")remote_transfer_send "$@";;
  "synch"|"synchronize")synchronize "$@";;
  "remote_file_receive")
temp11="$1"
temp12="$2"
shift 2
remote_transfer_receive "$temp11" "$temp12" "$*";;
  "remote") remote_command "$@";;
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
