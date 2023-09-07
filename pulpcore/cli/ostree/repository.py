from gettext import gettext as _
from typing import IO, Any, Dict, Optional

import click
from pulp_glue.common.context import (
    EntityFieldDefinition,
    PluginRequirement,
    PulpEntityContext,
    PulpRemoteContext,
    PulpRepositoryContext,
)
from pulp_glue.ostree.context import (
    PulpOstreeCommitContentContext,
    PulpOstreeConfigContentContext,
    PulpOstreeRefContentContext,
    PulpOstreeRemoteContext,
    PulpOstreeRepositoryContext,
)
from pulpcore.cli.common.generic import (
    GroupOption,
    PulpCLIContext,
    chunk_size_option,
    create_command,
    destroy_command,
    href_option,
    label_command,
    label_select_option,
    list_command,
    name_option,
    pass_pulp_context,
    pass_repository_context,
    pulp_option,
    repository_content_command,
    repository_href_option,
    repository_option,
    resource_option,
    retained_versions_option,
    show_command,
    update_command,
    version_command,
)
from pulpcore.cli.core.context import PulpArtifactContext
from pulpcore.cli.core.generic import task_command

remote_option = resource_option(
    "--remote",
    default_plugin="ostree",
    default_type="ostree",
    context_table={"ostree:ostree": PulpOstreeRemoteContext},
    href_pattern=PulpRemoteContext.HREF_PATTERN,
    help=_("Remote used for syncing in the form '[[<plugin>:]<resource_type>:]<name>' or by href."),
)


@click.group()
@click.option(
    "-t",
    "--type",
    "repo_type",
    type=click.Choice(["ostree"], case_sensitive=False),
    default="ostree",
)
@pass_pulp_context
@click.pass_context
def repository(ctx: click.Context, pulp_ctx: PulpCLIContext, repo_type: str) -> None:
    if repo_type == "ostree":
        ctx.obj = PulpOstreeRepositoryContext(pulp_ctx)
    else:
        raise NotImplementedError()


lookup_options = [href_option, name_option]
nested_lookup_options = [repository_href_option, repository_option]
update_options = [
    click.option("--description"),
    remote_option,
    retained_versions_option,
]
create_options = update_options + [click.option("--name", required=True)]

repository.add_command(list_command(decorators=[label_select_option]))
repository.add_command(show_command(decorators=lookup_options))
repository.add_command(create_command(decorators=create_options))
repository.add_command(update_command(decorators=lookup_options + update_options))
repository.add_command(destroy_command(decorators=lookup_options))
repository.add_command(task_command(decorators=nested_lookup_options))
repository.add_command(version_command(decorators=nested_lookup_options))
repository.add_command(label_command(decorators=nested_lookup_options))


def ref_callback(ctx: click.Context, param: click.Parameter, value: Any) -> Any:
    if value:
        pulp_ctx = ctx.find_object(PulpCLIContext)
        assert pulp_ctx is not None
        ctx.obj = PulpOstreeRefContentContext(pulp_ctx, entity=value)
    return value


def commit_callback(ctx: click.Context, param: click.Parameter, value: str) -> str:
    if value:
        pulp_ctx = ctx.find_object(PulpCLIContext)
        assert pulp_ctx is not None
        ctx.obj = PulpOstreeCommitContentContext(pulp_ctx, entity={"checksum": value})
    return value


def config_callback(ctx: click.Context, param: click.Parameter, value: str) -> str:
    if value:
        pulp_ctx = ctx.find_object(PulpCLIContext)
        assert pulp_ctx is not None
        ctx.obj = PulpOstreeConfigContentContext(pulp_ctx, entity={"pulp_href": value})
    return value


ref_options = [
    click.option("--name", cls=GroupOption, expose_value=False, group=["checksum"]),
    click.option(
        "--checksum", cls=GroupOption, expose_value=False, group=["name"], callback=ref_callback
    ),
]
ref_content_command = repository_content_command(
    name="ref",
    contexts={"ref": PulpOstreeRefContentContext},
    add_decorators=ref_options,
    remove_decorators=ref_options,
)

