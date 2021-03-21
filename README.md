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
  - Run `bundle update` in the terminal.
  - Use `bundle install`

- For `start` in `glitch.json` either:

  - Create a `config.ru` and use a `rackup` command, or
  - Run any command after `bundle exec`

## Ruby on Rails:

To use modern rails you will need a Boosted server to deal with the filesystem usage.
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
- Create a new rails app. (We pass `--skip-javascript` because otherwise it will expect `node`):

```
rails new app_name --skip-javascript
```

- Put `cd /app/app_name; bin/rails server` in `start` in your `glitch.json`
