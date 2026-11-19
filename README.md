# bookorbit

A Nix flake that provides [BookOrbit](https://github.com/bookorbit/bookorbit), a self-hosted library management and reading platform, as a runnable server.

## Outputs

| Attribute            | What you get                                                                                                                                                                                                                                     |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `packages.bookorbit` | `bin/bookorbit`, the application server; `bin/bookorbit-migrate`, which runs the schema migrations; and `lib/bookorbit/`, the runtime tree the server runs from, including the KOReader plugin whose path is exported as `KOREADER_PLUGIN_PATH`. |
| `packages.default`   | The same package.                                                                                                                                                                                                                                |

Both are published for `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. The prebuilt `kepubify` binaries the runtime tree carries cover each of those, and the package picks the one matching its system.

```sh
nix run .#bookorbit
nix build .#bookorbit
```

## Notes

- Node sizes the old-space heap on every start from the smaller of the machine's memory and the container's cgroup memory limit, so a memory-limited container needs no extra configuration. Set `NODE_OPTIONS=--max-old-space-size=<MiB>` to pin the heap, or `--max-old-space-size-percentage=<N>` to choose the fraction of that limit.
- Kobo metadata fetching delegates to a Python helper. The launcher exports `KOBO_CLOUDSCRAPER_PYTHON` pointing at an interpreter that already carries the Cloudflare-handling module, so the Kobo provider works with no Python on the host.
- `ffmpeg` and poppler's utilities are placed on `PATH` by the launcher for media and ebook conversion.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
