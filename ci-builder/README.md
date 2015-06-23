### Building in a CI environment
This directory contains all thats required to build the container in a CI environment
such as Jenkins.

#### Building in Jenkins
To build in Jenkins, track this repo and then add the following to your Jenkins build
job.

```
# Set application-specific docker settings
REGISTRY="my-registry"
APPLICATION="my-base"

# Pulling the previous build for cache purposes
docker pull ubuntu:utopic
docker pull ${REGISTRY}/${APPLICATION}:latest

# Substitute the proxy settings
sed -i "s/CproxyhostC/your-proxy/" ./Dockerfile
sed -i "s/CproxyportC/3128/" ./Dockerfile
sed -i "s/CmavennoproxyC/*.example.com|*.sub.example.com|127.0.0.1/" ./Dockerfile

# Build the new image
echo "Building a docker image..."
docker build --rm=true -t $REGISTRY/$APPLICATION:${GIT_COMMIT}_${BUILD_NUMBER} .

docker rmi $REGISTRY/$APPLICATION:latest

docker tag $REGISTRY/$APPLICATION:${GIT_COMMIT}_${BUILD_NUMBER} $REGISTRY/$APPLICATION:latest

docker push ${REGISTRY}/${APPLICATION}:${GIT_COMMIT}_${BUILD_NUMBER}
docker push ${REGISTRY}/${APPLICATION}:latest

docker rmi ${REGISTRY}/${APPLICATION}:${GIT_COMMIT}_${BUILD_NUMBER}
docker rmi ${REGISTRY}/${APPLICATION}:latest
```
