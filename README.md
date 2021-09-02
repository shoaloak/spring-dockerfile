# Spring Dockerfile

This is a documented, multi-stage dockerfile for a (simple) Maven-based
Java Spring application. It is largely based on the [official Docker
Java language specific guide](https://docs.docker.com/language/java/).

We use the
[go-offline-maven-plugin](https://github.com/qaware/go-offline-maven-plugin)
instead of using the `dependency:go` goal, since not all dependencies
are resolved with the default dependency plugin. Without this Maven
will resolve dependencies when starting the development container,
something which should already be done during image creation in our
opinion.

We also create a non-root user for running the application in
production. This is due to the fact that even though containers are
isolated with Linux capabilities, [if an unauthorized user manages to
break out of the container, he/she breaks out as
root](https://stackoverflow.com/questions/19054029/security-of-docker-as-it-runs-as-root-user).

Continuing on this, make sure you [specify a custom UID/GID that does
not overlap with any of your host
users/groups](https://medium.com/@mccode/understanding-how-uid-and-gid-work-in-docker-containers-c37a01d01cf). Do
base this key on your default range, see `cat /etc/login.defs | grep
"SYS_"`

Finally, `/dev/urandom` is faster but slightly less secure than
`/dev/random`. This is necessary since Docker containers lack entropy.
The dot in the path is a workaround for [a bug in Java 5 and
later](https://bugs.openjdk.java.net/browse/JDK-6202721), resulting in
`java.security.egd=file:/dev/./urandom`.


## CLI Building and Running

We recommend `docker-compose` to automate this.

### Building

**Development:**
`docker build --tag spring-dockerfile:jdk . --target development`

**Production:**
`docker build --tag spring-dockerfile:jre --build-arg UID=707 --build-arg GID=707 . --target production`


### Running

**Development:**
`docker run -it --rm -p 8080:8080 -p 8000:8000 --name development spring-dockerfile:jdk`

**Production:**
`docker run -it --rm -p 8080:8080 --name production spring-dockerfile:jre`


## Extras

It might be worthwhile to [not immediately start the java
process](https://engineeringblog.yelp.com/2016/01/dumb-init-an-init-for-docker.html),
but instead start an init, such as
[dumb-init](https://github.com/Yelp/dumb-init), first inside the
container. This supposedly allows for proper handling of signals.

We have done some simple testing and not found this worthwhile for
such a small application, but maybe it does fit your personal use
case.
