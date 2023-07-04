#Travail realisé par : 

#Zouhir AIT SAADA 
#Salas AIT OUARET 
#Adel OULMOU





Help="Usage: $0 La syntaxe de votre commande sera : trishell [-R] [-d] [-nsmletpg] rep
Les différentes options sont les suivantes :
– -R : tri le contenu de l’arborescence débutant au répertoire rep. Dans ce cas on triera par rapport aux
noms des entrées mais on affichera le chemin d’accès ;
– -d : tri dans l’ordre décroissant, par défaut le tri est effectué dans l’ordre croissant ;
– -nsdletpg : permet de spécifier le critère de tri utilisé. Ces critères peuvent être combinés, dans ce cas si
deux fichiers sont identiques pour le premier critère, le second critère les départegera et ainsi de suite.
– -n : tri suivant le nom des entrées ;
– -s : tri suivant la taille des entrées ;
– -m : tri suivant la date de dernière modification des entrées ;
– -l : tri suivant le nombre de lignes des entrées ;
– -e : tri suivant l’extension des entrées (caractères se trouvant après le dernier point du nom de l’entrée ;
– -t : tri suivant le type de fichier (ordre : répertoire, fichier, liens, fichier spécial de type bloc, fichier
spécial de type caractère, tube nommé, socket) ;
– p : tri suivant le nom du propriétaire de l’entrée ;
– g : tri suivant le groupe du propriétaire de l’entrée.
Exemple : trishell -R -d -pse /home trie, par ordre décroissant, l’arborescence débutant à /home en fonction
des propriétaires des entrées comme premier critère, de la taille des entrées comme second critère et de l’extension
des entrées comme dernier critère
"

Version="trishell 1.0
Copyright (C) 2022.

Written by SZA"

# **************************       documentation       ******************

case "$1" in
-help)    echo "$Help"  || exit 0; exit;;
-version) echo "$Version" || exit 0; exit;;
esac

if [[ $# -gt 4 ]]
then
    echo "****y en a bcp d'arguments **** voila la structure correcte, $Help"
    exit 1
fi

# ***************************      initialisation des variables      **************************************************
Tricroissant=true
TriEnRecursivite=false
CriteresTri="NULL"
CTL=1
Chemin="NULL"

#  ***************************          Lecture des Arguments          **********************************************************
for i in "$@"
do
    if [[ "$i" = "-R" ]]
    then
        test "$TriEnRecursivite" = true && echo " veuillez utilisez juste une seule fois l'option -R " && exit 2
        TriEnRecursivite=true
    elif [[ "$i" = "-d" ]]
    then
        test $Tricroissant = false && echo " veuillez utilisez juste une seule fois l'option -d " && exit 2
        Tricroissant=false
    elif [[ "$i" =~ ^[^-] ]]
    then
        test "$Chemin" != NULL && echo "chemin déja mentionné " && exit 2
        ! test -d "$i" && echo "Chemin incorrect: $i" && exit 3
        Chemin="$i"
    else
        test $CriteresTri != NULL && echo "Doublon dans les parametres" && exit 2
        CriteresTri="$i"
        CTL=${#CriteresTri}

        for a in $(seq 3 $(($CTL+1)))
        do
            opt=`echo '\'$CriteresTri | cut -c$a`
            if ! [[ $opt =~ [n|s|m|l|e|t|p|g] ]] 
            then
                echo "-$opt  invalide paramètre de tri" && exit 4
            fi
        done
    fi
done



test "$Chemin" = NULL && Chemin="."


if [[ $CriteresTri = NULL ]]
then
    CriteresTri="-n"
fi

#   ****************************      Le Programme Principale      **************************************************
firstPath=`pwd`
cd "$Chemin"
currentPath=`pwd`
allData=""
sizeOfAllData=0
allFolder=""
for i in *
do
    i=`echo $i | sed 's/\?/\\\?/'`
    allData="$i/$allData"
    test -d "$i" && allFolder="$currentPath/$i:$allFolder"
    sizeOfAllData=$(($sizeOfAllData+1))
done
echo -e "\x1B[39m\x1B[1m`pwd`\x1B[0m"
test "$allData" = "*/" && exit 0



# ****************************************    les fonctions de tri    *********************************************

#tri par rapport au nom 

triParNom(){
    if test "$1" \< "$2" 
    then
        echo 1
    elif test "$1" = "$2"
    then
        echo 2
    else
        echo 0
    fi
}

#tri par rapport a la valeur numérique

triParNum(){
    if [[ "$1" -lt "$2" ]]
    then
        echo 1
    elif [[ "$1" -eq "$2" ]]
    then
        echo 2
    else
        echo 0
    fi
}

#tri par rapport a la taille
triParTaille(){
    local res1=`stat -c '%s' -- "$1"`
    local res2=`stat -c '%s' -- "$2"`

    triParNum $res1 $res2
}

#tri par rapport a la derniere date de modification 

triParDM(){
    local timestamp1=`stat -c '%Y' -- "$1"`
    local timestamp2=`stat -c '%Y' -- "$2"`

    triParNum "$timestamp1" "$timestamp2"
}

#tri par rapport au nombre de ligne

triParNL(){
     local res1
     local res2

     if test -f "$1"; then
         res1=`wc -l "$1" | cut -d' ' -f1`
     elif test ! -f "$1"; then
         res1=0
     fi

     if test -f "$2"; then
         res2=`wc -l "$2" | cut -d' ' -f1`
     elif test ! -f "$2"; then
         res2=0
     fi

    triParNum $res1 $res2
}


#tri par rapport a l'extension
triParExt(){
    #chaine 1 et 2 sont les extensions
    # awk -F. separate the string by dot
    # print $NF will print the last one   
    local chaine1
    local chaine2
    case $1 in
    *.*)  
    chaine1=`echo -- "$1" | awk -F. '{print $NF}'`;;
    *)
    chaine1=0
    ;;
    esac

    case $2 in
    *.*)  
    chaine2=`echo -- "$2" | awk -F. '{print $NF}'`;;
    *)
    chaine2=0
    ;;
    esac

    triParNom "$chaine1" "$chaine2"
}

