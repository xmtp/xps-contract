## XMTP Postal Service (XPS) Inbox Contract

![XPS](xps.png)

[![Test](https://github.com/xmtp/xps-contract/actions/workflows/ci-image.yml/badge.svg)](https://github.com/xmtp/xps-contract/actions/workflows/ci-image.yml)

This is the reference implementation of XMTP Postal Service (XPS) inbox contract.

## Quick Start (Development)

- [READ THE DOCS](https://xmtp.github.io/xps-contract)
- [CONTRIBUTING](CONTRIBUTING.md)

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

## TestNet Deployment

| Contract     | Ethereum Address                           | Network                                                                                                                                                      |
| ------------ | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Conversation | 0x15aE865d0645816d8EEAB0b7496fdd24227d1801 | [Sepolia](https://sepolia.etherscan.io/address/0x15aE865d0645816d8EEAB0b7496fdd24227d1801)                                                                   |
| Conversation | 0xAaCe07B4C163D2bCcA78237E1F863b6d20122762 | [Optimisim Sepolia](https://sepolia-optimism.etherscan.io/address/0xAaCe07B4C163D2bCcA78237E1F863b6d20122762)                                                |
| Conversation | 0x146Aa237567bEAa52C51570D2A2BC8150C63754B | @Deprecated [Optimism Görli](https://goerli-optimism.etherscan.io/address/0x146aa237567beaa52c51570d2a2bc8150c63754b)                                        |
| Conversation | 0x34FE4677E581A57E9F9fe74948B0AbC8A4056f3F | [XMTP Sepolia Arbitrum L3](https://explorerl2new-xmtp-l3-sepolia-arbitrum-anytr-x1nwrvmveu.t.conduit.xyz/address/0x34FE4677E581A57E9F9fe74948B0AbC8A4056f3F) |

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Getting Started

`xps-contract` implementations may consist of up to three separate workflows, catching up, following and sending.

#### Catching up

Catching up involves querying the Ethereum log for existing message events. The expected log event is the 'PayloadSent'.

```rust
   pub async fn rewind(&self, conversation: &String, n: u32) -> Result<Vec[String], Error> {
        let mut n = n;
        let conversation_id = to_conversation_id(conversation).unwrap();
        let last_change_result: Result<U256, _> =
            self.contract.last_message(conversation_id).call().await;
        tracing::info!("conversation_id: {}", hex::encode(conversation_id));
        if let Err(err) = last_change_result {
            tracing::error!("last change error: {:?}", err);
            return Err(anyhow::anyhow!("failed to get last change"));
        }
        let message = Vec::new();
        let mut last_change = last_change_result.unwrap();
        while last_change != U256::zero() {
            tracing::debug!("prev_change: {}", last_change);
            let conversation_topic = [H256::from(conversation_id)];
            let contract_addr = SENDER_CONTRACT.parse::<Address>().unwrap();
            let filter = Filter::new()
                .from_block(U64::from(last_change.as_u64()))
                .to_block(U64::from(last_change.as_u64()))
                .event("PayloadSent(bytes32,bytes,uint256)")
                .address(vec![contract_addr])
                .topic1(conversation_topic.to_vec());
            let logs = self.client.get_logs(&filter).await;
            if let Ok(logs) = logs {
                for log in logs.iter() {
                    if tracing::level_enabled!(tracing::Level::TRACE) {
                        tracing::trace!("log: {:?}", log);
                    }
                    let param_result = decode_payload_sent(log.data.to_vec());
                    if let Ok(param) = param_result {
                        tracing::debug!("param: {:?}", param);
                        let message = param[0].clone().into_string().unwrap();
                        if tracing::level_enabled!(tracing::Level::TRACE) {
                            tracing::trace!("message: {message}");
                        }
                        message.push(message);
                        last_change = param[1].clone().into_uint().unwrap();
                    } else {
                        let err = param_result.unwrap_err();
                        tracing::error!("param error: {:?}", err);
                        return Err(err);
                    }

                    n -= 1;
                    if n == 0 {
                        last_change = U256::zero();
                        break;
                    }
                }
            }
        }

        message.reverse();
        tracing::info!("{} messages found", rewind.message.len());
        Ok(rewind)
    }
```

```rust
    pub async fn follow_messages(
        &self,
        conversation: &String,
        start_block: &U256,
        callback: MessageCallback,
    ) -> Result<(), Error> {
        let conversation_id = to_conversation_id(conversation).unwrap();
        tracing::info!("conversation_id: {}", hex::encode(conversation_id));
        let conversation_topic = [H256::from(conversation_id)];
        let contract_addr = SENDER_CONTRACT.parse::<Address>().unwrap();
        let filter = Filter::new()
            .from_block(U64::from(start_block.as_u64()))
            .event("PayloadSent(bytes32,bytes,uint256)")
            .address(vec![contract_addr])
            .topic1(conversation_topic.to_vec());

        let mut stream = self.client.subscribe_logs(&filter).await.unwrap();
        while let Some(log) = stream.next().await {
            if tracing::level_enabled!(tracing::Level::TRACE) {
                tracing::trace!("log: {:?}", log);
            }
            let param_result = decode_payload_sent(log.data.to_vec());
            if let Ok(param) = param_result {
                tracing::debug!("param: {:?}", param);
                let message = param[0].clone().into_string().unwrap();
                tracing::trace!("message: {message}");
                callback(&message);
            } else {
                let err = param_result.unwrap_err();
                tracing::error!("param error: {:?}", err);
                return Err(err);
            }
        }
        Ok(())
    }
```

```rust
    pub async fn send_message(&self, conversation: &String, message: &String) -> Result<(), Error> {
        let conversation_id_result = to_conversation_id(conversation);
        if let Err(err) = conversation_id_result {
            tracing::error!("Conversation ID error: {:?}", err);
            return Err(anyhow::anyhow!("failed to get conversation ID"));
        }
        let conversation_id = conversation_id_result.unwrap();
        let message_bytes = Bytes::from(message.as_bytes().to_vec());
        let tx = self.contract.send_message(conversation_id, message_bytes);
        let receipt = tx
            .gas(GAS_LIMIT)
            .send()
            .await
            .unwrap()
            .confirmations(REQUIRED_CONFIRMATIONS)
            .await;
        if let Err(err) = receipt {
            tracing::error!("Transaction error: {:?}", err);
            return Err(anyhow::anyhow!("failed to send message"));
        }
        tracing::info!("Transaction receipt: {:?}", receipt);
        Ok(())
    }
```
