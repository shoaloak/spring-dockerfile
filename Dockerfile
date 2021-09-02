# syntax=docker/dockerfile:1
# Multi-stage docker file with sane defaults and documentation for Maven-based Java Spring applications

##### STAGE: base
# Specific official OpenJDK image with latest Java version
FROM openjdk:16-alpine3.13@sha256:f9be8e89a2bbf973dcd6c286f85bb0f68a8f9d5fa7c6241eb59f07add4a24789 as base

WORKDIR /app

# Copy application into image and download dependencies; -B for Maven disables color output
COPY src ./src
COPY .mvn/ ./.mvn
COPY mvnw pom.xml ./
# dependency:go-offline does not work as expected, subsequent Maven spring-boot:run goal downloads dependencies
#RUN ./mvnw -B dependency:go-offline
# the go-offline-maven-plugin ensures no more dependency resolvement, but does take a while to finish
RUN ./mvnw -B de.qaware.maven:go-offline-maven-plugin:resolve-dependencies


##### STAGE: development
FROM base as development

EXPOSE 8000
EXPOSE 8080

# Start the application with JDWP agent debug port enabled
CMD ["./mvnw", \
     "spring-boot:run", \
     "-Dspring-boot.run.jvmArguments=\"-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000\""]


##### STAGE: TEST
FROM base as test

RUN ./mvnw test


##### STAGE: build
FROM base as build

RUN ./mvnw package -Dmaven.test.skip


##### STAGE: production
# Specific official OpenJDK JRE image with latest LTS Java version
FROM openjdk:11-jre-slim@sha256:f3cdb8fd164057f4ef3e60674fca986f3cd7b3081d55875c7ce75b7a214fca6d as production

# Please specify custom UID/GID that does not overlap with your host: https://tinyurl.com/tewa72ca
# e.g. docker build --build-arg UID=707 --build-arg GID=707 .
ARG UID=707
ARG GID=707

WORKDIR /app

EXPOSE 8080

# Create non-root user and set permissions
# don't use adduser/addgroup commands unless necessary (Debian/Ubuntu), since they are wrappers
RUN groupadd --system --gid ${GID} appgroup && \
    useradd --no-log-init --system -g appgroup --uid ${UID} appuser && \
    chown -R appuser:appgroup /app && \
    chmod 755 /app

COPY --from=build --chown=appuser:appgroup /app/target/*.jar /app/app.jar

USER appuser
CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/app.jar"]
