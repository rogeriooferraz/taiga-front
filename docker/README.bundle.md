# Package a locally built frontend bundle

`Dockerfile.bundle` packages the checked-out frontend's `dist/` over an
explicitly selected frontend base image. The base image supplies Nginx,
optional plugins, and the runtime entrypoint. The build copies the local
bundle, configuration template, and entrypoint script; the default Dockerfile
and its upstream distribution download remain available.

Build the distribution with the repository's supported Node toolchain and
`npm run ci:test`. Inspect `dist/index.html`, `dist/loading.css`, and both
theme stylesheets before packaging. Use a reviewed base image by immutable
registry digest for a release. For a local build, record the selected base
image ID and the resulting image ID.

```sh
docker build \
  --build-context bundle=./dist \
  --build-arg BASE_IMAGE="$reviewed_front_base_image" \
  -f docker/Dockerfile.bundle \
  -t local/taiga-front:bundle-review .
```

The named context keeps `dist/` out of the default Dockerfile's build context.
Compare hashes of the built image's `index.html`, `loading.css`, and compiled
theme files with the local `dist/` files before associating the image with a
source revision. Run browser checks against the resulting image. Record the
base and resulting registry manifest digests for a release. A Git commit or
tag alone does not establish source-to-image provenance.