commit_options = [click.option("--checksum", expose_value=False, callback=commit_callback)]
commit_content_command = repository_content_command(
    name="commit",
    contexts={"commit": PulpOstreeCommitContentContext},
    add_decorators=commit_options,
    remove_decorators=commit_options,
)

config_options = [click.option("--pulp_href", expose_value=False, callback=config_callback)]
config_content_command = repository_content_command(
    name="config",
    contexts={"config": PulpOstreeConfigContentContext},
    add_decorators=config_options,
    remove_decorators=config_options,
)

general_list_content_command = repository_content_command(
    contexts={
        "ref": PulpOstreeRefContentContext,
        "commit": PulpOstreeCommitContentContext,
        "config": PulpOstreeConfigContentContext,
    }
)

repository.add_command(ref_content_command)
repository.add_command(commit_content_command)
repository.add_command(config_content_command)
repository.add_command(general_list_content_command)


@repository.command()
@name_option
@href_option
@remote_option
@pass_repository_context
def sync(
    repository_ctx: PulpRepositoryContext,
    remote: EntityFieldDefinition,
) -> None:
    if not repository_ctx.capable("sync"):
        raise click.ClickException(_("Repository type does not support sync."))

    repository = repository_ctx.entity
    repository_href = repository_ctx.pulp_href

    body: Dict[str, Any] = {}

    if isinstance(remote, PulpEntityContext):
        body["remote"] = remote.pulp_href
    elif repository["remote"] is None:
        raise click.ClickException(
            _(
                "Repository '{name}' does not have a default remote. "
                "Please specify with '--remote'."
            ).format(name=repository["name"])
        )

    repository_ctx.sync(href=repository_href, body=body)


@repository.command(help=_("Import all refs and commits from a tarball"))
@click.option("--file", type=click.File("rb"), required=True)
@chunk_size_option
@name_option
@click.option(
    "--repository_name",
    type=str,
    required=True,
    help=_("Name of a repository which contains the imported commits"),
)
@pass_repository_context
@pass_pulp_context
def import_all(
    pulp_ctx: PulpCLIContext,
    repository_ctx: PulpRepositoryContext,
    file: IO[bytes],
    chunk_size: int,
    repository_name: str,
) -> None:
    assert isinstance(repository_ctx, PulpOstreeRepositoryContext)

    repository_href = repository_ctx.pulp_href
    artifact_href = PulpArtifactContext(pulp_ctx).upload(file, chunk_size)
    kwargs = {
        "href": repository_href,
        "artifact": artifact_href,
        "repository_name": repository_name,
    }
    repository_ctx.import_all(**kwargs)


@repository.command(help=_("Import commits from a tarball to a specific ref"))
@click.option("--file", type=click.File("rb"), required=True)
@chunk_size_option
@name_option
@click.option(
    "--repository_name",
    type=str,
    required=True,
    help=_("Name of a repository which contains the imported commits"),
)
@click.option("--ref", type=str, required=False, help=_("Name of a ref"))
@pulp_option(
    "--parent_commit",
    type=str,
    required=False,
    help=_("Name of a parent commit"),
)
@pass_repository_context
@pass_pulp_context
def import_commits(
    pulp_ctx: PulpCLIContext,
    repository_ctx: PulpRepositoryContext,
    file: IO[bytes],
    chunk_size: int,
    repository_name: str,
    ref: Optional[str],
    parent_commit: Optional[str],
) -> None:
    assert isinstance(repository_ctx, PulpOstreeRepositoryContext)

    repository_href = repository_ctx.pulp_href
    artifact_href = PulpArtifactContext(pulp_ctx).upload(file, chunk_size)

    kwargs = {
        "href": repository_href,
        "artifact": artifact_href,
        "repository_name": repository_name,
        "ref": ref,
    }

    if pulp_ctx.has_plugin(PluginRequirement("ostree", max="2.0.0")):
        if not all((ref, parent_commit)) and any((ref, parent_commit)):
            raise click.ClickException(
                "Please specify both the ref and parent_commit if you want to add new child "
                "commits to the existing repository"
            )

        kwargs["parent_commit"] = parent_commit

    repository_ctx.import_commits(**kwargs)
