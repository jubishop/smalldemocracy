# A Modern Ruby Environment

## This project includes:

- Ruby 3
- A fully updated `gem` and `bundler`
- A `.gemrc` with `gem: --no-document` to save space.
- Symlinks from `bin/` to all the new binaries in `.rbenv` so they can actually be used.
- An `fs` command to show filesizes. (This setup is already 86 megabytes..)

## Next steps:

From here you can work in a modern ruby development environment:

- For `install` in `glitch.json`:

  - Create a `Gemfile`
  - Run `bundle update`
  - Set `install` to `bundle install`

- For `start` in `glitch.json` either:

  - Create a `config.ru` and use a `rackup` or
  - Run any command after `bundle exec`

## Ruby on Rails:

Using modern rails is tricky, you will need a Boosted because by default you need `node`.
However you can get around this with the `--skip-javascript` option.
Here's the steps to set this up from here:

- Install rails:

```
gem install rails
```

- Symlink your gem binaries (which now includes rails) into `bin/`:

```
ln -s /app/.local/gems/bin/* bin
```

- Close your terminal and open a new one.
- Create a new rails app, plugging in any name for `<app_name>`:

```
rails new <app_name> --skip-javascript
```

- Put `bin/rails server`
