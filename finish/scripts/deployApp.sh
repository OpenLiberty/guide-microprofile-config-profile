#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: ./deployApp.sh <username> <password>"
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
    # tag::systemProd[]
    -P prod \
    # end::systemProd[]
    # tag::systemCredential[]
    -Dliberty.var.default.username="$USERNAME" \
    -Dliberty.var.default.password="$PASSWORD" \
    # end::systemCredential[]
    liberty:start
# end::start-system[]
mvn -pl query -ntp \
    # tag::queryProd[]
    -Dliberty.var.mp.config.profile="prod" \
    # end::queryProd[]
    # tag::queryCredential[]
    -Dliberty.var.system.user="$USERNAME" \
    -Dliberty.var.system.password="$PASSWORD" \
    # end::queryCredential[]
    liberty:start
# end::start-query[]
# end::start[]
