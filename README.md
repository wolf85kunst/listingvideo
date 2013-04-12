AUTEUR : HUGO GUTEKUNST
NOM : ListingVideo
VERSION : 2.0
LICENCE : GPLV3

ARPROUVE : fonctionne sur Debian et Ubuntu.

PREREQUIS : 
	Le paquet FFMPEG.
	Un acces a une base de donnees MYSQL.

DESCRIPTION :
	Ce logiciel vous permet de realiser un inventaire de votre filmotheque et de le stocker dans une base de donnees.
	Les informations a recuperer sont les codecs audio, codecs video, la duree, le conteneur video, etc.
	La syncronisation de la base de etre planifiee par un cron.

UTILISATION : 
	Recuperer ce programme comme suit.
	cd /home/user && git clone https://github.com/wolf85kunst/listingvideo.git && cd listingvideo
	veillez a remplir les informations utiles dans le fichier "param.conf" avec 'nano/vim param.conf', dont les informations d'authentification a la BDD.
	lancez le script d'initialisation de la BDD -> 'bash setup_bdd.sh'. Ce script permet remplir la base de donnees avec les tables necessaires. La BDD est alors prete a recevoir le listing des videos de votre filmotheque.
	Lancez manuellement le scrit principal pour initier le listing de vos films a l'aide de la commande 'bash listingvideo.sh'. Il est possible de planifier une resyncronisation de votre repertoire de film par un cron.
	Pour ce faire crontab -e. Choisissez votre editeur et tapez la ligne suivante '0 18 * * * /chemin_de_mon_script/listingvideo.sh' pour planifier la syncro tous les jours a 18H.
	
MISE A JOUR : 
	Une interface web sera developper pour editer, lister, et effectuer des requettes sur la BDD.
	Un systeme de requetage des informations relative a un film doit etre developper afin de pouvoir recuperer le synopsys, jaquette film, genre du film, etc.
	Un debuggage et un controle d'ajout des films a la BDD doit etre ajoute. Des plantages du script ont ete observer sur certain film, du a la recuperation des information ffmpeg
	Automatisation de l'installation pour une mise en place simplifiee.
	Possibilite d'automatiser l'ajout d'un cron pour la syncronisation de la BDD.
	Votre aide est la bien venu.
