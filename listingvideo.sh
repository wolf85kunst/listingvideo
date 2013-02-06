#!/bin/bash
########################################################################################
# Titre
# Auteur		Hugo GUTEKUNST 
# Version		1.0.1
# Date			27/11/2011
# Descriptif		Constituer sa filmothèque en 10 secondes
# Info			Chemin absolu, titre, resolution, poid, duree
########################################################################################


# ==================================================================================== #
# ==================================================================================== #
# PARAMETRES
# ==================================================================================== #
# ==================================================================================== #

# Format date
date=`date +%Y%m%d-%H%M`
prefix_fichier_log='listing_'
defaut_fichier_log=$HOME/$prefix_fichier_log$date
defaut_search=$HOME/$USER/Vidéos/

fichier_log=$defaut_fichier_log
search=$defaut_seach

# Des couleurs
VERT="\\033[1;32m"
NORMAL="\\033[0;39m"
ROUGE="\\033[1;31m"
ROSE="\\033[1;35m"
BLEU="\\033[1;34m"
BLANC="\\033[0;02m"
BLANCLAIR="\\033[1;08m"
JAUNE="\\033[1;33m"
CYAN="\\033[1;36m"
# EXEMPLE DUTILISATION --> echo -e "$ROUGE" "Bonjour !" "$NORMAL"

# ==================================================================================== #
# ==================================================================================== #
# FONCTIONS
# ==================================================================================== #
# ==================================================================================== #

box_dialog()
{
	# Chemin de sauvegarde de la liste des films
		fichier_log=$(whiptail --inputbox "Fichier de la liste de vos films" 50 50 --title "FILMOTHEQUE" $defaut_fichier_log 3>&1 1>&2 2>&3)
	# Chemin de recherche des films
		search=$(whiptail --inputbox "Dossier de recherche :" 50 50 --title "FILMOTHEQUE" $defaut_search 3>&1 1>&2 2>&3)
}

readlist()
{
echo "Fichiers 'list' de vos films :"
echo "" 
ls | egrep "^listing_" | nl

# Menu de choix :
whiptail --title "Menu example" --menu "Choose an option" 20 78 16 \
"" "" \
"" "" \
"" "" \
"" ""

param=$1
case $param in
	'-b')
		# Si l'option -b est precise, alors on affiche une liste BRUTE
		cat $fichier_log | less ;;
	'-a')
		# Si l'option -a est précise, alors on trie par ordre ALPHABETIQUE
		cat $fichier_log | cut -d : -f 2 | sort | nl ;; 
	'-t')
		# Si l'option -t est précise, alors on trie par DUREE du film
		cat $fichier_log | cut -d : -f 2,5 | sort -t: -k2nr,2nr | nl ;; 
	'-p')
		# Si l'option -p est presise, alors on trie par TAILLE de film
		cat $fichier_log | cut -d : -f 2,4 | sort -t: -k2nr,2nr | nl ;;
	*)
		# Par DEFAUT on affiche uniquement les noms de fichiers
		cat $fichier_log | cut -d : -f 2 | sort | nl ;; 
esac
}

list()
{
box_dialog
echo "Recherche des films dans $search en cours..."
echo "Les données seront sauvegardées dans $fichier_log".
while read line
do
	path=${line}
   	name=${path##*/}
	poids=$(stat -c '%s' "${line}") ## en octets
	duration=$(mplayer "$line" -vo null -ao null -frames 0 -identify 2>/dev/null | egrep "ID_LENGTH" | cut -d = -f 2)
	size=$(mplayer "$line" -vo null -ao null -frames 0 -identify 2>/dev/null | egrep -m2 '^ID_VIDEO_(WIDTH|HEIGHT)')
	width=$(echo ${size#*=} | cut -d" " -f 1)
	height=${size##*=}
	resolution="${width}x${height}"

	if echo $path | egrep -q "/\."; then : ;
 	else 
		echo $name
		echo "$path:$name:$resolution:$poids:$duration" >> $fichier_log 
	fi

done < <(find $search -type f \( -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mpeg" \))
}

# ==================================================================================== #
# ==================================================================================== #
# CORP DU PROGRAMME
# ==================================================================================== #
# ==================================================================================== #

case $1 in
	readlist)readlist $2;;
	list)list;;
	*)
		echo -e "$JAUNE"
		echo "# -----------------------------------------------"
		echo "CREATED BY HUGO GUTEKUNST v1.1"
		echo "15/10/2011"
		echo "# -----------------------------------------------"
		echo -e "$NORMAL" 
		echo -e "$ROUGE"
		echo "Ulisez \"$0 readlist|list|help\" :"
		echo -e "\t-readlist : Consultez la liste de vos films, \"readlist -b\" pour afficher la liste brute."
		echo -e "\t-list : générez le listing de vos film."
		echo -e "\t-help : Obtenir de l'aide sur la commande."
		echo -e "$NORMAL"
		;;
esac
