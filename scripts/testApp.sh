./mvnw -version
#!/bin/bash
set -euxo pipefail

./mvnw -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -pl system -q clean package liberty:create liberty:install-feature liberty:deploy

./mvnw -ntp -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -pl query -q clean package liberty:create liberty:install-feature liberty:deploy

# Testing the testing environment

./mvnw -pl system -ntp -P test liberty:start
./mvnw -pl query -ntp -Dliberty.var.mp.config.profile="test" liberty:start

./mvnw -pl system -ntp -P test failsafe:integration-test
./mvnw -pl query -ntp failsafe:integration-test
./mvnw -ntp failsafe:verify

./mvnw -pl system -ntp liberty:stop
./mvnw -pl query -ntp liberty:stop

# Testing the development environment

./mvnw -pl system -ntp -P dev liberty:start 
./mvnw -pl query -ntp -Dliberty.var.mp.config.profile="dev" liberty:start 

./mvnw -pl system -ntp -P dev failsafe:integration-test
./mvnw -pl query -ntp failsafe:integration-test
./mvnw -ntp failsafe:verify

./mvnw -pl system -ntp liberty:stop
./mvnw -pl query -ntp liberty:stop

# Testing the production environment

./mvnw -pl system -ntp -P prod liberty:start
./mvnw -pl query -ntp -Dliberty.var.mp.config.profile="prod" liberty:start

./mvnw -pl system -ntp -P prod failsafe:integration-test
./mvnw -pl query -ntp failsafe:integration-test
./mvnw -ntp failsafe:verify

./mvnw -pl system -ntp liberty:stop
./mvnw -pl query -ntp liberty:stop

# Testing the docker environment

./mvnw -P prod package
docker build -t system:1.0-SNAPSHOT system/.
docker build -t query:1.0-SNAPSHOT query/.

NETWORK=query-app
docker network create $NETWORK

docker run -d --network=$NETWORK --name system -p 9080:9080 system:1.0-SNAPSHOT
docker run -d --network=$NETWORK --name query -p 9085:9085 query:1.0-SNAPSHOT

sleep 30

docker logs system | grep Launching
docker logs query | grep Launching

curl http://localhost:9085/query/systems/system

queryStatus="$(curl --write-out "%{http_code}\n" --silent --output /dev/null "http://localhost:9085/query/systems/system")"

docker stop system query
docker rm system query
docker network rm $NETWORK

if [ "$queryStatus" == "200" ]; then
  echo ENDPOINT OK
else
  echo query status: "$queryStatus"
  echo ENDPOINT
  exit 1
fi
