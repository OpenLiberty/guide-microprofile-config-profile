#!/bin/bash
set -euxo pipefail

mvn -P prod clean package

kubectl api-resources --api-group=apps.openliberty.io | grep "apps.openliberty.io"

docker pull icr.io/appcafe/open-liberty:kernel-slim-java11-openj9-ubi
docker build -t system:1.0-SNAPSHOT system/.
docker build -t query:1.0-SNAPSHOT query/.

docker tag system:1.0-SNAPSHOT us.icr.io/"${SN_ICR_NAMESPACE}"/system:1.0-SNAPSHOT
docker push us.icr.io/"${SN_ICR_NAMESPACE}"/system:1.0-SNAPSHOT

docker tag query:1.0-SNAPSHOT us.icr.io/$SN_ICR_NAMESPACE/query:1.0-SNAPSHOT
docker push us.icr.io/$SN_ICR_NAMESPACE/query:1.0-SNAPSHOT

sed -i 's=system:1.0-SNAPSHOT=us.icr.io/'"${SN_ICR_NAMESPACE}"'/system:1.0-SNAPSHOT\n  pullPolicy: Always\n  pullSecret: icr=g' deploy.yaml
sed -i 's=query:1.0-SNAPSHOT=us.icr.io/'"${SN_ICR_NAMESPACE}"'/query:1.0-SNAPSHOT\n  pullPolicy: Always\n  pullSecret: icr=g' deploy.yaml

kubectl create secret generic sys-app-credentials --from-literal username=admin --from-literal password=adminpwd

kubectl apply -f deploy.yaml

sleep 60

kubectl get OpenLibertyApplications | grep 'us.icr.io/'"${SN_ICR_NAMESPACE}"'/system:1.0-SNAPSHOT'
kubectl get OpenLibertyApplications | grep 'us.icr.io/'"${SN_ICR_NAMESPACE}"'/query:1.0-SNAPSHOT'
kubectl describe olapps/system | grep "apps.openliberty.io/v1" 
kubectl describe olapps/query | grep "apps.openliberty.io/v1" 
kubectl describe pods
kubectl port-forward svc/query 9448 &

sleep 20

curl -k -s "https://localhost:9448/query/systems/system.${SN_ICR_NAMESPACE}.svc"
curl -k -s "https://localhost:9448/query/systems/system.${SN_ICR_NAMESPACE}.svc" | grep "\"os.name\":\"Linux\"" || exit 1

pkill -f "port-forward"
kubectl delete -f deploy.yaml
kubectl delete secret sys-app-credentials

docker image prune -a -f

echo "Tests passed"

