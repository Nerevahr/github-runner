FROM debian:buster-slim

ARG GITHUB_RUNNER_VERSION=2.272.0
ARG MAVEN_VERSION=3.6.3

ARG MVN_SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG MVN_BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

ENV RUNNER_NAME runner
ENV RUNNER_WORKDIR _work
ENV RUNNER_LABELS ""
ENV DOCKER_GROUP_GUID 113

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG /home/github/.m2

RUN apt-get update \
    && apt-get install -y \
        curl \
        git \
        jq \
        unzip \
        netcat \
        apt-transport-https \
        ca-certificates \
        gnupg-agent \
        software-properties-common \
    && useradd -u 4242 -m github \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Maven install
RUN  mkdir -p /usr/share/maven /usr/share/maven/ref \
    && curl -fsSL -o /tmp/apache-maven.tar.gz ${MVN_BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && echo "${MVN_SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && rm -f /tmp/apache-maven.tar.gz \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# Docker / Kubectl / Node / Yarn install
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/debian \
            $(lsb_release -cs) \
            stable" \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y docker-ce-cli kubectl nodejs yarn \
    && groupadd -g ${DOCKER_GROUP_GUID} docker \
    && usermod -aG docker github \
    && newgrp docker \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/github

# Github action runner install
RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && ./bin/installdependencies.sh \
    && chown github:github -R /home/github

# Cleanup
RUN apt-get remove -y curl jq unzip netcat apt-transport-https gnupg-agent software-properties-common \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=github:github entrypoint.sh ./entrypoint.sh
RUN chmod u+x ./entrypoint.sh

USER github

RUN yarn global add @angular/cli

ENTRYPOINT ["/home/github/entrypoint.sh"]
