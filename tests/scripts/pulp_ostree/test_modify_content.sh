#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree repository destroy --name "cli_test_ostree_repository1" || true
  pulp ostree repository destroy --name "cli_test_ostree_repository2" || true
  pulp ostree remote destroy --name "cli_test_ostree_remote" || true
  pulp orphan cleanup || true
}
trap cleanup EXIT

expect_succ pulp ostree remote create --name "cli_test_ostree_remote" --url "$OSTREE_REMOTE_URL"
expect_succ pulp ostree repository create --name "cli_test_ostree_repository1"
expect_succ pulp ostree repository sync --name "cli_test_ostree_repository1" \
  --remote "cli_test_ostree_remote"

expect_succ pulp ostree repository create --name "cli_test_ostree_repository2"

# add content to the second repository
expect_succ pulp ostree repository commit add --repository "cli_test_ostree_repository2" \
  --checksum "506f7811e94cb0966ada5f52a60eb4c34e534037497390ec4491712c3b040938"
expect_succ pulp ostree repository ref add --repository "cli_test_ostree_repository2" \
  --name "stable" \
  --checksum "7f92632aa5a71a0a36ff97ae14dd298081d52aaa8fa1cd79fb19521e00c35030"

# remove the added content from the second repository
expect_succ pulp ostree repository commit remove --repository "cli_test_ostree_repository2" \
  --checksum "506f7811e94cb0966ada5f52a60eb4c34e534037497390ec4491712c3b040938"
expect_succ pulp ostree repository ref remove --repository "cli_test_ostree_repository2" \
  --name "stable" \
  --checksum "7f92632aa5a71a0a36ff97ae14dd298081d52aaa8fa1cd79fb19521e00c35030"

# remove the original content from the first repository
expect_succ pulp ostree repository commit remove --repository "cli_test_ostree_repository1" \
  --checksum "506f7811e94cb0966ada5f52a60eb4c34e534037497390ec4491712c3b040938"
expect_succ pulp ostree repository ref remove --repository "cli_test_ostree_repository1" \
  --name "stable" \
  --checksum "7f92632aa5a71a0a36ff97ae14dd298081d52aaa8fa1cd79fb19521e00c35030"

# add the content back to the first repository
expect_succ pulp ostree repository commit add --repository "cli_test_ostree_repository1" \
  --checksum "506f7811e94cb0966ada5f52a60eb4c34e534037497390ec4491712c3b040938"
expect_succ pulp ostree repository ref add --repository "cli_test_ostree_repository1" \
  --name "stable" \
  --checksum "7f92632aa5a71a0a36ff97ae14dd298081d52aaa8fa1cd79fb19521e00c35030"

# list content stored within the latest repository versions
expect_succ pulp ostree repository ref list --repository "cli_test_ostree_repository1"
expect_succ pulp ostree repository ref list --repository "cli_test_ostree_repository1" \
  --type "ref"

expect_succ pulp ostree repository commit list --repository "cli_test_ostree_repository1"
expect_succ pulp ostree repository commit list --repository "cli_test_ostree_repository1" \
  --type "commit"

expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1"

expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
  --type "all"
expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
  --type "ref"
expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
  --type "commit"
