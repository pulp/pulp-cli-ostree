#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree remote destroy --name "cli_test_ostree_remote" || true
  pulp ostree repository destroy --name "cli_test_ostree_repository" || true
  pulp ostree distribution destroy --name "cli_test_ostree_distro" || true
}
trap cleanup EXIT

if [ "$VERIFY_SSL" = "false" ]
then
  curl_opt="-k"
else
  curl_opt=""
fi

# Those need yet to be implemented
if false
then
expect_succ pulp ostree remote create --name "cli_test_ostree_remote" --url "$OSTREE_REMOTE_URL"
expect_succ pulp ostree repository create --name "cli_test_ostree_repository"
expect_succ pulp ostree repository sync --name "cli_test_ostree_repository" --remote "cli_test_ostree_remote"
expect_succ pulp ostree publication create --repository "cli_test_ostree_repository"
PUBLICATION_HREF=$(echo "$OUTPUT" | jq -r .pulp_href)

expect_succ pulp ostree distribution create --name "cli_test_ostree_distro" \
  --base-path "cli_test_ostree_distro" \
  --publication "$PUBLICATION_HREF"

expect_succ curl "$curl_opt" --head --fail "$PULP_BASE_URL/pulp/content/cli_test_ostree_distro/config.repo"

expect_succ pulp ostree distribution destroy --name "cli_test_ostree_distro"
expect_succ pulp ostree publication destroy --href "$PUBLICATION_HREF"
expect_succ pulp ostree repository destroy --name "cli_test_ostree_repository"
expect_succ pulp ostree remote destroy --name "cli_test_ostree_remote"
fi
