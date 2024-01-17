<div align="center"> 
  <h1> GiveawayActionModule 🍀</h1>
  <p> Project created as part of the <a href="https://ethglobal.com/events/lfgho">LFGHO</a> Hackathon
  </p>
</div>

# Abstract

The GiveawayActionModule is a Lens Protocol Open Action Module that allows Lens users to easily create giveway on Lens.

# GiveawayActionModule

- When a user, let's say an influencer, create a Giveaway Lens Post, he will set:
  - The ERC-20 token he wants to giveaway
  - The amount of tokens
- Once the publication posted, influencer followers can now enter the giveway by running the open action: it will register them to the giveaway only if they follow the influencer
- Finaly, when the influencer wants, he can in turn run the openaction and it will:
  - Choose randomly one of the registrants (using [chainlinkVRF](https://docs.chain.link/vrf))
  - Send the tokens to the winner

# Tests

Tests must be run on mumbai testnet:

```bash
forge test -vv --fork-url wss://polygon-mumbai-bor.publicnode.com
```

# Contact

[![Twitter Follow](https://img.shields.io/twitter/follow/0xMartinGbz?style=social)](https://twitter.com/0xMartinGbz)
