# Melody Vault 🎵

A decentralized music streaming royalty platform built on the Stacks blockchain with fan engagement tokens and on-chain reputation system.

## Overview

Melody Vault revolutionizes music streaming by creating a direct connection between artists and fans through blockchain technology. Artists earn royalties per stream while fans are rewarded with engagement tokens for their support. The platform features a comprehensive reputation system that builds trust and encourages positive behavior from all participants.

## Key Features

### 🎤 For Artists
- **Direct Royalty Payments**: Set custom per-stream rates and receive payments instantly
- **Transparent Earnings**: All transactions are recorded on-chain for complete transparency
- **Reputation Building**: Earn reputation points through uploads, streams, and community engagement
- **Artist Verification**: Get verified status to build trust with fans
- **Analytics**: Track total streams, earnings, and fan engagement

### 👥 For Fans
- **Fan Engagement Tokens (FET)**: Earn tokens for every stream and interaction
- **Premium Features**: Use tokens to unlock exclusive content and features
- **Reputation System**: Build credibility through positive platform engagement
- **Artist Discovery**: Support emerging artists and build relationships
- **Transparent Support**: See exactly how your payments support artists

### ⭐ Reputation System
- **On-chain Scores**: Immutable reputation tracking for all users
- **Multiple Actions**: Earn points through various platform activities
- **Trust Building**: Higher reputation users gain platform benefits
- **Anti-Spam Protection**: Reputation requirements prevent malicious behavior

## Smart Contract Architecture

### Core Components

#### 1. Token System
- **Fan Engagement Token (FET)**: Fungible token for platform rewards
- **Automatic Minting**: Tokens earned through streaming and platform engagement
- **Utility Features**: Tokens used for premium features and exclusive content

#### 2. Data Structures

**Artists**
```clarity
{
    name: (string-ascii 50),
    total-earnings: uint,
    song-count: uint,
    reputation-score: uint,
    verified: bool,
    join-date: uint
}
```

**Songs**
```clarity
{
    title: (string-ascii 100),
    artist: principal,
    royalty-rate: uint,
    total-streams: uint,
    total-earnings: uint,
    upload-date: uint,
    active: bool
}
```

**Fans**
```clarity
{
    name: (string-ascii 50),
    total-spent: uint,
    fan-tokens: uint,
    reputation-score: uint,
    favorite-genre: (string-ascii 30),
    join-date: uint
}
```

## Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for transactions
- Clarinet for local development

### Installation

1. Clone the repository
```bash
git clone https://github.com/your-username/melody-vault
cd melody-vault
```

2. Install Clarinet
```bash
# Install Clarinet
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install clarinet-cli
```

3. Check the contract
```bash
clarinet check
```

4. Run tests
```bash
clarinet test
```

### Deployment

1. Deploy to testnet
```bash
clarinet deploy --testnet
```

2. Deploy to mainnet
```bash
clarinet deploy --mainnet
```

## Usage Guide

### For Artists

#### 1. Register as an Artist
```clarity
(contract-call? .melody-vault register-artist "Your Artist Name")
```

#### 2. Upload a Song
```clarity
(contract-call? .melody-vault upload-song "Song Title" u1000) ;; 0.001 STX per stream
```

#### 3. Track Your Earnings
```clarity
(contract-call? .melody-vault get-artist tx-sender)
```

### For Fans

#### 1. Register as a Fan
```clarity
(contract-call? .melody-vault register-fan "Your Name" "Pop")
```

#### 2. Stream a Song
```clarity
(contract-call? .melody-vault stream-song u1) ;; Stream song with ID 1
```

#### 3. Use Fan Tokens
```clarity
(contract-call? .melody-vault use-fan-tokens u50 "Premium Feature Access")
```

## Function Reference

### Public Functions

#### Artist Functions
- `register-artist(name)` - Register as an artist
- `upload-song(title, royalty-rate)` - Upload a new song
- `deactivate-song(song-id)` - Deactivate a song

#### Fan Functions
- `register-fan(name, favorite-genre)` - Register as a fan
- `stream-song(song-id)` - Stream a song and pay royalties
- `use-fan-tokens(amount, purpose)` - Use tokens for premium features

#### Admin Functions
- `verify-artist(artist-address)` - Verify an artist (owner only)
- `set-platform-fee(new-fee)` - Set platform fee percentage (owner only)

### Read-Only Functions

- `get-artist(artist-address)` - Get artist information
- `get-fan(fan-address)` - Get fan information
- `get-song(song-id)` - Get song details
- `get-fan-tokens(user)` - Get user's token balance
- `get-reputation-score(user)` - Get user's reputation score
- `get-total-songs()` - Get total number of songs
- `get-platform-fee()` - Get current platform fee

## Reputation System

### Point Values

| Action | Points Earned |
|--------|---------------|
| Artist Registration | +10 |
| Fan Registration | +5 |
| Song Upload | +15 |
| Stream Song (Fan) | +1 |
| Receive Stream (Artist) | +2 |
| Token Usage | +amount/10 |
| Artist Verification | +50 |

### Reputation Benefits

- **High Reputation Artists**: Priority in discovery algorithms
- **Verified Status**: Available for artists with high reputation
- **Platform Trust**: Higher reputation users get platform benefits
- **Community Standing**: Visible reputation scores build trust

## Economics

### Revenue Model
- **Platform Fee**: Configurable percentage (default 10%)
- **Artist Royalties**: 90% of stream payments go directly to artists
- **Token Incentives**: Fans earn 1 FET per 100 micro-STX spent

### Token Utility
- **Premium Features**: Access exclusive content
- **Artist Support**: Enhanced interaction capabilities
- **Platform Governance**: Future voting rights (roadmap)
- **Staking Rewards**: Future yield opportunities (roadmap)

## Security Features

### Access Control
- **Owner-only functions**: Platform administration restricted
- **Artist verification**: Only contract owner can verify artists
- **Song ownership**: Only artists can deactivate their songs

### Data Integrity
- **Immutable records**: All streams and payments recorded permanently
- **Reputation tracking**: Anti-manipulation through on-chain verification
- **Balance checks**: Prevents insufficient balance transactions

### Error Handling
- Comprehensive error codes for all failure scenarios
- Input validation on all public functions
- Safe arithmetic operations prevent overflow

## Testing

Run the test suite:

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/melody-vault_test.ts
```

### Test Coverage
- Artist registration and song upload
- Fan registration and streaming
- Token minting and burning
- Reputation system accuracy
- Access control verification
- Error condition handling

## Roadmap

### Phase 1 (Current) ✅
- Core streaming functionality
- Basic reputation system
- Fan engagement tokens
- Artist verification

### Phase 2 (Q2 2024)
- Advanced analytics dashboard
- Playlist creation and sharing
- Enhanced fan-artist interactions
- Mobile app integration

### Phase 3 (Q3 2024)
- NFT album releases
- Governance token implementation
- Cross-chain compatibility
- Advanced monetization features

### Phase 4 (Q4 2024)
- AI-powered music recommendations
- Social features and communities
- Live streaming integration
- Metaverse concert hosting

## Contributing

We welcome contributions from the community! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting

## Support

### Documentation
- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity)
- [Smart Contract Tutorial](https://docs.stacks.co/build-apps/tutorials/clarity-hello-world)

### Community
- Discord: [Join our community](https://discord.gg/melody-vault)
- Twitter: [@MelodyVault](https://twitter.com/melodyvault)
- Telegram: [Melody Vault Community](https://t.me/melodyvault)

### Issues and Bugs
Please report issues on our [GitHub Issues](https://github.com/your-username/melody-vault/issues) page.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
