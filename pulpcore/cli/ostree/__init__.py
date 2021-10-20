from pulpcore.cli.common import main
from pulpcore.cli.common.context import PluginRequirement, PulpContext, pass_pulp_context

from pulpcore.cli.ostree.distribution import distribution
from pulpcore.cli.ostree.remote import remote
from pulpcore.cli.ostree.repository import repository


@main.group()
@pass_pulp_context
def ostree(pulp_ctx: PulpContext) -> None:
    pulp_ctx.needs_plugin(PluginRequirement("ostree"))


ostree.add_command(distribution)
ostree.add_command(remote)
ostree.add_command(repository)
