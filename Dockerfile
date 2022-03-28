FROM ghcr.io/aquasecurity/trivy:0.24.4 as trivy

FROM trivy as scanner
RUN mkdir -p /tmp/app
COPY . /tmp/app
RUN trivy  fs --exit-code 1 --security-checks vuln,config /tmp/app/Dockerfile > /tmp/Dockerfile-report.log && \
    cat /tmp/Dockerfile-report.log

FROM docker.io/library/gradle:7.4.1 AS builder
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION:-1.0.0}
ARG USERNAME=gradle
COPY --from=scanner /tmp/Dockerfile-report.log /tmp/Dockerfile-report.log
COPY . /home/$USERNAME/
WORKDIR /home/$USERNAME/

#RUN mkdir -p /home/gradle/build/libs && \
#    touch /home/$USERNAME/build/libs/spring-demo-${APP_VERSION}.jar

RUN gradle --info clean build -Pversion=${APP_VERSION} && \
    ls -l /home/$USERNAME/build/libs/ && \
    ls -l /home/$USERNAME/build/libs/spring-demo-${APP_VERSION}.jar


FROM docker.io/library/openjdk:11.0.14.1-jre-buster AS base
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION:-1.0.0}

# Create a non-root user
ARG USERNAME=appuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
&& useradd --uid $USER_UID --gid $USER_GID -m $USERNAME --home /home/$USERNAME
COPY --from=builder /home/gradle/build/libs/spring-demo-${APP_VERSION}.jar /home/$USERNAME/spring-demo.jar
RUN chown -R $USER_UID:$USER_GID /home/$USERNAME/spring-demo.jar && \
chmod 400 /home/$USERNAME/spring-demo.jar
WORKDIR /home/$USERNAME
USER $USERNAME

EXPOSE 8081
HEALTHCHECK --interval=1m --timeout=1s --start-period=5s --retries=2 \
CMD curl -f http://localhost:8081/ || exit 1

#CMD ["ls", "-ltr", "/home/appuser/spring-demo.jar"]
CMD ["java", "-jar", "/home/appuser/spring-demo.jar"]

# Run vulnerability scan on final image
FROM base AS vulnscan
COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy
RUN trivy rootfs --exit-code 0  / > /tmp/base-image-vulnscan-report && \
    cat /tmp/base-image-vulnscan-report

FROM base AS test
ARG USERNAME=appuser
COPY --from=vulnscan  /tmp/base-image-vulnscan-report /tmp/base-image-vulnscan-report
RUN java -jar /home/$USERNAME/spring-demo.jar & echo 'Running Application' && \
    sleep 90 && \
    curl http://localhost:8081 && \
    kill -9 `pidof java` && date > /tmp/image-test-date

FROM base as final
LABEL description="APP_NAME=spring-demo APP_VERSION=${APP_VERSION}"
COPY --from=test  /tmp/image-test-date /tmp/image-test-date