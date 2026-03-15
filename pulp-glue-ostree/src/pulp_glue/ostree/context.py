from gettext import gettext as _
from typing import Any, ClassVar, Dict, Optional

from pulp_glue.common.context import (
    EntityDefinition,
    PluginRequirement,
    PulpContentContext,
    PulpEntityContext,
    PulpRemoteContext,
    PulpRepositoryContext,
    PulpRepositoryVersionContext,
)


class PulpOstreeCommitContentContext(PulpContentContext):
    PLUGIN = "ostree"
    RESOURCE_TYPE = "commit"
    ENTITY = _("commit content")
    ENTITIES = _("commit content")
    HREF = "ostree_ostree_commit_href"
    ID_PREFIX = "content_ostree_commits"
    NEEDS_PLUGINS = [PluginRequirement("ostree", specifier=">=2.0.0")]


class PulpOstreeRefContentContext(PulpContentContext):
    PLUGIN = "ostree"
    RESOURCE_TYPE = "ref"
    ENTITY = _("ref content")
    ENTITIES = _("ref content")
    HREF = "ostree_ostree_ref_href"
    ID_PREFIX = "content_ostree_refs"
    NEEDS_PLUGINS = [PluginRequirement("ostree", specifier=">=2.0.0")]


class PulpOstreeConfigContentContext(PulpContentContext):
    PLUGIN = "ostree"
    RESOURCE_TYPE = "config"
    ENTITY = _("config content")
    ENTITIES = _("config content")
    HREF = "ostree_ostree_config_href"
    ID_PREFIX = "content_ostree_configs"
    NEEDS_PLUGINS = [PluginRequirement("ostree", specifier=">=2.0.0")]


class PulpOstreeDistributionContext(PulpEntityContext):
    PLUGIN = "ostree"
    RESOURCE_TYPE = "ostree"
    ENTITY = _("ostree distribution")
    ENTITIES = _("ostree distributions")
    HREF = "ostree_ostree_distribution_href"
    ID_PREFIX = "distributions_ostree_ostree"
    NEEDS_PLUGINS = [PluginRequirement("ostree", specifier=">=2.0.0")]

    def preprocess_entity(self, body: EntityDefinition, partial: bool = False) -> EntityDefinition:
        body = super().preprocess_entity(body, partial)
        version = body.pop("version", None)
        if version is not None:
            repository_href = body.pop("repository")
            body["repository_version"] = f"{repository_href}versions/{version}/"
        return body


class PulpOstreeRemoteContext(PulpRemoteContext):
    PLUGIN = "ostree"
    RESOURCE_TYPE = "ostree"
    ENTITY = _("ostree remote")
    ENTITIES = _("ostree remotes")
    HREF = "ostree_ostree_remote_href"
    ID_PREFIX = "remotes_ostree_ostree"
    NEEDS_PLUGINS = [PluginRequirement("ostree", specifier=">=2.0.0")]


class PulpOstreeRepositoryVersionContext(PulpRepositoryVersionContext):
    PLUGIN = "ostree"
    RESOURCE_TYPE = "ostree"
    HREF = "ostree_ostree_repository_version_href"
    ID_PREFIX = "repositories_ostree_ostree_versions"
    NEEDS_PLUGINS = [PluginRequirement("ostree", specifier=">=2.0.0")]


class PulpOstreeRepositoryContext(PulpRepositoryContext):
    PLUGIN = "ostree"
    RESOURCE_TYPE = "ostree"
    HREF = "ostree_ostree_repository_href"
    ID_PREFIX = "repositories_ostree_ostree"
    IMPORT_ALL_ID: ClassVar[str] = "repositories_ostree_ostree_import_all"
    IMPORT_COMMITS_ID: ClassVar[str] = "repositories_ostree_ostree_import_commits"
    VERSION_CONTEXT = PulpOstreeRepositoryVersionContext
    NEEDS_PLUGINS = [PluginRequirement("ostree", specifier=">=2.0.0")]
    CAPABILITIES = {
        "sync": [PluginRequirement("ostree")],
        "import_all": [PluginRequirement("ostree", specifier=">=2.0.0")],
        "import_commits": [PluginRequirement("ostree")],
    }

    def import_all(self, href: str, artifact: str, repository_name: str) -> Any:
        body: Dict[str, Any] = {
            "artifact": artifact,
            "repository_name": repository_name,
        }
        return self.pulp_ctx.call(self.IMPORT_ALL_ID, parameters={self.HREF: href}, body=body)

    def import_commits(
        self,
        href: str,
        artifact: str,
        repository_name: str,
        ref: Optional[str] = None,
        parent_commit: Optional[str] = None,
    ) -> Any:
        body: Dict[str, Any] = {
            "artifact": artifact,
            "repository_name": repository_name,
        }

        if ref is not None:
            body["ref"] = ref
        if parent_commit is not None:
            body["parent_commit"] = parent_commit

        return self.pulp_ctx.call(
            self.IMPORT_COMMITS_ID,
            parameters={self.HREF: href},
            body=body,
        )
