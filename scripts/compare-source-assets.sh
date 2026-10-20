#!/usr/bin/env bash
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.

set -euo pipefail

if (( $# != 2 )); then
    printf 'Usage: %s IMAGE_A IMAGE_B\n' "$0" >&2
    exit 2
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

for index in 1 2; do
    image=${!index}
    docker image inspect "$image" >/dev/null
    docker run --rm --network none --entrypoint sh "$image" -ec '
        test -s /usr/share/nginx/html/index.html
        cd /usr/share/nginx/html
        find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
        find . -type l -print | LC_ALL=C sort | while IFS= read -r link; do
            printf "SYMLINK %s -> %s\n" "$link" "$(readlink "$link")"
        done
    ' > "$tmp_dir/$index"
done

diff -u "$tmp_dir/1" "$tmp_dir/2"
printf 'Frontend asset trees match.\n'
