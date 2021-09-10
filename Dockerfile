# syntax=docker/dockerfile:1
# Multi-stage docker file with sane defaults and documentation for Maven-based Java Spring applications

##### STAGE: base
# Specific OpenJDK image with latest Java version
FROM eclipse-temurin:16.0.2_7-jdk-focal@sha256:464ae9eda46599180d4221672b416407ced45707dbc11ab6501e84d7ea832278 as base

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
# Specific OpenJDK JRE image with latest LTS Java version
FROM eclipse-temurin:11.0.12_7-jre-focal@sha256:87d6207d6e6c6d24acab2608e4f0152d240fe09532b11714000867b6b0d01b22 as production

# Please specify custom UID/GID that does not overlap with your host: https://tinyurl.com/tewa72ca
# e.g. docker build --build-arg UID=707 --build-arg GID=707 .
ARG UID=707
ARG GID=707

# Application folder location
ARG APP_LOC=/app
ENV APP_LOC=${APP_LOC}
WORKDIR ${APP_LOC}

EXPOSE 8080

# Create non-root user and set permissions
# don't use adduser/addgroup commands unless necessary (Debian/Ubuntu), since they are wrappers
RUN groupadd --system --gid ${GID} appgroup && \
    useradd --no-log-init --system -g appgroup --uid ${UID} appuser && \
    chown -R appuser:appgroup ${APP_LOC} && \
    chmod 755 ${APP_LOC}

COPY --from=build --chown=appuser:appgroup /app/target/*.jar ./application.jar

USER appuser
CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "application.jar"]
