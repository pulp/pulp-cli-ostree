#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree remote destroy --name "cli_test_ostree_remote" || true
  pulp ostree repository destroy --name "cli_test_ostree_repository" || true
  pulp ostree distribution destroy --name "cli_test_ostree_distro" || true
  pulp orphan cleanup || true
}
trap cleanup EXIT

expect_succ pulp ostree remote create --name "cli_test_ostree_remote" --url "$OSTREE_REMOTE_URL"
expect_succ pulp ostree repository create --name "cli_test_ostree_repository"
expect_succ pulp ostree repository sync --name "cli_test_ostree_repository" \
  --remote "cli_test_ostree_remote"

expect_succ pulp ostree distribution create --name "cli_test_ostree_distro" \
  --base-path "cli_test_ostree_distro" \
  --repository "cli_test_ostree_repository"

expect_succ pulp ostree distribution update --name "cli_test_ostree_distro" --version 0
expect_succ pulp ostree distribution show --name "cli_test_ostree_distro"
REPOSITORY_VERSION_DIST_HREF=$(echo "$OUTPUT" | jq -r ".repository_version")
expect_succ pulp ostree repository show --name "cli_test_ostree_repository"
REPOSITORY_VERSION_REPO_HREF=$(echo "$OUTPUT" | jq -r ".pulp_href")versions/0/

if [ "$REPOSITORY_VERSION_DIST_HREF" != "$REPOSITORY_VERSION_REPO_HREF" ]; then
  echo "Repository versions are not equal" && exit 1
fi
