#!/bin/zsh

# Preparation
## echo "deb http://ftp.fr.debian.org/debian/ wheezy-backports main" >> /etc/apt/sources.list
## cat > /etc/apt/preferences << EOF
## Package: *
## Pin: release n=unstable
## Pin-Priority: 1000
## EOF
## aptitude update
## aptitude install jq

# Programme
readonly Su=/bin/su
readonly Jq=/usr/bin/jq
readonly Psql=/usr/bin/psql
readonly Curl=/usr/bin/curl

# Test des pré-requis
for Bin in $Su $Jq $Psql $Curl ; do
    if [[ ! -f $Bin ]] ; then
        echo Merci d\'installer $(basename $Bin)
        exit 1
    fi
done

exit 42

# API
readonly ApiUser="user_api"
readonly ApiPass="pass_api"
readonly ApiHost="127.0.0.1"
readonly ApiPort="9486"

# Socket
SocketPort=5123
fd=""

# Déclaration des variables
declare -A IdTaxa=()
UserToModify=''

# Dictionnaire
## a=azerty
## echo ${a:3:2}                                                                                                                           root@xivo
## rt
# Type = (CaracDebut NombreCarac)
Ordre=(0 2)
Chambre=(2 4)
Nom=(10 20)

# Fonctions
OpenSocket () {
    zmodload zsh/net/tcp
    ztcp -l ${SocketPort}
    listenfd=${REPLY}
    ztcp -a ${listenfd}
    fd=${REPLY}
}

CloseSocket () {
    zmodload zsh/net/tcp
    ztcp -cf
}

ReadFromSocket () {
    read -r line <&${fd}; print -r - ${line}
}

SearchIdUser () {
    $Curl -s -H "Content-Type:application/json" -H "Accept:application/json" --digest --insecure --cookie '' -u ${ApiUser}:${ApiPass} "https://${ApiHost}:${ApiPort}/1.1/users?view=directory" | jq --arg UserToFind ${1} '.items | .[] | select(.exten==$UserToFind) | .id'
}

ChangeNom () {
    $Curl -X PUT -H "Content-Type:application/json" -H "Accept:application/json" --digest --insecure --cookie '' -u ${ApiUser}:${ApiPass} https://${ApiHost}:${ApiPort}/1.1/users/$(SearchIdUser ${Chambre}) -d \'{ "firstname": "${Nom}" }\'
}

SetLanguage () {

}

AutorizeSortant () {
    for i in echo ${IdTaxa[*]} ; do
        ${Su} - postgres -c "${Psql} -A -t asterisk -c \"insert into rightcallmember (rightcallid, type, typeval) VALUES (${i}, 'user', \'$(SearchIdUser ${UserToModify})\');\""
    done
}

BlockSortant () {
    ${Su} - postgres -c "${Psql} -A -t asterisk -c \"delete from rightcallmember where typeval=\'$(SearchIdUser ${UserToModify})\';\""
}

#AutorizeInterChambre () {
#
#}

#ForbidInterChambre () {
#
#}

#SendTaxa () {
    # Probablement dans un autre script
    ## C'est envoyé au fil de l'eau vers le PMS
#}

OpenRoom () {
    ChangeNom
    AutorizeSortant
    SetLanguage
}

CloseRoom () {
    ChangeNom
    BlockSortant
    SendTaxa
}

ParseInput () {
    Commande=$(ReadFromSocket)
    if ${Ordre}
}


Initialize () {
    # On commence par détruire les socket ouverte
    CloseSocket

    # On va chercher les id des règles de filtrage et les stocker
    IdTaxa=(\
        $(${Su} - postgres -c "${Psql} -A -t asterisk -c \"select id from rightcallexten where exten='_00[12345679].';\"") \
        $(${Su} - postgres -c "${Psql} -A -t asterisk -c \"select id from rightcallexten where exten='_0.';\"") \
    )
    OpenSocket
}

Initialize

while true ; do
    ParseInput
done

CloseSocket
