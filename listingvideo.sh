#!/bin/bash

# script start time
start_script=`date +%s`

source `dirname $0`/param.conf
source `dirname $0`/regex.list

usefull_program()
{
	# if enable in 'param.conf' file, the script will test if the necessary programm are installed
	# if not, it'll install
	useful_program=(ffmpeg mysql-client-core-5.5)
	apt-get install -y ${useful_program[@]}
}

clear_name()
{
	# BETA function
	# clear the brut name of the originel file
        clearname=`echo "$1" |sed -E 's/[_.-]/\ /g' | tr '[[:upper:]]' '[[:lower:]]'` #Remplacer les majuscule par des minuscules
        clearname=`echo "$clearname" |sed -E 's/(720|720p|1080|1080p|#)//g'` #supprimer des chaines 
        clearname=`echo "$clearname" |sed -E 's/\(.*\)//g'` #supprimer le contenu des parentheses 
        clearname=`echo "$clearname" |sed "s/\ \ */\ /g"` #remplacer plusieurs espaces par un seul
}

get_secondes_duration()
{
	# convert the duration from ffmpeg return ( xx:xx:xx ) --> in secondes
	hours=`echo $1| cut -d':' -f1 |sed -E 's/^0//'`
	minutes=`echo $1| cut -d':' -f2 |sed -E 's/^0//'`
	secondes=`echo $1| cut -d':' -f3 |sed -E 's/^0//'`
	if [ -z $hours ]; then 
		secondes='0';
	else
		hours=$(( $hours * 60 * 60 ))
		minutes=$(( $minutes * 60 )) 
		secondes=$(( $secondes + $minutes + $hours )) 
	fi
}

get_info_video()
{
	# get all the informations from the return of ffmpeg command
	video_path=`dirname "$line"`
        ffmpeg_result=`ffmpeg -i "$line" 2>&1 |sed -r "s/\t//g" |tr "\n$" "\ "`
        resolution_video=`echo "$ffmpeg_result" |sed -nE "s/$regex__resolution_video/\\1/p"`
	height=`echo $resolution_video | cut -d'x' -f1`
	width=`echo $resolution_video | cut -d'x' -f2`        
	duration_video=`echo "$ffmpeg_result" |sed -nE "s/$regex__duration_video/\\1/p"`
        codec_audio=`echo "$ffmpeg_result" |sed -nE "s/$regex__codec_audio/\\1/p"`
        codec_video=`echo "$ffmpeg_result" |sed -nE "s/$regex__codec_video/\\1/p"`
        container=`echo "$video_title" |sed -nE "s/$regex__contener/\\1/p"`
        purename=`echo "$video_title" |sed -nE "s/$regex__purename/\\1/p"`
        clear_name "$purename"
	get_secondes_duration "$duration_video"	
	duration_video=$secondes
}

put_verbose_mode()
{	
	# enable if 'verbose_mode' in 'param.com' is to '1'
	# give the information to user on shell of the action of the script on a file
	if [ $verbose_mode -eq 1 ]; then 
		enable_full_path='off'
		if [ $enable_full_path == 'off' ]; then output=$video_title; else output=$line; fi
		echo "[$cpt_find] -$1- $output"
	fi
}

display_files_error()
{
	# enable if 'display_error' is enable in param.conf
	# display file error at the end of the script
	if [ "$display_error" == 'on' ]; then	
		echo; echo '################# ERREUR SUR LES FICHIERS SUIVANTS ######################'; echo
		longueur_tab=${#error_film[*]}

	if [ $longueur_tab -ne 0 ]; then
		echo "/!\ - $longueur_tab erreurs ont ete trouvees : "; echo
	else echo "AUCUNE ERREUR TROUVEE."
	fi	
	
	for ((i = 0; i < $longueur_tab; i += 1))
		do
			echo ${error_film[i]}
		done
	fi
}

# MAIN PROGRAM =========================================================

# test if the programs are installed before start the main program
if [  "$verify_usefull_program" == 'enable' ]; then usefull_program; fi;

cpt_test=0
cpt_find=0
cpt_add=0
cpt_update=0
cpt_lost=0
date_format_bdd=`date '+%Y-%m-%d %H:%M:%S'`

while read line
do
	cpt_find=$(($cpt_find + 1))
        video_title=`basename "$line"`
        weight=`ls -l "$line" |awk '{print $5}'`
        md5sum=`echo "$video_title.$weight" |md5sum |awk '{print $1}'`

	if [ "$data" == 'bdd' ]; then        
		# Recherche du md5sum dans la BDD
		md5sum_found=`mysql $bdd_name --batch -u $bdd_user -h $bdd_host -p$bdd_password -N -e \
		"SELECT md5sum FROM filmotheque WHERE md5sum='$md5sum';"`
	
		if [ -z "$md5sum_found" ]; then
			# Le hash MD5 n'a pas ete trouve dans la BDD
			# Ajout du la nouvelle video dans la BDD
			get_info_video
			mysql $bdd_name --batch -u $bdd_user -h $bdd_host -p$bdd_password -N -e \
			"INSERT INTO filmotheque VALUES \
			(\"\",\"$line\",\"$video_path\",\"$video_title\",\"$purename\",'-',\"$clearname\",\"$codec_video\",\"$codec_audio\",\"$resolution_video\",\"$duration_video\",\"$width\",\"$container\",\"$date_format_bdd\",\"$date_format_bdd\",\"$md5sum\",'NO','','-','0','-');"
			if [ "$?" -ne 0 ]; then error_film[$cpt_test]="$line" && cpt_test=$(($cpt_test+1)); fi;
			cpt_add=$(($cpt_add+1))
			put_verbose_mode 'ADD BDD'
		else 
			# L'entree a ete trouve dans la BDD
			# Mise a jour du champ verifydate
			mysql $bdd_name --batch -u $bdd_user -h $bdd_host -p$bdd_password -N -e \
			"UPDATE filmotheque SET verifydate='$date_format_bdd' WHERE md5sum='$md5sum';";
			cpt_update=$(($cpt_update+1))
			put_verbose_mode 'UPTDATE BDD'
		fi	
	else
		# Exporation des resultats dans un fichier
		get_info_video
		put_verbose_mode 'ADD FILE'
		echo "$video_title:$video_path:$duration_video:$weight:$codec_video:$codec_audio:$container" >>$filmo_file
	fi

done < <(find "${search_path[@]}" -type f -regextype posix-extended -iregex ".*\.($video_format)$")


# MARQUAGE DES FILMS SUPPRIMES / NON TROUVES
mysql $bdd_name --batch -u $bdd_user -h $bdd_host -p$bdd_password -N -e \
"UPDATE filmotheque SET deleted='YES' WHERE verifydate != '$date_format_bdd' AND deleted != 'YES';"
cpt_lost=`mysql $bdd_name --batch -u $bdd_user -h $bdd_host -p$bdd_password -N -e \
"select count(*) FROM filmotheque WHERE verifydate='$date_format_bdd' AND deleted='YES';"`

# INSCRIPTION DE LA DATE DE LA DERNIERE SYNCRHO AVEC LA BDD
if [ "$data" == 'bdd' ]; then
	echo $date_format_bdd > `dirname $0`/last_synchro.info
fi

# script end time
end_script=`date +%s`
time_script=$(($end_script-$start_script))

# Ajout des logs
echo "[$date_format] SYNCRO DONE ($time_script sec)- vidéos trouvées ($cpt_find), ajoutées ($cpt_add), mises à jour ($cpt_update), perdues ($cpt_lost)." >>$logfile

display_files_error
