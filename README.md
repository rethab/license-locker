[![Build Status](https://travis-ci.org/rethab/license-locker.svg?branch=master)](https://travis-ci.org/rethab/license-locker)

# license locker
Lock files are common for dependencies. But how do we make sure we are only using libraries that have compatible licenses?
The idea of the license locker is to generate lock files, which are basically a list of libraries and their licenses, and have some periodic check (eg. integrated into CI) to make sure no unwanted dependency with an incompatible license sneaked in.

## Usage
Generate lock file:
```bash
./license-locker.sh --generate
```

Check whether lock file is up to date:
```bash
./license-locker.sh --check
```

## Options
- `--packager` package manager. This option is optional and if not specified, this script tries to guess. Currently supported: `npm` (via [license-checker](https://github.com/davglass/license-checker)) and `cargo` (via [cargo-license](https://github.com/onur/cargo-license))


## Typical workflow
### Initial Setup
- generate lock file and commit it to the version control system
### When adding a new dependency
- generate lock file (will be overwritten) and commit update to version control system
### Periodically
- run `--check` to make sure nobody forgot to update the lock file


# Contributions
Contributions are very welcome. When making a pull request, please make sure the script passes all checks from [shellcheck](https://github.com/koalaman/shellcheck).
