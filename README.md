# A Modern Ruby Environment

## This project includes:

- Ruby 3
- A fully updated `gem` and `bundler`
- A `.gemrc` with `gem: --no-document` to save space.
- Symlinks from `bin/` to all the new binaries in `.rbenv` so they can actually be used.
- An `fs` command to show filesizes.  This setup is already 86 megabytes..

## Next steps:

From here you can work in a modern ruby development environment:

- Add a `Gemfile` and/or `config.ru` file
- Set your `install` and `start` attributes in `glitch.json` to `bundle` or `rackup` commands.