## Running inside Molt Code

In Molt Code, `cua-driver` on PATH is a Molt launcher. Molt runs the driver
daemon embedded in the app, so do not run `serve`, `stop`, `update`, `skills`
or `permissions grant`; the launcher refuses them. Use the CLI subcommands
(`status`, `doctor`, `list-tools`, `describe`, `call`) as documented below.

If `check_permissions` reports Accessibility or Screen Recording missing, ask
the user to grant them in Molt Code under Plugins > Computer Use (Cua). Do not
open System Settings yourself.
