
helm install hello-world ./hello-world

 helm upgrade hello-world ./hello-world

 helm package .

 helm registry login

      helm registry login <registry_address> -u <username> -p <password>

           helm push <chart_name>.tgz oci://<registry_address>/<chart_repository>




[helm doc](https://helm.sh/docs/helm/helm/)

docker build -t jamilnoyda/python-hello:latest .

docker push jamilnoyda/python-hello:latest

git push -u origin main


kubectl port-forward svc/hello-world-service 8080:80
curl http://localhost:8080