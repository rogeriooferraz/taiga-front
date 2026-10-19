# This source code is licensed under the terms of the GNU Affero General
# Public License found in the LICENSE file in the root of this source tree.

FROM node:24.22.0-bookworm-slim AS frontend
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund
COPY .stylelintrc.js elements.js gulpfile.js gulp-utils.js ./
COPY app/ app/
COPY app-loader/ app-loader/
COPY conf/ conf/
COPY emojis/ emojis/
COPY extras/ extras/
RUN set -eu; \
    source_hash="$( \
        { find app app-loader conf emojis extras -type f -print0 | sort -z | xargs -0 sha256sum; \
          sha256sum .stylelintrc.js elements.js gulpfile.js gulp-utils.js package.json package-lock.json; } \
        | sha256sum | cut -c1-16 \
    )"; \
    TAIGA_BUILD_VERSION="v-${source_hash}" ./node_modules/.bin/gulp deploy; \
    test -s dist/index.html

FROM alpine:3.24 AS plugins
RUN apk add --no-cache curl unzip
WORKDIR /work
RUN set -eu; \
    mkdir -p /out/plugins/slack /out/plugins/github-auth /out/plugins/gitlab-auth; \
    curl -fsSL https://codeload.github.com/taigaio/taiga-contrib-slack/zip/refs/tags/6.10.0 -o slack.zip; \
    echo '61ca8a4486495226769e8fd6d72744bfa8a6616a6b2f4965665c6b72492dcac7  slack.zip' | sha256sum -c -; \
    unzip -j -q slack.zip 'taiga-contrib-slack-6.10.0/front/dist/*' -d /out/plugins/slack; \
    curl -fsSL https://codeload.github.com/taigaio/taiga-contrib-github-auth/zip/refs/tags/6.10.0 -o github.zip; \
    echo '44bfff24264a49103e9430cab32d8ed703e1b25f747781580df429f07c4af84a  github.zip' | sha256sum -c -; \
    unzip -j -q github.zip 'taiga-contrib-github-auth-6.10.0/front/dist/*' -d /out/plugins/github-auth; \
    curl -fsSL https://codeload.github.com/taigaio/taiga-contrib-gitlab-auth/zip/refs/tags/6.10.0 -o gitlab.zip; \
    echo '98bfc0d0358a15f1c02ddae1b1f7d40cd1c2de4bcb486e151334d7b3193bc612  gitlab.zip' | sha256sum -c -; \
    unzip -j -q gitlab.zip 'taiga-contrib-gitlab-auth-6.10.0/front/dist/*' -d /out/plugins/gitlab-auth

FROM nginx:stable-alpine
RUN apk upgrade --no-cache && apk add --no-cache bash
COPY --from=frontend /work/dist/ /usr/share/nginx/html/
COPY --from=plugins /out/plugins/ /usr/share/nginx/html/plugins/
COPY docker/default.conf /etc/nginx/conf.d/default.conf
COPY docker/conf.json.template /usr/share/nginx/html/conf.json.template
COPY docker/config_env_subst.sh /docker-entrypoint.d/30_config_env_subst.sh
RUN chmod +x /docker-entrypoint.d/30_config_env_subst.sh
