# A Modern Ruby Environment

## This project includes:

- Ruby 3
- A fully updated `gem` and `bundler`
- A `.gemrc` with `gem: --no-document` to save space.
- Symlinks from `bin/` to all the new binaries in `.rbenv` so they can actually be used.
- An `fs` command to show filesizes.  (This setup is already 86 megabytes..)

## Next steps:

From here you can work in a modern ruby development environment:

- For `install` in `glitch.json`:
  - Create a `Gemfile`
  - Run `bundle update`
  - Set `install` to `bundle install`

- For `start` in `glitch.json` either:
  - Create a `config.ru` and use a `rackup` or
  - Run any command after `bundle exec`
  

## A note on rails:

- Note: Rails is still tricky, because by default you need a `node` command.
  - However `rails new <app_name> --skip-javascript` will work but f