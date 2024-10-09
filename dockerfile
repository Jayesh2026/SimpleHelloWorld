FROM openjdk:21-jdk AS builder

WORKDIR /app


COPY build/libs/docker-demo-0.0.1-SNAPSHOT.jar app.jar

RUN jar xf app.jar
RUN jdeps --ignore-missing-deps -q \
    --recursive \
    --multi-release 21 \
    --print-module-deps \
    --class-path 'BOOT-INF/lib/*' \
    app.jar > deps.txt

RUN jlink \
    --add-modules $(cat deps.txt) \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output /custom-jre

RUN /custom-jre/bin/java -Xshare:dump

FROM debian:bookworm-slim

ENV JAVA_HOME=/custom-jre
ENV PATH="$JAVA_HOME/bin:$PATH"

RUN mkdir /app
COPY --from=builder /app/app.jar /app/
COPY --from=builder /custom-jre /custom-jre
# Using below line we can access deps.info file
COPY --from=builder /app/deps.txt /app/deps.txt

WORKDIR /app

EXPOSE 8081

ENTRYPOINT ["java", "-XX:ArchiveClassesAtExit=dynamic-cds.jsa", "-jar", "app.jar"]