## XMTP Inbox

[![Test](https://github.com/xmtp/postal_service_contract/actions/workflows/ci-image.yml/badge.svg)](https://github.com/xmtp/postal_service_contract/actions/workflows/ci-image.yml)

This is the reference implementation of XMTP Inbox gateway contract.

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
$ docker build . -t postal_service_contract:1
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
