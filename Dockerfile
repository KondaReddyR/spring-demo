FROM  docker.io/hadolint/hadolint:v2.9.3-debian AS linter
COPY Dockerfile /tmp/
RUN hadolint Dockerfile > /tmp/lint-issues && \
    if [ -s /tmp/lint-issues ]; then cat /tmp/lint-issues && exit 1; fi

FROM docker.io/library/gradle:7.4.1 AS builder
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION:-1.0.0}
ARG USERNAME=gradle

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
LABEL description="APP_NAME=spring-demo APP_VERSION=${APP_VERSION}"

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