#tri par rapport au type

triParType(){

    # Répertoire: valeur 1
    # Fichier: valeur 2
    # Lien symbolique: valeur 3
    # Fichier bloc: valeur 4
    # Fichier caractère: valeur 5
    # Tube nommé: valeur 6
    # Socket: valeur 7
    # Le reste à la valeur 8.

    local res1
    local res2

    if test -d "$1"; then
        res1="1"
    elif test -f "$1"; then
        res1="2"
    elif test -L "$1"; then
        res1="3"
    elif test -b "$1"; then
        res1="4"
    elif test -c "$1"; then
        res1="5"
    elif test -p "$1"; then
        res1="6"
    elif test -S "$1"; then
        res1="7"
    else
        res1="8"
    fi

    if test -d "$2"; then
        res2="1"
    elif test -f "$2"; then
        res2="2"
    elif test -L "$2"; then
        res2="3"
    elif test -b "$2"; then
        res2="4"
    elif test -c "$2"; then
        res2="5"
    elif test -p "$2"; then
        res2="6"
    elif test -S "$2"; then
        res2="7"
    else
        res2="8"
    fi

    triParNum "$res1" "$res2" 
}

#tri par rapport au proprietaire

triParProp(){    

    # $1 $2 est le chemin de ce fichier ou répertoire
    # compare the owner name of 2 files or folders.
    
    local chaine1=`stat -c '%U' -- "$1"`
    local chaine2=`stat -c '%U' -- "$2"`


    triParNom "$chaine1" "$chaine2"
}

#tri par rapport au groupe

triParGroupe(){
    # $1 $2 est le chemin de ce fichier ou répertoire
    # compare the group name of 2 files or folders.
   
    local chaine1=` stat -c "%G" -- "$1"`
    local chaine2=` stat -c "%G" -- "$2"`

    triParNom "$chaine1" "$chaine2"
}

#FIN FONCTION DE TRI


#getLowest $elem1 $elem2
#compare les deux parametres par rapport au tri fourni en drapeux
#renvoie 1 si $1 est plus petit que $2, sinon 0
getLowest(){
    if [[ $3 -ge $CTL ]]
    then
        echo "1"
    else
        #On recupere le nom de la fonction de tri aproprié
        local char=`echo '\'$CriteresTri | cut -c$(($3+3))`
        local res
        #On compare
        IFS=\ 
        case $char in
        n) res=`triParNom "$1" "$2"`;;
        s) res=`triParTaille "$1" "$2"`;;
        m) res=`triParDM "$1" "$2"`;;
        l) res=`triParNL "$1" "$2"`;;
        e) res=`triParExt "$1" "$2"`;;
        t) res=`triParType "$1" "$2"`;;
        p) res=`triParProp "$1" "$2"`;;
        g) res=`triParGroupe "$1" "$2"`;;
        esac
        #Si il y a egalité on passe au tri suivant
        if [[ "$res" -eq 2 ]]
        then
            local tmp=`expr $3 + 1`
            echo `getLowest "$1" "$2" $tmp`
        else
        IFS=/
        #Sinon on affiche le resultat
            if test $Tricroissant = "true"
            then 
                echo $res
            elif test "$res" = 1
            then 
                echo 0
            else
                echo 1
            fi
        fi
    fi
}

#parcour le "tableau" fourni agrument ($1) et renvoie le plus petit element
getLast(){
    local res=`echo "$1" | cut -d'/' -f1`
    for i in $1
    do
        if [[ `getLowest "$i" "$res" 0` -eq 1 ]]
        then
            res="$i"
        fi
    done
    echo "$res"
}

#suprime $1 de $2
change(){
    local res=""
    for i in $2
    do
        if [[ "$1" != "$i" ]]
        then
            res="$res""$i/"
        fi
    done
    echo "$res"
}

#recupere le plus petit element, l'afficher, et relancer la meme fonction sans ce dernier 
tri(){
    test -z "$1" && return  
    local res=`getLast "$1"`
    if test -d "$res"
    then
        echo -e "\x1B[94m'-> "$res"\x1B[0m"
    else
        echo -e "\x1B[96m'-> "$res"\x1B[0m"
    fi
    tri "`change "$res" "$1"`"
}

#modification de l'IFS 
main(){
    IFS=/
    tri "$allData"
    IFS=' '
}


Trecursivite(){
    IFS=":"
    for i in $allFolder
    do
        tmp=""
        if test $Tricroissant = "false"
        then 
            tmp="-d"
        fi
        "$0" "$i" $CriteresTri -R $tmp
    done
}


main 
cd "$firstPath"
test $TriEnRecursivite = true && Trecursivite
IFS=$firstIFS
exit 0
