#!/bin/bash
set -euxo pipefail

mvn -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -pl system -q clean package liberty:create liberty:install-feature liberty:deploy

mvn -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -pl query -q clean package liberty:create liberty:install-feature liberty:deploy

# Testing the testing environment

mvn -pl system -ntp -P test liberty:start
mvn -pl query -ntp -Dliberty.var.mp.config.profile="test" liberty:start

mvn -pl system -ntp -P test failsafe:integration-test
mvn -pl query -ntp failsafe:integration-test
mvn -ntp failsafe:verify

mvn -pl system -ntp liberty:stop
mvn -pl query -ntp liberty:stop

# Testing the development environment

mvn -pl system -ntp -P dev liberty:start 
mvn -pl query -ntp -Dliberty.var.mp.config.profile="dev" liberty:start 

mvn -pl system -ntp -P dev failsafe:integration-test
mvn -pl query -ntp failsafe:integration-test
mvn -ntp failsafe:verify

mvn -pl system -ntp liberty:stop
mvn -pl query -ntp liberty:stop

# Testing the production environment

mvn -pl system -ntp -P prod liberty:start
mvn -pl query -ntp -Dliberty.var.mp.config.profile="prod" liberty:start

mvn -pl system -ntp -P prod failsafe:integration-test
mvn -pl query -ntp failsafe:integration-test
mvn -ntp failsafe:verify

mvn -pl system -ntp liberty:stop
mvn -pl query -ntp liberty:stop
