#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")/config.source"

cleanup() {
  pulp ostree repository destroy --name "cli_test_ostree_repository_import_all_only" || true
  pulp ostree distribution destroy --name "cli_test_ostree_distro_import_all_only" || true
  pulp orphan cleanup || true
}
trap cleanup EXIT

# workflow fixed in 2.2, https://github.com/pulp/pulp_ostree/issues/279
if pulp debug has-plugin --name "ostree" --min-version "2.2.0"
then
  workdir=$(mktemp -d)
  cd "${workdir}"

  # prepare pulp
  expect_succ pulp ostree repository create --name "cli_test_ostree_repository_import_all_only"
  expect_succ pulp ostree distribution create --name "cli_test_ostree_distro_import_all_only" \
    --repository "cli_test_ostree_repository_import_all_only" \
    --base-path "cli_test_ostree_distro_import_all_only"

  BASE_URL=$(echo "$OUTPUT" | jq -r ".base_url")

  # first commit
  mkdir "${workdir}/first"
  cd "${workdir}/first"
  ostree --repo="${workdir}/first/repo" init --mode=archive
  mkdir "${workdir}/first/files"
  echo "one" > files/file.txt
  commit=$(
    ostree commit --repo "${workdir}/first/repo" --branch ostree-main "${workdir}/first/files/"
  )

  cd "${workdir}/first"
  tar czvf repo.tar "repo/"

  # first upload
  expect_succ pulp ostree repository import-all --name "cli_test_ostree_repository_import_all_only" \
    --file "repo.tar" \
    --repository_name "repo"

  # second commit
  mkdir "${workdir}/second"
  cd "${workdir}/second"
  mkdir files
  echo "two" > files/file2.txt
  ostree --repo="${workdir}/second/repo" init --mode=archive
  ostree commit --repo repo --branch ostree-main files/ --parent="${commit}"
  tar czvf repo.tar repo/

  # second upload
  echo "Uploading and importing second repo"
  expect_succ pulp ostree repository import-all --name "cli_test_ostree_repository_import_all_only" \
    --file "repo.tar" \
    --repository_name "repo"

  # local remote repo
  ostree --repo="${workdir}/rremote" init
  ostree --repo="${workdir}/rremote" remote add --no-gpg-verify iot "$BASE_URL"
  expect_succ ostree --repo="${workdir}/rremote" remote refs iot
  expect_succ ostree --repo="${workdir}/rremote" remote summary iot
  expect_succ ostree --repo="${workdir}/rremote" pull iot ostree-main
fi
