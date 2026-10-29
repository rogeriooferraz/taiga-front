# Package a locally built frontend bundle

`Dockerfile.bundle` packages one version of the checked-out frontend's
`dist/` over an explicitly selected frontend base image. The base image
supplies Nginx, optional plugins, and the runtime entrypoint. The build
copies the public index, loading page, selected versioned assets,
configuration template, and entrypoint script. It never copies the local
`dist/conf.json`; runtime configuration comes from the template. The default
source-build Dockerfile remains available.

Build the distribution with the repository's supported Node toolchain and
`npm run ci:test`. Set `bundle_version` to the exact `window.TAIGA_VERSION`
value in `dist/index.html`, including `v-`; check that its directory has
both theme stylesheets. The Dockerfile checks that the index names the
selected version and packages only that version, even if `dist/` also has
older builds. Use a reviewed base image by immutable registry digest for a
release. For a local build, record the selected base image ID and the
resulting image ID.

```sh
docker build \
  --build-context bundle=./dist \
  --build-arg BASE_IMAGE="$reviewed_front_base_image" \
  --build-arg BUNDLE_VERSION="$bundle_version" \
  -f docker/Dockerfile.bundle \
  -t local/taiga-front:bundle-review .
```

The named context keeps `dist/` out of the default Dockerfile's build context.
Compare hashes of the built image's `index.html`, `loading.css`, and compiled
theme files with the selected local `dist/` version before associating the
image with a source revision. Verify that the image has no `conf.json` until
its runtime entrypoint generates one. Run browser checks against the resulting
image. Record the base and resulting registry manifest digests for a release.
A Git commit or tag alone does not establish source-to-image provenance.
