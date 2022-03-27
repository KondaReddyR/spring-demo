# An example spring-boot application

* A [Spring-boot Java project](https://spring.io/projects/spring-boot)
* Dockerfile, Containers images will be scanned using [Trivy](https://aquasecurity.github.io/trivy/).
* Containers Integration using Docker [multi-stage build](), [GitHub Actions](), [ArgoCD]().

## Local setup
```shell
git clone --recursive https://github.com/KondaReddyR/spring-demo.git
cd spring-demo

APP_VERSION=1.0.0
docker build --build-arg APP_VERSION=${APP_VERSION} -t spring-demo:${APP_VERSION} .
docker run --rm -d -p 8081:8081 --name spring-demo spring-demo:${APP_VERSION}
curl http://localhost:8081
docker rm -f spring-demo
```

## Docker multistage build

```mermaid
  graph LR;
      Start((Start building <br>container image))-->Linter{Lint </br> Dockerfile};      
      Linter-->Builder[ Build Jar and Run unit Tests];
      Builder-->BaseImage[ Create a slim container image];
      BaseImage-->vulnscan{ Scan</br> image for</br> vulnerabilities}
      BaseImage-->IntTest{ Run <br>integration <br>tests}
      vulnscan--Yes-->FinalImage((vulnerabilities free<br> final image))
      IntTest--Yes-->FinalImage
      vulnscan-.No.->fail(Fail)
      IntTest-.No.->fail
      Linter-.No.->fail
      style Start fill:#fff,stroke:#333,stroke-width:4px,color:#000
      style fail fill:#f00,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5
      style FinalImage fill:#0f0,stroke:#333,stroke-width:4px,color:#000
```

Running in Kubernetes

```shell
helm upgrade --install spring-demo ./spring-demo-iac/spring-demo --set image.tag=1.0.2
kubectl port-forward service/spring-demo 8081:8081
curl http://localhost:8081
```