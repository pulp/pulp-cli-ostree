#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree repository destroy --name "cli_test_ostree_repository_two_refs" || true
  pulp ostree distribution destroy --name "cli_test_ostree_distro_two_refs" || true
  pulp orphan cleanup || true
}
trap cleanup EXIT

# workflow fixed in 2.2, https://github.com/pulp/pulp_ostree/issues/277
if pulp debug has-plugin --name "ostree" --min-version "2.2.0"
then
  workdir=$(mktemp -d)
  cd "${workdir}"

  # prepare pulp
  expect_succ pulp ostree repository create --name "cli_test_ostree_repository_two_refs"
  expect_succ pulp ostree distribution create --name "cli_test_ostree_distro_two_refs" \
    --repository "cli_test_ostree_repository_two_refs" \
    --base-path "cli_test_ostree_distro_two_refs"

  BASE_URL=$(echo "$OUTPUT" | jq -r ".base_url")

  # first commit
  mkdir "${workdir}/first"
  cd "${workdir}/first"
  ostree --repo="${workdir}/first/repo" init --mode=archive
  mkdir "${workdir}/first/files"
  echo "one" > files/file.txt
  ostree commit --repo "${workdir}/first/repo" --branch first "${workdir}/first/files/"

  cd "${workdir}/first"
  tar czvf repo.tar "repo/"

  # first upload
  expect_succ pulp ostree repository import-all \
    --name "cli_test_ostree_repository_two_refs" \
    --file "repo.tar" \
    --repository_name "repo"

  # local remote repo
  ostree --repo="${workdir}/rremote" init
  ostree --repo="${workdir}/rremote" remote add --no-gpg-verify iot "$BASE_URL"
  expect_succ ostree --repo="${workdir}/rremote" remote refs iot
  expect_succ ostree --repo="${workdir}/rremote" remote summary iot

  # second commit
  mkdir "${workdir}/second"
  cd "${workdir}/second"
  mkdir files
  echo "two" > files/file2.txt
  ostree --repo="${workdir}/second/repo" init --mode=archive
  ostree commit --repo repo --branch second files/
  tar czvf repo.tar repo/

  # second upload
  expect_succ pulp ostree repository import-all \
    --name "cli_test_ostree_repository_two_refs" \
    --file "repo.tar" \
    --repository_name "repo"

  # fetch refs
  expect_succ ostree --repo="${workdir}/rremote" remote refs iot
  expect_succ ostree --repo="${workdir}/rremote" remote summary iot
  expect_succ ostree --repo="${workdir}/rremote" pull iot second
  expect_succ ostree --repo="${workdir}/rremote" pull iot first
fi
