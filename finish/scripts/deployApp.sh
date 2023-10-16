#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: ./deployApp.sh [username] [password]"
    exit 1
fi

USERNAME="$1"
PASSWORD="$2"

# tag::build[]
mvn -pl system -ntp clean package liberty:create liberty:install-feature liberty:deploy
mvn -pl query -ntp clean package liberty:create liberty:install-feature liberty:deploy
# end::build[]

# tag::start[]
mvn -pl system -ntp \
    -P prod \
    -Dliberty.var.default.username="$USERNAME" \
    -Dliberty.var.default.password="$PASSWORD" \
    liberty:start
mvn -pl query -ntp \
    -Dliberty.var.mp.config.profile="prod" \
    -Dliberty.var.system.user="$USERNAME" \
    -Dliberty.var.system.password="$PASSWORD" \
    liberty:start
# end::start[]
