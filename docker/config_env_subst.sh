#!/bin/bash

# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC

contribs=()

# Slack
if [[ -z "${ENABLE_SLACK}" ]]; then
    export ENABLE_SLACK="false"
fi

if [ ${ENABLE_SLACK} == "true" ]; then
    contribs+=('"plugins/slack/slack.json"')
fi

# Public registration and oauth
if [[ -z "${PUBLIC_REGISTER_ENABLED}" ]]; then
    export PUBLIC_REGISTER_ENABLED="false"
fi

if [ ${PUBLIC_REGISTER_ENABLED} == "true" ]; then
    if [ ${ENABLE_GITHUB_AUTH} == "true" ]; then
        contribs+=('"plugins/github-auth/github-auth.json"')
    fi
    if [ ${ENABLE_GITLAB_AUTH} == "true" ]; then
        contribs+=('"plugins/gitlab-auth/gitlab-auth.json"')
    fi
fi

# Importers
if [[ -z "${ENABLE_GITHUB_IMPORTER}" ]]; then
    export ENABLE_GITHUB_IMPORTER="false"
fi

if [[ -z "${ENABLE_JIRA_IMPORTER}" ]]; then
    export ENABLE_JIRA_IMPORTER="false"
fi

if [[ -z "${ENABLE_TRELLO_IMPORTER}" ]]; then
    export ENABLE_TRELLO_IMPORTER="false"
fi

# Default language
if [[ -z "${DEFAULT_LANGUAGE}" ]]; then
    export DEFAULT_LANGUAGE="en"
fi

# Debug
if [[ -z "${DEBUG}" ]]; then
    export DEBUG="false"
fi

# Optional deployment support contact. Reject characters that could break
# the generated JSON before passing the value through envsubst.
PROJECT_SUPPORT_URL="${PROJECT_SUPPORT_URL:-}"
if [[ -n "$PROJECT_SUPPORT_URL" ]]; then
    if [[ ! "$PROJECT_SUPPORT_URL" =~ ^(mailto:|https://) ]] ||
       [[ ! "$PROJECT_SUPPORT_URL" =~ ^[A-Za-z0-9:/?\&=._%+@#~-]+$ ]]; then
        echo "Invalid PROJECT_SUPPORT_URL" >&2
        exit 1
    fi
fi
export PROJECT_SUPPORT_URL

PROJECT_SUPPORT_LABEL="${PROJECT_SUPPORT_LABEL:-Project support}"
if [[ ${#PROJECT_SUPPORT_LABEL} -gt 80 ]] ||
   [[ "$PROJECT_SUPPORT_LABEL" == *\"* ]] ||
   [[ "$PROJECT_SUPPORT_LABEL" == *\\* ]] ||
   [[ "$PROJECT_SUPPORT_LABEL" =~ [[:cntrl:]] ]]; then
    echo "Invalid PROJECT_SUPPORT_LABEL" >&2
    exit 1
fi
export PROJECT_SUPPORT_LABEL

contribs=$( IFS=,; echo "[${contribs[*]}]" )

export CONTRIB_PLUGINS=$contribs

FILE=/usr/share/nginx/html/conf.json
if [ ! -f "$FILE" ]; then
    envsubst < /usr/share/nginx/html/conf.json.template \
             > /usr/share/nginx/html/conf.json
fi

sed -i 's;<base href="/">;<base href="'"${TAIGA_SUBPATH}/"'">;g' /usr/share/nginx/html/index.html
