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

expect_succ pulp ostree repository content list --repository "cli_test_ostree_repository1" \
  --type "ref"

COMMIT_CHECKSUM1=$(echo "$OUTPUT" | jq -r ".[0].checksum")
COMMIT_CHECKSUM2=$(echo "$OUTPUT" | jq -r ".[1].checksum")
REF_NAME2=$(echo "$OUTPUT" | jq -r ".[1].name")

expect_succ pulp ostree repository create --name "cli_test_ostree_repository2"

# add content to the second repository
pulp ostree repository commit add --repository "cli_test_ostree_repository2" \
  --checksum "$COMMIT_CHECKSUM1"
pulp ostree repository ref add --repository "cli_test_ostree_repository2" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"

# remove the added content from the second repository
pulp ostree repository commit remove --repository "cli_test_ostree_repository2" \
  --checksum "$COMMIT_CHECKSUM1"
pulp ostree repository ref remove --repository "cli_test_ostree_repository2" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"

# remove the original content from the first repository
pulp ostree repository commit remove --repository "cli_test_ostree_repository1" \
  --checksum "$COMMIT_CHECKSUM1"
pulp ostree repository ref remove --repository "cli_test_ostree_repository1" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"

# add the content back to the first repository
pulp ostree repository commit add --repository "cli_test_ostree_repository1" \
  --checksum "$COMMIT_CHECKSUM1"
pulp ostree repository ref add --repository "cli_test_ostree_repository1" \
  --name "$REF_NAME2" \
  --checksum "$COMMIT_CHECKSUM2"

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
  --type "commit"
