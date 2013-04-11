#!/bin/bash

# script time
start_script=`date +%s`

source `dirname $0`/param.conf

clear_name()
{
        clearname=`echo "$1" |sed -E 's/[_.-]/\ /g' | tr '[[:upper:]]' '[[:lower:]]'` #Remplacer les majuscule par des minuscules
        clearname=`echo "$clearname" |sed -E 's/(720|720p|1080|1080p|#)//g'` #supprimer des chaines 
        clearname=`echo "$clearname" |sed -E 's/\(.*\)//g'` #supprimer le contenu des parentheses 
        clearname=`echo "$clearname" |sed "s/\ \ */\ /g"` #remplacer plusieurs espaces par un seul
}

get_secondes_duration()
{
	hours=`echo $1| cut -d':' -f1 |sed -E 's/^0//'`
	minutes=`echo $1| cut -d':' -f2 |sed -E 's/^0//'`
	secondes=`echo $1| cut -d':' -f3 |sed -E 's/^0//'`
	
	hours=$(( $hours * 60 * 60 ))
	minutes=$(( $minutes * 60 )) 
	secondes=$(( $secondes + $minutes + $hours )) 
}

get_info_video()
{
	video_path=`dirname "$line"`
        ffmpeg_result=`ffmpeg -i "$line" 2>&1 |sed -r "s/\t//g" |tr "\n$" "\ "`
        resolution_video=`echo "$ffmpeg_result" |sed -E "s/.*Video:.*([0-9]{3,}x[0-9]{3,}).*/\\1/"`
	height=`echo $resolution_video | cut -d'x' -f1`
	width=`echo $resolution_video | cut -d'x' -f2`        
	duration_video=`echo "$ffmpeg_result" |sed -E "s/.*Duration: (([0-9]{2}:){2}[0-9]{2}).*/\\1/"`
        codec_audio=`echo "$ffmpeg_result" |sed -E "s/.*Audio: ([a-zA-Z0-9]*).*/\\1/"`
        codec_video=`echo "$ffmpeg_result" |sed -E "s/.*Video: ([a-zA-Z0-9]*).*/\\1/"`
        container=`echo "$video_title" |sed -E "s/.*\.([0-9a-zA-Z]{,4})/\\1/"`
        purename=`echo "$video_title" |sed -E "s/(.*)\.[a-zA-Z0-9]{,4}/\\1/"`
        clear_name "$purename"
	get_secondes_duration "$duration_video"	
	duration_video=$secondes
}

put_verbose_mode()
{	
	if [ $verbose_mode -eq 1 ]; then 
		echo "[$cpt_find] -$1- $line"
	fi
}

cpt_find=0
cpt_add=0
cpt_update=0
cpt_lost=0
date_format_bdd=`date '+%Y-%m-%d %H:%M:%S'`

while read line
do

# test ==========================
#	get_info_video
#	echo ">>>"$ffmpeg_result
#	echo ">>>"$video_titlult	
#	echo ">>>"$duration_video
# test ==========================

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
			('','$line','$video_path','$video_title','$purename','-','$clearname','$codec_video','$codec_audio','$resolution_video','$duration_video','$width','$container','$date_format_bdd','$date_format_bdd','$md5sum','NO','','-','0','-');"
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
	echo $date_format_bdd > ./last_synchro.info
fi

# script time
end_script=`date +%s`
time_script=$(($end_script-$start_script))

# Ajout des logs
echo "[$date_format] SYNCRO DONE ($time_script sec)- vidéos trouvées ($cpt_find), ajoutées ($cpt_add), mises à jour ($cpt_update), perdues ($cpt_lost)." >>$logfile
