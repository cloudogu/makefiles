ARG BATS_BASE_IMAGE
ARG BATS_TAG

FROM ${BATS_BASE_IMAGE}:${BATS_TAG}
ARG YQ_VERSION=v4.35.1
ARG YQ_SHA256=bd695a6513f1196aeda17b174a15e9c351843fb1cef5f9be0af170f2dd744f08

# Make bash more findable by scripts and tests
RUN apk add coreutils make git bash jq wget
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /tmp/yq && \
    echo "${YQ_SHA256} */tmp/yq" | sha256sum -c - && \
    mkdir -p /workspace/.bin/ && \
    mv /tmp/yq /workspace/.bin/

RUN addgroup -S -g 1000 bats \
  && adduser -S -h /home/bats -s /bin/bash -G bats -u 1000 bats

USER 1000
