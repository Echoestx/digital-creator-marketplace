# Digital Asset Studio - Creator Economy Platform

A decentralized marketplace for digital tools and services built on the Stacks blockchain using Clarity smart contracts.

## Overview

Digital Asset Studio is a creator economy platform that enables content creators to publish, monetize, and distribute digital assets through a decentralized marketplace. The platform supports both one-time purchases and subscription-based access models, with built-in rating systems and creator earnings management.

## Features

### For Creators
- **Asset Publishing**: Upload and list digital assets with customizable pricing
- **Multiple Pricing Models**: Support for both one-time purchases and recurring subscriptions
- **Tier-based Assets**: Organize content into basic, premium, and enterprise tiers
- **Earnings Management**: Track revenue and withdraw earnings directly to your wallet
- **Asset Analytics**: Monitor downloads, earnings, and user engagement
- **Content Control**: Update asset details and manage availability

### For Users
- **Flexible Licensing**: Choose between permanent licenses or monthly subscriptions
- **Access Control**: Secure access tracking for purchased content
- **Rating System**: Rate and review assets (1-5 stars with comments)
- **Usage Tracking**: Monitor your asset access and spending

### Platform Features
- **Decentralized**: Built on Stacks blockchain for transparency and security
- **Low Fees**: 3% platform commission (configurable by admin)
- **Immutable Records**: All transactions and ratings stored on-chain
- **Content Verification**: SHA-256 content hashing for integrity

## Smart Contract Functions

### Read-Only Functions

#### `get-asset (asset-key)`
Retrieve detailed information about a digital asset including creator, pricing, and metrics.

#### `get-license (owner, asset-key)`
Check license details for a specific user and asset, including type and validity.

#### `has-access (owner, asset-key)`
Verify if a user has valid access to an asset (either permanent or active subscription).

#### `get-creator-balance (creator)`
View current earnings balance for a creator.

### Public Functions

#### `publish-asset`
```clarity
(publish-asset asset-key title summary tier one-time-cost subscription-cost content-hash)
```
Publish a new digital asset to the marketplace.

**Parameters:**
- `asset-key`: Unique identifier (48 chars)
- `title`: Asset title (80 chars max)
- `summary`: Description (300 chars max)
- `tier`: "basic", "premium", or "enterprise"
- `one-time-cost`: Price for permanent license (in microSTX)
- `subscription-cost`: Monthly subscription price (in microSTX)
- `content-hash`: SHA-256 hash of the content (48 chars)

#### `buy-permanent-license (asset-key)`
Purchase permanent access to a digital asset with unlimited usage rights.

#### `subscribe-to-asset (asset-key)`
Subscribe to an asset for 30 days of access (renewable).

#### `access-asset (asset-key)`
Track asset usage (required for subscription validation).

#### `rate-asset (asset-key, stars, comment)`
Rate an asset from 1-5 stars with optional comment (requires valid license).

#### `withdraw-balance`
Creators can withdraw their accumulated earnings to their wallet.

#### `modify-asset`
Update asset details including pricing, description, and availability status.

## Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for transactions
- Basic understanding of Clarity smart contracts

### Deployment

1. **Deploy the Contract**
   ```bash
   clarinet deploy --network testnet
   ```

2. **Verify Deployment**
   Check the contract deployment on the Stacks explorer.

### Usage Examples

#### Publishing an Asset
```clarity
(contract-call? .digital-asset-studio publish-asset
  "unique-asset-key-123"
  u"My Digital Tool"
  u"A powerful productivity tool for creators"
  "premium"
  u1000000  ;; 1 STX for permanent license
  u100000   ;; 0.1 STX monthly subscription
  "abc123def456..."  ;; Content hash
)
```

#### Purchasing a License
```clarity
(contract-call? .digital-asset-studio buy-permanent-license "unique-asset-key-123")
```

#### Rating an Asset
```clarity
(contract-call? .digital-asset-studio rate-asset
  "unique-asset-key-123"
  u5
  u"Excellent tool, highly recommended!"
)
```

## Economic Model

### Revenue Sharing
- **Platform Commission**: 3% (configurable, max 15%)
- **Creator Share**: 97% of each sale
- **Payment Processing**: Handled on-chain via STX transfers

### Pricing Structure
- **Permanent Licenses**: One-time payment for unlimited access
- **Subscriptions**: Monthly recurring payments (30-day cycles)
- **Flexible Pricing**: Creators set their own rates for both models

## Technical Architecture

### Data Storage
- **Assets**: Stored with metadata, pricing, and performance metrics
- **Licenses**: User permissions and access tracking
- **Ratings**: Community feedback and reputation system
- **Balances**: Creator earnings management

### Security Features
- **Access Control**: Function-level permissions and validation
- **Payment Security**: Atomic transactions with automatic commission splitting
- **Content Integrity**: Hash-based content verification
- **Error Handling**: Comprehensive error codes and validation

## Error Codes

| Code | Description |
|------|-------------|
| 200 | Creator only function |
| 201 | Asset not found |
| 202 | Access denied |
| 203 | Payment failed |
| 204 | Asset already exists |
| 205 | Invalid tier or rating |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Join our Discord community
- Check the documentation wiki
