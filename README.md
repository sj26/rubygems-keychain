# Rubygems Keychain

[![Gem Version](https://badge.fury.io/rb/rubygems-keychain.svg)](https://badge.fury.io/rb/rubygems-keychain)

Store Rubygems api keys and signing certificates securely in your macOS Keychain. Works with iCloud Keychain.

**Warning: This gem is in active development and should not yet be considered stable**

## Installation

Install with Rubygems:

```
gem install rubygems-keychain --pre
```

Now you probably want to import your existing api keys:

```
gem keychain import
```

When you're ready, securely remove the old credentials file:

```
rm -P ~/.gem/credentials
```

You can always find your API key again [on your rubygems.org profile](https://rubygems.org/profile/edit).

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

$ stat ~/.gem/credentials
stat: /Users/sj26/.gem/credentials: stat: No such file or directory
```

### Import

You can import existing api keys from your credentials file using:

```
$ gem keychain import
Importing api keys from /Users/sj26/.gem/credentials:
 - rubygems (rubygems.org)
 - foo
 - https://gems.example.com
```

Optionally specify the path to a credentials file:

```
$ gem keychain import ~/Dropbox/.gem/credentials
Importing api keys from /Users/sj26/Dropbox/.gem/credentials:
 - ...
```

### List

List the api keys stored in the Keychain by name/host:

```
$ gem keychain list
- rubygems (https://rubygems.org)
- foo
- https://gems.example.com
```

This will never output the actual keys, just their names.

### Add

Add new api keys using `gem keychain add`:

```
$ gem keychain add
Name/host:  foo
API Key:  🔑
INFO:  Successfully added key for 'foo'
```

You can specify the name and optionally the key on the command line if you like, but that is less secure:

```
$ gem keychain add foo abc123
INFO:  Successfully added key for 'foo'
```

To add an api key for rubygems.org use `rubygems` as the name.

### Remove

Remove api keys using `gem keychain rm`:

```
$ gem keychain rm
Which api key do you want to remove?
 1. rubygems (rubygems.org)
 2. foo
> 2
Are you sure you want to remove the api key 'foo'? [yN]  y
INFO:  Successfully removed api key 'foo'
```

You can specify the api key name on the command line, and force removal if you wish:

```
$ gem keychain rm --force foo
INFO:  Successfully removed api key 'foo'
```

## Coming Soon

- Certificate management for signing gems

## Known Issues

- Bundler's [gem tasks](http://bundler.io/v1.12/guides/creating_gem.html#releasing-the-gem) require a `~/.gem/credentials` file to exist:

  https://github.com/bundler/bundler/blob/5e49f422b69df8fc5a0c0c06cb1adfc167212b5d/lib/bundler/gem_helper.rb#L104

  Workaround: `echo "{}" > ~/.gem/credentials`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Test rubygems plugin integration with `bundle exec gem ...` which will load the plugin from the current directory.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

The helper tool is written in Swift and needs to be code signed correctly for iCloud Keychain to work. At the moment this is only possible by the primary author.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sj26/rubygems-keychain.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
