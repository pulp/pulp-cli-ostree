import json
from typing import Any

import click
from pulp_glue.common.i18n import get_translation
from pulp_glue.ostree.context import PulpOstreeRemoteContext
from pulpcore.cli.common.generic import (
    PulpCLIContext,
    common_remote_create_options,
    common_remote_update_options,
    create_command,
    destroy_command,
    href_option,
    label_command,
    label_select_option,
    list_command,
    name_option,
    pass_pulp_context,
    show_command,
    update_command,
)

translation = get_translation(__package__)
_ = translation.gettext


@click.group()
@click.option(
    "-t",
    "--type",
    "remote_type",
    type=click.Choice(["ostree"], case_sensitive=False),
    default="ostree",
)
@pass_pulp_context
@click.pass_context
def remote(ctx: click.Context, pulp_ctx: PulpCLIContext, remote_type: str) -> None:
    if remote_type == "ostree":
        ctx.obj = PulpOstreeRemoteContext(pulp_ctx)
    else:
        raise NotImplementedError()


def parse_refs_list(ctx: click.Context, param: click.Parameter, value: Any) -> Any:
    if value:
        try:
            value = json.loads(value)
        except json.decoder.JSONDecodeError as error:
            raise click.BadParameter(error.msg, ctx=ctx, param=param)
        else:
            if not all(isinstance(s, str) for s in value):
                raise click.BadParameter(
                    "A list of string values should be specified", ctx=ctx, param=param
                )
        return value
    return []


lookup_options = [href_option, name_option]
ostree_remote_options = [
    click.option("--policy", type=click.Choice(["immediate", "on_demand"], case_sensitive=False)),
    click.option("--depth", type=click.INT, default=0),
    click.option("--include-refs", callback=parse_refs_list),
    click.option("--exclude-refs", callback=parse_refs_list),
]

remote.add_command(list_command(decorators=[label_select_option]))
remote.add_command(show_command(decorators=lookup_options))
remote.add_command(create_command(decorators=common_remote_create_options + ostree_remote_options))
remote.add_command(
    update_command(decorators=lookup_options + common_remote_update_options + ostree_remote_options)
)
remote.add_command(destroy_command(decorators=lookup_options))
remote.add_command(label_command())
