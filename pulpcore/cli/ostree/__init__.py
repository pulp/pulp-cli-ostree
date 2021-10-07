from pulpcore.cli.common import main
from pulpcore.cli.common.context import PluginRequirement, PulpContext, pass_pulp_context


@main.group()
@pass_pulp_context
def ostree(pulp_ctx: PulpContext) -> None:
    pulp_ctx.needs_plugin(PluginRequirement("ostree"))
