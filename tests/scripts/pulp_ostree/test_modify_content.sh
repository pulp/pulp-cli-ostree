#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree repository destroy --name "cli_test_ostree_repository1" || true
  pulp ostree repository destroy --name "cli_test_ostree_repository2" || true
  pulp ostree remote destroy --name "cli_test_ostree_remote" || true
}
trap cleanup EXIT

expect_succ pulp ostree remote create --name "cli_test_ostree_remote" --url "$OSTREE_REMOTE_URL"
expect_succ pulp ostree repository create --name "cli_test_ostree_repository1"
expect_succ pulp ostree repository sync --name "cli_test_ostree_repository1" \
  --remote "cli_test_ostree_remote"

expect_succ pulp ostree repository create --name "cli_test_ostree_repository2"

# add content to the second repository
expect_succ pulp ostree repository content add --repository "cli_test_ostree_repository2" \
  --commit "506f7811e94cb0966ada5f52a60eb4c34e534037497390ec4491712c3b040938"
expect_succ pulp ostree repository content add --repository "cli_test_ostree_repository2" \
  --ref "stable"

# remove the added content from the repository
expect_succ pulp ostree repository content remove --repository "cli_test_ostree_repository2" \
  --commit "506f7811e94cb0966ada5f52a60eb4c34e534037497390ec4491712c3b040938"
expect_succ pulp ostree repository content remove --repository "cli_test_ostree_repository2" \
  --ref "stable"

# list content stored within the latest versions of the repositories
expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
  --type "all"
expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository2" \
  --type "commit"
