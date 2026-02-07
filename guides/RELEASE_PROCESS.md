# Release Process

This project ships through Hex.pm and HexDocs.

## Recommended Commands

```bash
make preflight
make publish-interactive
```

For CI or non-interactive usage:

```bash
export HEX_API_KEY=...
make release
```

## Preflight Includes

- `mix deps.get`
- `mix format --check-formatted`
- `mix test`
- `mix docs`
- `mix hex.build`
- `mix hex.publish --dry-run --yes`

## Publishing Notes

- Interactive publish uses local Hex credentials.
- Non-interactive publish requires `HEX_API_KEY`.
- Keep `README.md`, guides, and module docs current before release.

## Suggested Release Steps

1. Update version in `mix.exs`.
2. Run `make preflight`.
3. Publish package and docs.
4. Create and push a Git tag matching the version.
5. Check package and docs pages after publication.
