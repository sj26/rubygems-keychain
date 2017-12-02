# Rubygems Keychain

Store Rubygems credentials and signing certificates securely in your macOS Keychain. Works with iCloud Keychain.

**Warning: This gem is in active development and should not yet be considered stable**

## Installation

Install with Rubygems:

```
gem install rubygems-keychain
```

## Usage

This gem overrides the default api key get and set methods in Rubygems so should work transparently with all commands. For example:

```
$ gem owner mailcatcher
Enter your RubyGems.org credentials.
Don't have an account yet? Create one at https://rubygems.org/sign_up
   Email:   sj26@sj26.com
Password:   ********

Signed in.
Owners for gem: mailcatcher
- sj26@sj26.com
```

You can import your existing credentials using:

```
gem keychain import
```

Then you should be able to remove `~/.gem/credentials` (but _keep a backup_) and still be able to use authenticated commands like `push` and `yank` with your gems. It works across multiple hosts and will respect `-k` arguments.

## TODO

- More key management (add, list, rm)
- Certificate management for signing gems

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Test rubygems plugin integration with `bundle exec gem ...` which will load the plugin from the current directory.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

The helper tool is written in Swift and needs to be code signed correctly for iCloud Keychain to work. At the moment this is only possible by the primary author.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sj26/rubygems-keychain.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
