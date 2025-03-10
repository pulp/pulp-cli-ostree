#!/bin/sh

set -eu
# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

CLI15="$(python -c "from packaging.version import parse; from pulpcore.cli.common import __version__; print(parse(__version__) >= parse('0.15.0.dev'))")"

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

if [ "$CLI15" = "True" ]
then
  expect_succ pulp ostree repository content --type "ref" list \
    --repository "cli_test_ostree_repository1"
else
  expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
    --type "ref"
fi

COMMIT_CHECKSUM1=$(echo "$OUTPUT" | jq -r ".[0].checksum")
COMMIT_CHECKSUM2=$(echo "$OUTPUT" | jq -r ".[1].checksum")
REF_NAME2=$(echo "$OUTPUT" | jq -r ".[1].name")

if [ "$CLI15" = "True" ]
then
  expect_succ pulp ostree repository content --type "config" list \
    --repository "cli_test_ostree_repository1"
else
  expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
    --type "config"
fi

CONFIG_HREF=$(echo "$OUTPUT" | jq -r ".[0].pulp_href")

expect_succ pulp ostree repository create --name "cli_test_ostree_repository2"

# add content to the second repository
expect_succ pulp ostree repository commit add --repository "cli_test_ostree_repository2" \
  --checksum "$COMMIT_CHECKSUM1"
expect_succ pulp ostree repository ref add --repository "cli_test_ostree_repository2" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"
expect_succ pulp ostree repository config add --repository "cli_test_ostree_repository2" \
  --pulp_href "$CONFIG_HREF"

# remove the added content from the second repository
expect_succ pulp ostree repository commit remove --repository "cli_test_ostree_repository2" \
  --checksum "$COMMIT_CHECKSUM1"
expect_succ pulp ostree repository ref remove --repository "cli_test_ostree_repository2" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"
expect_succ pulp ostree repository config remove --repository "cli_test_ostree_repository2" \
  --pulp_href "$CONFIG_HREF"

# remove the original content from the first repository
expect_succ pulp ostree repository commit remove --repository "cli_test_ostree_repository1" \
  --checksum "$COMMIT_CHECKSUM1"
expect_succ pulp ostree repository ref remove --repository "cli_test_ostree_repository1" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"

# add the content back to the first repository
expect_succ pulp ostree repository commit add --repository "cli_test_ostree_repository1" \
  --checksum "$COMMIT_CHECKSUM1"
expect_succ pulp ostree repository ref add --repository "cli_test_ostree_repository1" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"

# list content stored within the latest repository versions
expect_succ pulp ostree repository ref list --repository "cli_test_ostree_repository1"

if [ "$CLI15" = "True" ]
then
  expect_succ pulp ostree repository ref --type "ref" list \
    --repository "cli_test_ostree_repository1"
else
  expect_succ pulp ostree repository ref list --repository "cli_test_ostree_repository1" \
    --type "ref"
fi

expect_succ pulp ostree repository commit list --repository "cli_test_ostree_repository1"

if [ "$CLI15" = "True" ]
then
  expect_succ pulp ostree repository commit --type "commit" list \
    --repository "cli_test_ostree_repository1"
else
  expect_succ pulp ostree repository commit list --repository "cli_test_ostree_repository1" \
    --type "commit"
fi

expect_succ pulp ostree repository config list --repository "cli_test_ostree_repository1"

if [ "$CLI15" = "True" ]
then
  expect_succ pulp ostree repository config --type "config" list \
    --repository "cli_test_ostree_repository1"
else
  expect_succ pulp ostree repository config list --repository "cli_test_ostree_repository1" \
    --type "config"
fi

expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1"

if [ "$CLI15" = "True" ]
then
  expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
    --all-types
  expect_succ pulp ostree repository content --type "commit" list \
    --repository "cli_test_ostree_repository1"
else
  expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
    --type "all"
  expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
    --type "commit"
fi
