# setup-ruby

This action downloads a prebuilt ruby and adds it to the `PATH`.

It is very efficient and takes about 5 seconds to download, extract and add the given Ruby to the `PATH`.
No extra packages need to be installed.

**Important:** Prefer `ruby/setup-ruby@v1`.
If you pin to a commit or release, only the Ruby versions available at the time of the commit
will be available, and you will need to update it to use newer Ruby versions, see [Versioning](#versioning).

### Supported Versions

This action currently supports these versions of MRI, JRuby and TruffleRuby:

| Interpreter | Versions |
| ----------- | -------- |
| `ruby` | 1.9.3, 2.0.0, 2.1.9, 2.2, all versions from 2.3.0 until 3.3.0-preview2, head, debug, mingw, mswin, ucrt |
| `jruby` | 9.1.17.0 - 9.4.3.0, head |
| `truffleruby` | 19.3.0 - 23.1.0, head |
| `truffleruby+graalvm` | 21.2.0 - 23.1.0, head |

`ruby-debug` is the same as `ruby-head` but with assertions enabled (`-DRUBY_DEBUG=1`).  

Regarding Windows ruby master builds, `mingw` is a MSYS2/MinGW build, `head` & `ucrt` are MSYS2/UCRT64
builds, and `mswin` is a MSVC/VS 2022 build.

Preview and RC versions of Ruby might be available too on Ubuntu and macOS (not on Windows).
However, it is recommended to test against `ruby-head` rather than previews,
as it provides more useful feedback for the Ruby core team and for upcoming changes.

Only release versions published by [RubyInstaller](https://rubyinstaller.org/downloads/archives/)
are available on Windows.  Due to that, Ruby 2.2 resolves to 2.2.6 on Windows and 2.2.10
on other platforms. Ruby 2.3 on Windows only has builds for 2.3.0, 2.3.1 and 2.3.3.

Note that Ruby ≤ 2.4 and the OpenSSL version it needs (1.0.2) are both end-of-life,
which means Ruby ≤ 2.4 is unmaintained and considered insecure.

### Supported Platforms

The action works on these [GitHub-hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources) images. Runner images not listed below are not supported yet. `$OS-latest` just alias to one of these images.

| Operating System | Supported |
| ---------------- | --------- |
| Ubuntu  | `ubuntu-20.04`, `ubuntu-22.04` |
| macOS   | `macos-11`, `macos-12`, `macos-13`, `macos-14` |
| Windows | `windows-2019`, `windows-2022` |

The prebuilt releases are generated by [ruby-builder](https://github.com/ruby/ruby-builder)
and on Windows by [RubyInstaller2](https://github.com/oneclick/rubyinstaller2).
The `mingw`, `ucrt` and `mswin` builds are generated by [ruby-loco](https://github.com/MSP-Greg/ruby-loco).
`ruby-head` is generated by [ruby-dev-builder](https://github.com/ruby/ruby-dev-builder),
`jruby-head` is generated by [jruby-dev-builder](https://github.com/ruby/jruby-dev-builder),
`truffleruby-head` is generated by [truffleruby-dev-builder](https://github.com/ruby/truffleruby-dev-builder)
and `truffleruby+graalvm` is generated by [graalvm-ce-dev-builds](https://github.com/graalvm/graalvm-ce-dev-builds).
The full list of available Ruby versions can be seen in [ruby-builder-versions.json](ruby-builder-versions.json)
for Ubuntu and macOS and in [windows-versions.json](windows-versions.json) for Windows.

## Usage

### Single Job

```yaml
name: My workflow
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.2' # Not needed with a .ruby-version file
        bundler-cache: true # runs 'bundle install' and caches installed gems automatically
    - run: bundle exec rake
```

### Matrix of Ruby Versions

This matrix tests all stable releases and `head` versions of MRI, JRuby and TruffleRuby on Ubuntu and macOS.

```yaml
name: My workflow
on: [push, pull_request]
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
        # Due to https://github.com/actions/runner/issues/849, we have to use quotes for '3.0'
        ruby: ['2.7', '3.0', '3.1', '3.2', head, jruby, jruby-head, truffleruby, truffleruby-head]
    runs-on: ${{ matrix.os }}
    steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{ matrix.ruby }}
        bundler-cache: true # runs 'bundle install' and caches installed gems automatically
    - run: bundle exec rake
```

### Matrix of Gemfiles

```yaml
name: My workflow
on: [push, pull_request]
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        gemfile: [ rails5, rails6 ]
    runs-on: ubuntu-latest
    env: # $BUNDLE_GEMFILE must be set at the job level, so it is set for all steps
      BUNDLE_GEMFILE: ${{ github.workspace }}/gemfiles/${{ matrix.gemfile }}.gemfile
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true # runs 'bundle install' and caches installed gems automatically
      - run: bundle exec rake
```

See the GitHub Actions documentation for more details about the
[workflow syntax](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions)
and the [condition and expression syntax](https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions).

### Supported Version Syntax

* engine-version like `ruby-2.6.5` and `truffleruby-19.3.0`
* short version like `'2.6'`, automatically using the latest release matching that version (`2.6.10`)
* version only like `'2.6.5'`, assumes MRI for the engine
* engine only like `ruby` and `truffleruby`, uses the latest stable release of that implementation
* `.ruby-version` reads from the project's `.ruby-version` file
* `.tool-versions` reads from the project's `.tool-versions` file
* If the `ruby-version` input is not specified, `.ruby-version` is tried first, followed by `.tool-versions`

### Working Directory

The `working-directory` input can be set to resolve `.ruby-version`, `.tool-versions` and `Gemfile.lock`
if they are not at the root of the repository, see [action.yml](action.yml) for details.

### RubyGems

By default, the default RubyGems version that comes with each Ruby is used.
However, users can optionally customize the RubyGems version that they want by
setting the `rubygems` input.

See [action.yml](action.yml) for more details about the `rubygems` input.

If you're running into `ArgumentError: wrong number of arguments (given 4,
expected 1)` errors with a stacktrace including Psych and RubyGems entries, you
should be able to fix them by setting `rubygems: 3.0.0` or higher.

### Bundler

By default, Bundler is installed as follows:

* If there is a `Gemfile.lock` file (or `$BUNDLE_GEMFILE.lock` or `gems.locked`) with a `BUNDLED WITH` section,
  that version of Bundler will be installed and used.
* If the Ruby ships with Bundler 2.2+ (as a default gem), that version is used.
* Otherwise, the latest compatible Bundler version is installed (Bundler 2 on Ruby >= 2.3, Bundler 1 on Ruby < 2.3).

This behavior can be customized, see [action.yml](action.yml) for more details about the `bundler` input.

### Caching `bundle install` automatically

This action provides a way to automatically run `bundle install` and cache the result:
```yaml
    - uses: ruby/setup-ruby@v1
      with:
        bundler-cache: true
```

Note that any step doing `bundle install` (for the root `Gemfile`) or `gem install bundler` can be removed with `bundler-cache: true`.

This caching speeds up installing gems significantly and avoids too many requests to RubyGems.org.  
It needs a `Gemfile` (or `$BUNDLE_GEMFILE` or `gems.rb`) under the [`working-directory`](#working-directory).  
If there is a `Gemfile.lock` (or `$BUNDLE_GEMFILE.lock` or `gems.locked`), `bundle config --local deployment true` is used.

To use a `Gemfile` which is not at the root or has a different name, set `BUNDLE_GEMFILE` in the `env` at the job level
as shown in the [example](#matrix-of-gemfiles).

#### bundle config

When using `bundler-cache: true` you might notice there is no good place to run `bundle config ...` commands.
These can be replaced by `BUNDLE_*` environment variables, which are also faster.
They should be set in the `env` at the job level as shown in the [example](#matrix-of-gemfiles).
To find the correct the environment variable name, see the [Bundler docs](https://bundler.io/man/bundle-config.1.html) or look at `.bundle/config` after running `bundle config --local KEY VALUE` locally.
You might need to `"`-quote the environment variable name in YAML if it has unusual characters like `/`.

To perform caching, this action will use `bundle config --local path $PWD/vendor/bundle`.  
Therefore, the Bundler `path` should not be changed in your workflow for the cache to work (no `bundle config path`).

#### How it Works

When there is no lockfile, one is generated with `bundle lock`, which is the same as `bundle install` would do first before actually fetching any gem.
In other words, it works exactly like `bundle install`.
The hash of the generated lockfile is then used for caching, which is the only correct approach.

#### Dealing with a corrupted cache

In some rare scenarios (like using gems with C extensions whose functionality depends on libraries found on the system
at the time of the gem's build) it may be necessary to ignore contents of the cache and get and build all the gems anew.
In order to achieve this, set the `cache-version` option to any value other than `0` (or change it to a new unique value
if you have already used it before.)

```yaml
    - uses: ruby/setup-ruby@v1
      with:
        bundler-cache: true
        cache-version: 1
```

#### Caching `bundle install` manually

It is also possible to cache gems manually, but this is not recommended because it is verbose and *very difficult* to do correctly.
There are many concerns which means using `actions/cache` is never enough for caching gems (e.g., incomplete cache key, cleaning old gems when restoring from another key, correctly hashing the lockfile if not checked in, OS versions, ABI compatibility for `ruby-head`, etc).
So, please use `bundler-cache: true` instead and report any issue.

## Windows

Note that running CI on Windows can be quite challenging if you are not very familiar with Windows.
It is recommended to first get your build working on Ubuntu and macOS before trying Windows.

* Use Bundler 2.2.18+ on Windows (older versions have [bugs](https://github.com/ruby/setup-ruby/issues/209#issuecomment-889064123)) by not setting the `bundler:` input and ensuring there is no `BUNDLED WITH 1.x.y` in a checked-in `Gemfile.lock`.
* The default shell on Windows is not Bash but [PowerShell](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#using-a-specific-shell).
  This can lead issues such as multi-line scripts [not working as expected](https://github.com/ruby/setup-ruby/issues/13).
* The `PATH` contains [multiple compiler toolchains](https://github.com/ruby/setup-ruby/issues/19). Use `where.exe` to debug which tool is used.
* For Ruby ≥ 2.4, MSYS2 is prepended to the `Path`, similar to what RubyInstaller2 does.
* For Ruby < 2.4, the DevKit MSYS tools are installed and prepended to the `Path`.
* Use JRuby 9.2.20+ on Windows (older versions have [bugs](https://github.com/ruby/setup-ruby/issues/18#issuecomment-889072695)).
* JRuby on Windows has multiple issues ([jruby/jruby#7106](https://github.com/jruby/jruby/issues/7106), [jruby/jruby#7182](https://github.com/jruby/jruby/issues/7182)).

## Versioning

It is highly recommended to use `ruby/setup-ruby@v1` for the version of this action.
This will provide the best experience by automatically getting bug fixes, new Ruby versions and new features.

If you instead choose a specific version (v1.2.3) or a commit sha, there will be no automatic bug fixes and
it will be your responsibility to update every time the action no longer works.
Make sure to always use the latest release before reporting an issue on GitHub.

This action follows semantic versioning with a moving `v1` branch.
This follows the [recommendations](https://github.com/actions/toolkit/blob/master/docs/action-versioning.md) of GitHub Actions.

## Using self-hosted runners

This action might work with [self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
if the [Runner Image](https://github.com/actions/runner-images) is very similar to the ones used by GitHub runners. Notably:

* Make sure to use the same operating system and version.
* Make sure to use the same version of libssl.
* Make sure that the operating system has `libyaml-0` and [`libgmp`](https://stackoverflow.com/questions/26555902/ruby-v-dyld-library-not-loaded-usr-local-lib-libgmp-10-dylib) installed
* The default tool cache directory (`/opt/hostedtoolcache` on Linux, `/Users/runner/hostedtoolcache` on macOS,
  `C:/hostedtoolcache/windows` on Windows) must be writable by the `runner` user.
  This is necessary since the Ruby builds embed the install path when built and cannot be moved around.
* `/home/runner` must be writable by the `runner` user.

In other cases, you will need to install Ruby in the runner tool cache as shown by the action when it detects that case
(run it so it will show you where to install Ruby).
You could of course also not use this action and e.g. use Ruby from a system package or use a Docker image instead.

## History

This action used to be at `eregon/use-ruby-action` and was moved to the `ruby` organization.
Please [update](https://github.com/ruby/setup-ruby/releases/tag/v1.13.0) if you are using `eregon/use-ruby-action`.

## Credits

The current maintainer of this action is @eregon.
Most of the Windows logic is based on work by MSP-Greg.
Many thanks to MSP-Greg and Lars Kanis for the help with Ruby Installer.
