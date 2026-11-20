# bookorbit

A Nix flake that provides [BookOrbit](https://github.com/bookorbit/bookorbit), a self-hosted library management and reading platform, as a runnable server.

## Outputs

| Attribute            | What you get                                                                                                                                                                                                                                    |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages.bookorbit` | `bin/bookorbit`: the application server. `bin/bookorbit-migrate`: runs the schema migrations. `lib/bookorbit/`: the runtime tree the server runs from. The tree includes the KOReader plugin, whose path is exported as `KOREADER_PLUGIN_PATH`. |
| `packages.default`   | The same package.                                                                                                                                                                                                                               |

The flake publishes both for `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. The runtime tree carries a prebuilt `kepubify` binary for each of those, and the package picks the one matching its system.

```sh
nix run .#bookorbit
nix build .#bookorbit
```

## Notes

- Node sizes the old-space heap on every start. It takes the smaller of the machine's memory and the container's cgroup memory limit, so a memory-limited container needs no extra configuration. Set `NODE_OPTIONS=--max-old-space-size=<MiB>` to pin the heap, or `--max-old-space-size-percentage=<N>` to choose the fraction of that limit.
- The Kobo provider fetches its metadata through a Python helper. The launcher exports `KOBO_CLOUDSCRAPER_PYTHON` pointing at an interpreter that already carries the Cloudflare-handling module, so the Kobo provider works with no Python on the host.
- The launcher puts `ffmpeg` and poppler's utilities on `PATH` for media and ebook conversion.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
