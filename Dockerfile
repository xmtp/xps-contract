FROM ghcr.io/xmtp/foundry:latest

ARG PROJECT=xps-contract
WORKDIR /workspaces/${PROJECT}

RUN chown -R xmtp:xmtp /workspaces
COPY --chown=xmtp:xmtp . .

# build and test
RUN yarn install --frozen-lockfile
RUN yarn prettier:check
RUN yarn lint
RUN forge test -v
RUN forge geiger --check contracts/*.sol
RUN forge coverage

USER xmtp
