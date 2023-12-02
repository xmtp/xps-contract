## XMTP Postal Service (XPS) Inbox Contract

[![Test](https://github.com/xmtp/xps-contract/actions/workflows/ci-image.yml/badge.svg)](https://github.com/xmtp/xps-contract/actions/workflows/ci-image.yml)

This is the reference implementation of XMTP Postal Service (XPS) inbox contract.

## Quick Start (Development)

### Submodules

First, init submodules from the project root

```bash
$ git submodule update --recursive --init -f
```

### Dev Containers Development

This contract supports containerized development. From Visual Studio Code Dev Containers extension

`Reopen in Container`

or

Command line build using docker

```bash
$ docker build . -t xps-contract:1
```

## Testing the Contracts

From the containerized environment:

```bash
$ yarn install --frozen-lockfile
$ yarn prettier:check
$ yarn lint
$ forge test -vvv
```


### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
