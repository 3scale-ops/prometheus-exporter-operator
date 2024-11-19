# Release

- Update Makefile variable `VERSION` to the appropiate release version. Allowed formats:
  - alpha: `VERSION ?= 0.3.0-alpha.12`
  - stable: `VERSION ?= 0.3.0`

## Alpha

- If it is an **alpha** release, execute the following target to create appropiate `alpha` bundle files:

```bash
make prepare-alpha-release
```

- Then you can manually execute opeator, bundle and catalog build/push.

```bash
make release-publish
```

## Stable

- But if it is an **stable** release, execute the following target to create appropiate `alpha` and `stable` bundle files:

```bash
make prepare-stable-release
```

- Then open a [Pull Request](https://github.com/3scale-ops/prometheus-exporter-operator/pulls), and the [Release GitHub Action](https://github.com/3scale-ops/prometheus-exporter-operator/actions/workflows/release.yaml) will automatically detect if it is new release or not, in order to create it by building/pushing new operator and bundle.

- As part of the release workflow, a:

  - Release Draft will be published, review the changelog, adding any missing information and publish the release.
  - A new Pull Request will open with the updated catalog including the new release.

- Review the Catalog Pull Request and merge it to publish the trigger the [Release Catalog GitHub Action](https://github.com/3scale-ops/prometheus-exporter-operator/actions/workflows/release-catalog.yaml). This action will automatically build and publish the new catalog image.
