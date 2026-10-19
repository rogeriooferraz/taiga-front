# This source code is licensed under the terms of the GNU Affero General
# Public License found in the LICENSE file in the root of this source tree.

FROM alpine:3.24 AS assets
RUN apk add --no-cache curl unzip
WORKDIR /work
RUN set -eu; \
    curl -fsSL https://codeload.github.com/taigaio/taiga-front-dist/zip/refs/tags/6.10.3 -o front.zip; \
    echo '4c9a97d2d134dbb884d307742d9cf60c359360849f7d2086b5beff823c1c25f6  front.zip' | sha256sum -c -; \
    unzip -q front.zip; \
    mkdir -p /out/plugins/slack /out/plugins/github-auth /out/plugins/gitlab-auth; \
    cp -a taiga-front-dist-6.10.3/dist/. /out/; \
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
COPY --from=assets /out/ /usr/share/nginx/html/
COPY docker/default.conf /etc/nginx/conf.d/default.conf
COPY docker/conf.json.template /usr/share/nginx/html/conf.json.template
COPY docker/config_env_subst.sh /docker-entrypoint.d/30_config_env_subst.sh
RUN chmod +x /docker-entrypoint.d/30_config_env_subst.sh
