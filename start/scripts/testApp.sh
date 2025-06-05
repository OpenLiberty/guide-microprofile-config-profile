#!/bin/bash
./mvnw -version

./mvnw -pl system -ntp clean package liberty:create liberty:install-feature liberty:deploy
./mvnw -pl query -ntp clean package liberty:create liberty:install-feature liberty:deploy

./mvnw -pl system -ntp -P test liberty:start
./mvnw -pl query -ntp -Dliberty.var.mp.config.profile="test" liberty:start

./mvnw -pl system -ntp -P test failsafe:integration-test
./mvnw -pl query -ntp failsafe:integration-test

./mvnw -pl query -ntp liberty:stop
./mvnw -pl system -ntp liberty:stop
