from typing import Any

import click
from pulp_glue.common.i18n import get_translation
from pulpcore.cli.common.generic import pulp_group

from pulpcore.cli.ostree.distribution import distribution
from pulpcore.cli.ostree.remote import remote
from pulpcore.cli.ostree.repository import repository

translation = get_translation(__package__)
_ = translation.gettext

__version__ = "0.6.0.dev"


@pulp_group("ostree")
def ostree_group() -> None:
    pass


def mount(main: click.Group, **kwargs: Any) -> None:
    ostree_group.add_command(distribution)
    ostree_group.add_command(remote)
    ostree_group.add_command(repository)
    main.add_command(ostree_group)
