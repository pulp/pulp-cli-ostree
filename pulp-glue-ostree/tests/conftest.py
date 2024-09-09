from pulp_glue.common.context import PulpContext


class PulpTestContext(PulpContext):
    # TODO check if we can just make the base class ignore echo.
    def echo(*args, **kwargs) -> None:
        return
