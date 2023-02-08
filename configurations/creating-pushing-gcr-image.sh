#!/bin/bash
docker build -t gcr.io/ahmed-nasr-iti-demo/devops-challenge:v1.0 ../app
docker push gcr.io/ahmed-nasr-iti-demo/devops-challenge:v1.0

docker tag redis gcr.io/ahmed-nasr-iti-demo/redis
docker push gcr.io/ahmed-nasr-iti-demo/redis
