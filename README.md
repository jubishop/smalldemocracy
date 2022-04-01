# Small Democracy

[![RSpec Status][rspec-badge]][rspec-yml]  [![Rubocop Status][rubocop-badge]][rubocop-yml]

## Tools for a Small Democracy

Small Democracy can be viewed online at [smalldemocracy.com][small-democracy].

## Polls

Small Democracy currently supports:

- Ranked Choice Voting ([Borda Count][borda-count]).
- Choose One.

## Developing Small Democracy

### Basic Setup

1. Install two local postgres databases:

   ```shell
   createdb smalldemocracy_test
   createdb smalldemocracy_dev
   ```

1. From the root directory of your copy of `smalldemocracy`:

    ```shell
    bundle install
    bundle exec rake db:migrate
    ```

    This will install all necessary dependencies and migrate the schema for the `smalldemocracy_dev` database.  `smalldemocracy_test` will be automatically set up and torn down during each test run.

### Launching SmallDemocracy

1. From the root directory of your copy of `smalldemocracy`:

    ```shell
    bundle exec rake run
    ```

    You will now be able to load `smalldemocracy` at http://localhost:8989

### Testing SmallDemocracy

- To run all tests:

    ```shell
    bundle exec rake
    ```

- To run all tests except the slow UI tests:

    ```shell
    bundle exec rake fast
    ```

### Other Commands

To see everything you can do:

```shell
bundle exec rake --tasks
```

## License

This work is licensed under the [Fair Source License](https://fair.io) as [Fair Source 10][license].

<!-- Badge Shortcuts -->
[rspec-badge]: https://github.com/jubishop/smalldemocracy/workflows/RSpec/badge.svg
[rspec-yml]: https://github.com/jubishop/smalldemocracy/actions/workflows/rspec.yml
[rubocop-badge]: https://github.com/jubishop/smalldemocracy/workflows/Rubocop/badge.svg
[rubocop-yml]: https://github.com/jubishop/smalldemocracy/actions/workflows/rubocop.yml

<!-- Link Shortcuts -->
[license]: https://github.com/jubishop/smalldemocracy/blob/main/LICENSE.md
[small-democracy]: https://smalldemocracy.com
[borda-count]: https://en.wikipedia.org/wiki/Borda_count
