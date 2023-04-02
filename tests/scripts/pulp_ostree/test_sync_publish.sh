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

if pulp debug has-plugin --name "ostree" --min-version "2.0.0"
then
  expect_succ pulp ostree remote create --name "cli_test_ostree_remote" \
    --url "$OSTREE_REMOTE_URL" \
    --include-refs "[\"stable\"]" \
    --exclude-refs "[\"rawhide\"]"
  expect_succ pulp ostree remote update --name "cli_test_ostree_remote" \
    --include-refs "[\"rawhide\"]" \
    --exclude-refs "[\"stable\"]"
else
  expect_succ pulp ostree remote create --name "cli_test_ostree_remote" \
    --url "$OSTREE_REMOTE_URL"
fi

expect_succ pulp ostree repository create --name "cli_test_ostree_repository"
expect_succ pulp ostree repository sync --name "cli_test_ostree_repository" \
  --remote "cli_test_ostree_remote"

expect_succ pulp ostree distribution create --name "cli_test_ostree_distro" \
  --base-path "cli_test_ostree_distro" \
  --repository "cli_test_ostree_repository"

if pulp debug has-plugin --name "ostree" --min-version "2.0.0"
then
  BASE_PATH=$(pulp ostree distribution show --name "cli_test_ostree_distro" | jq -r ".base_url")

  RESPONSE_CODE=$(curl -I "${BASE_PATH}"refs/heads/rawhide | head -n 1| cut -d' ' -f2)
  if [ "$RESPONSE_CODE" != "200" ]
  then
    echo "The 'rawhide' ref could not be found" && exit 1
  fi

  RESPONSE_CODE=$(curl -I "${BASE_PATH}"refs/heads/stable | head -n 1| cut -d' ' -f2)
  if [ "$RESPONSE_CODE" != "404" ]
  then
    echo "The 'stable' ref should not be synced" && exit 1
  fi
fi

expect_succ pulp ostree distribution update --name "cli_test_ostree_distro" --version 0
expect_succ pulp ostree distribution show --name "cli_test_ostree_distro"
REPOSITORY_VERSION_DIST_HREF=$(echo "$OUTPUT" | jq -r ".repository_version")
expect_succ pulp ostree repository show --name "cli_test_ostree_repository"
REPOSITORY_VERSION_REPO_HREF=$(echo "$OUTPUT" | jq -r ".pulp_href")versions/0/

if [ "$REPOSITORY_VERSION_DIST_HREF" != "$REPOSITORY_VERSION_REPO_HREF" ]; then
  echo "Repository versions are not equal" && exit 1
fi
