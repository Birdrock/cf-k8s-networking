ARG BUILD_IMAGE=golang:1.13
ARG RUN_IMAGE=cloudfoundry/run:tiny

FROM ${BUILD_IMAGE} AS build
ARG GIT_SHA
RUN if [ -z "$GIT_SHA" ]; then echo "GIT_SHA not set"; exit 1; else : ; fi

COPY ./ /go/src/routecontroller/
WORKDIR /go/src/routecontroller/
RUN go install

FROM ${RUN_IMAGE}
COPY --from=build /go/bin/routecontroller /routecontroller/
WORKDIR /routecontroller
ENTRYPOINT ["/routecontroller/routecontroller"]

ARG GIT_SHA
ARG BUILD_IMAGE
ARG RUN_IMAGE
LABEL org.opencontainers.image.source=https://github.com/Birdrock/cf-k8s-networking.git \
            org.opencontainers.image.revision=$GIT_SHA \
            org.cloudfoundry.project.name=cf-k8s-networking \
            org.cloudfoundry.project.component.name=routecontroller \
            org.cloudfoundry.image.base.build=$BUILD_IMAGE \
            org.cloudfoundry.image.base.run=$RUN_IMAGE
