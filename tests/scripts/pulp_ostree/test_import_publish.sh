#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree repository destroy --name "cli_test_ostree_repository" || true
  pulp ostree distribution destroy --name "cli_test_ostree_distro" || true
}
trap cleanup EXIT

wget --no-parent -r "$OSTREE_REMOTE_URL"
tar --exclude="index.html" -cvf "fixtures_small_repo.tar" -C "$OSTREE_DOWNLOADED_REPO_PATH" "small"

expect_succ pulp ostree repository create --name "cli_test_ostree_repository"
expect_succ pulp ostree repository import-commits --name "cli_test_ostree_repository" \
  --file "fixtures_small_repo.tar" \
  --repository_name "small"

expect_succ pulp ostree distribution create --name "cli_test_ostree_distro" \
  --base-path "cli_test_ostree_distro" \
  --repository "cli_test_ostree_repository"

expect_succ pulp ostree distribution destroy --name "cli_test_ostree_distro"
expect_succ pulp ostree repository destroy --name "cli_test_ostree_repository"
