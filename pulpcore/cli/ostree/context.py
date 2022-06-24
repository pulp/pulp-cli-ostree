from gettext import gettext as _
from typing import Any, ClassVar, Dict, Optional

from pulpcore.cli.common.context import (
    EntityDefinition,
    PluginRequirement,
    PulpContentContext,
    PulpEntityContext,
    PulpRemoteContext,
    PulpRepositoryContext,
    PulpRepositoryVersionContext,
    registered_repository_contexts,
)


class PulpOstreeCommitContentContext(PulpContentContext):
    ENTITY = _("commit content")
    ENTITIES = _("commit content")
    HREF = "ostree_ostree_commit_href"
    LIST_ID = "content_ostree_commits_list"
    READ_ID = "content_ostree_commits_read"


class PulpOstreeRefContentContext(PulpContentContext):
    ENTITY = _("ref content")
    ENTITIES = _("ref content")
    HREF = "ostree_ostree_ref_href"
    LIST_ID = "content_ostree_refs_list"
    READ_ID = "content_ostree_refs_read"


class PulpOstreeConfigContentContext(PulpContentContext):
    ENTITY = _("config content")
    ENTITIES = _("config content")
    HREF = "ostree_ostree_config_href"
    LIST_ID = "content_ostree_configs_list"
    READ_ID = "content_ostree_configs_read"


class PulpOstreeDistributionContext(PulpEntityContext):
    ENTITY = _("ostree distribution")
    ENTITIES = _("ostree distributions")
    HREF = "ostree_ostree_distribution_href"
    LIST_ID = "distributions_ostree_ostree_list"
    READ_ID = "distributions_ostree_ostree_read"
    CREATE_ID = "distributions_ostree_ostree_create"
    UPDATE_ID = "distributions_ostree_ostree_partial_update"
    DELETE_ID = "distributions_ostree_ostree_delete"

    def preprocess_body(self, body: EntityDefinition) -> EntityDefinition:
        body = super().preprocess_body(body)
        version = body.pop("version", None)
        if version is not None:
            repository_href = body.pop("repository")
            body["repository_version"] = f"{repository_href}versions/{version}/"
        return body


class PulpOstreeRemoteContext(PulpRemoteContext):
    ENTITY = _("ostree remote")
    ENTITIES = _("ostree remotes")
    HREF = "ostree_ostree_remote_href"
    LIST_ID = "remotes_ostree_ostree_list"
    CREATE_ID = "remotes_ostree_ostree_create"
    READ_ID = "remotes_ostree_ostree_read"
    UPDATE_ID = "remotes_ostree_ostree_partial_update"
    DELETE_ID = "remotes_ostree_ostree_delete"

    def preprocess_body(self, body: EntityDefinition) -> EntityDefinition:
        body = super().preprocess_body(body)
        if body and not self.pulp_ctx.has_plugin(PluginRequirement("ostree", min="2.0.0a6.dev")):
            include_refs = body.pop("include_refs")
            exclude_refs = body.pop("exclude_refs")
            if any((include_refs, exclude_refs)):
                self.pulp_ctx.needs_plugin(
                    PluginRequirement(
                        "ostree", min="2.0.0a6.dev", feature="including/excluding refs"
                    )
                )

        return body


class PulpOstreeRepositoryVersionContext(PulpRepositoryVersionContext):
    HREF = "ostree_ostree_repository_version_href"
    LIST_ID = "repositories_ostree_ostree_versions_list"
    READ_ID = "repositories_ostree_ostree_versions_read"
    DELETE_ID = "repositories_ostree_ostree_versions_delete"
    REPAIR_ID = "repositories_ostree_ostree_versions_repair"


class PulpOstreeRepositoryContext(PulpRepositoryContext):
    HREF = "ostree_ostree_repository_href"
    LIST_ID = "repositories_ostree_ostree_list"
    READ_ID = "repositories_ostree_ostree_read"
    CREATE_ID = "repositories_ostree_ostree_create"
    UPDATE_ID = "repositories_ostree_ostree_partial_update"
    DELETE_ID = "repositories_ostree_ostree_delete"
    SYNC_ID = "repositories_ostree_ostree_sync"
    MODIFY_ID = "repositories_ostree_ostree_modify"
    IMPORT_ALL_ID: ClassVar[str] = "repositories_ostree_ostree_import_all"
    IMPORT_COMMITS_ID: ClassVar[str] = "repositories_ostree_ostree_import_commits"
    VERSION_CONTEXT = PulpOstreeRepositoryVersionContext
    CAPABILITIES = {
        "sync": [PluginRequirement("ostree")],
        "import_all": [PluginRequirement("ostree", min="2.0.0a6.dev")],
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


registered_repository_contexts["ostree:ostree"] = PulpOstreeRepositoryContext
