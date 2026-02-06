# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.3] - 2026-02-06

### Added
- Add Ruby 3.2 to the test matrix [#7](https://github.com/nebulab/omnes/pull/7).
- Add benchmark and `ostruct` dependencies [#11](https://github.com/nebulab/omnes/pull/11).

### Changed
- Update Ruby versions under test (Ruby 4 compatibility) [#11](https://github.com/nebulab/omnes/pull/11).
- Stop supporting old Rubies [#9](https://github.com/nebulab/omnes/pull/9).

### Fixed
- Fix RuboCop linting violation [#12](https://github.com/nebulab/omnes/pull/12).
- Fix Style/RedundantConstantBase violations [#7](https://github.com/nebulab/omnes/pull/7).
- Correct README example [#8](https://github.com/nebulab/omnes/pull/8).

## [0.2.2] - 2022-05-03

### Added
- Support Ruby 2.5 & 2.6 [#6](https://github.com/nebulab/omnes/pull/6).

## [0.2.1] - 2022-04-19

### Added
- Added `Omnes::Bus#clear` for autoloading [#4](https://github.com/nebulab/omnes/pull/4).

### Changed
- Fix re-adding autodiscovered subscriptions on subsequent calls [#5](https://github.com/nebulab/omnes/pull/5).

## [0.2.0] - 2022-04-15

### Added
- Be able to fetch subscriptions by id from the bus [#1](https://github.com/nebulab/omnes/pull/1).
- Use ad-hoc configuration system (and make Omnes zero-deps) [#2](https://github.com/nebulab/omnes/pull/2).
- Bind a publication context to subscriptions [#3](https://github.com/nebulab/omnes/pull/3).

## [0.1.0] - 2022-03-23

[Unreleased]: https://github.com/nebulab/omnes/compare/v0.2.3...HEAD
[0.2.3]: https://github.com/nebulab/omnes/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/nebulab/omnes/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/nebulab/omnes/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/nebulab/omnes/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/nebulab/omnes/releases/tag/v0.1.0
