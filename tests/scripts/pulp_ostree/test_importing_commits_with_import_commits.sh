#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree repository destroy --name "cli_test_ostree_repository" || true
  pulp ostree distribution destroy --name "cli_test_ostree_distro" || true
  pulp orphan cleanup || true
}
trap cleanup EXIT

wget --no-parent -r "$OSTREE_REMOTE_URL"
tar --exclude="index.html" -cvf "fixtures_small_repo.tar" -C "$OSTREE_DOWNLOADED_REPO_PATH" "small"

expect_succ pulp ostree repository create --name "cli_test_ostree_repository"

if pulp debug has-plugin --name "ostree" --min-version "2.0.0"
then
  expect_succ pulp ostree repository import-all --name "cli_test_ostree_repository" \
    --file "fixtures_small_repo.tar" \
    --repository_name "small"
else
  expect_succ pulp ostree repository import-commits --name "cli_test_ostree_repository" \
    --file "fixtures_small_repo.tar" \
    --repository_name "small"
fi

tar -xvf fixtures_small_repo.tar
# extract the latest commit checksum from the ref 'stable'
LATEST_COMMIT=$(ostree --repo=small show stable | head -n 1 | cut -d ' ' -f2-3)
rm -rf small/

# add a new commit and associate it with the parent commit
mkdir tree
echo "Hello world!" > tree/hello.txt

ostree --repo=small init --mode=archive
ostree --repo=small commit --branch "stable" tree/ --parent="$LATEST_COMMIT"
tar -cvf "fixtures_small_repo_new_commit.tar" "small"

if pulp debug has-plugin --name "ostree" --min-version "2.0.0"
then
  expect_succ pulp ostree repository import-commits --name "cli_test_ostree_repository" \
    --file "fixtures_small_repo_new_commit.tar" \
    --repository_name "small" \
    --ref "stable"
else
  expect_succ pulp ostree repository import-commits --name "cli_test_ostree_repository" \
    --file "fixtures_small_repo_new_commit.tar" \
    --repository_name "small" \
    --ref "stable" \
    --parent_commit "$LATEST_COMMIT"
fi

expect_succ pulp ostree distribution create --name "cli_test_ostree_distro" \
  --base-path "cli_test_ostree_distro" \
  --repository "cli_test_ostree_repository"
