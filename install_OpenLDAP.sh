#!/bin/bash

# Recuperer l'ip local
ip_local=`hostname -i`

# Changer le nom de l'hote
sudo hostnamectl set-hostname ldap.exemple.com

# Ajouter l'adresse IP et le FQDN au fichier /etc/hosts
sudo sed -i "2i\\$ip_local ldap.exemple.com" /etc/hosts

# Vérifier si un argument a été fourni
if [ -n "$1" ]; then
    # Utiliser l'argument fourni comme valeur de la variable
    LDAP_ADMIN_PASSWORD="$1"
else
    # Utiliser une valeur par défaut si aucun argument n'est fourni
    LDAP_ADMIN_PASSWORD="admin"
fi

# Définir les sélections pour debconf
echo "slapd slapd/internal/adminpw password $LDAP_ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/internal/generated_adminpw password $LDAP_ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/password1 password $LDAP_ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/password2 password $LDAP_ADMIN_PASSWORD" | debconf-set-selections
echo "slapd slapd/domain string example.com" | debconf-set-selections
echo "slapd shared/organization string Example Organization" | debconf-set-selections

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y slapd ldap-utils

# Utiliser la variable dans le script
echo "Le mot de passe ADMIN est : $LDAP_ADMIN_PASSWORD"

# Verifier la config
sudo /sbin/slapcat

# Creation de la base ldif
echo "dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups" > basedn.ldif

ldapadd -x -D cn=admin,dc=example,dc=com -w $LDAP_ADMIN_PASSWORD -f basedn.ldif

# Vérifier si un argument a été fourni
if [ -n "$2" ]; then
    # Utiliser l'argument fourni comme valeur de la variable
    LDAP_PASSWORD="$2"
else
    # Utiliser une valeur par défaut si aucun argument n'est fourni
    LDAP_PASSWORD="user"
fi

# Générer le mot de passe chiffré avec slappasswd
HASH_LDAPD_PASSWORD=$(slappasswd -s "$LDAP_PASSWORD")

# Générer le mot de passe chiffré avec slappasswd
HASH_LDAPD_PASSWORD=$(slappasswd -s "$LDAP_PASSWORD")

# Utiliser le mot de passe chiffré dans la configuration de slapd
echo "Le mot de passe chiffré est : $HASH_LDAPD_PASSWORD"

# Fichier de creation de l'utilisateur
echo "dn: uid=JohnWick,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: John
sn: Wick
userPassword: $HASH_LDAPD_PASSWORD
loginShell: /bin/bash
uidNumber: 2000
gidNumber: 2000
homeDirectory: /home/computingforgeeks" > ldapusers.ldif

ldapadd -x -D cn=admin,dc=example,dc=com -w $LDAP_ADMIN_PASSWORD -f ldapusers.ldif

# Fichier de creation du groupe
echo "dn: cn=computing,ou=groups,dc=example,dc=com
objectClass: posixGroup
cn: computingforgeeks
gidNumber: 2000
memberUid: computing" > ldapgroups.ldif

ldapadd -x -D cn=admin,dc=example,dc=com -w $LDAP_ADMIN_PASSWORD -f ldapgroups.ldif