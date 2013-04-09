#!/bin/bash

# Vous devez avoir la base de donnée au préalable avoir d'effectuer cette commande. Exemple :
# mysql> CREATE DATABASE MA BDD

source `dirname $0`/param.conf
mysql $bdd_password -u $bdd_user -h $bdd_host -p$bdd_password < ./filmo_schema.sql
