# TrustForge - Decentralized Identity & Reputation Engine

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-blue)](https://www.stacks.co/)
[![Clarity](https://img.shields.io/badge/Language-Clarity-orange)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Overview

TrustForge is a comprehensive blockchain-based identity management system built on the Stacks blockchain. It enables secure digital identity creation, verifiable credential issuance, and dynamic reputation tracking with advanced recovery mechanisms. The protocol provides a trustless, decentralized platform where users can establish verifiable identities, accumulate reputation through validated credentials, and maintain sovereignty over their digital presence in the Web3 ecosystem.

## Key Features

- **🔐 Trustless Identity Registration**: Secure identity creation with cryptographic hash validation
- **📜 Verifiable Credential System**: Issue, manage, and revoke verifiable credentials with metadata support
- **⭐ Dynamic Reputation Scoring**: Merit-based reputation system with configurable scoring mechanisms
- **🔒 Zero-Knowledge Proof Integration**: Privacy-preserving verification capabilities
- **🛡️ Multi-layered Recovery**: Sophisticated identity recovery protocols with designated recovery addresses
- **👑 Administrative Governance**: Robust administrative controls for protocol management
- **⏰ Automated Lifecycle Management**: Built-in expiration and revocation mechanisms for credentials

## Architecture

### Smart Contract Structure

```
TrustForge Contract
├── Identity Registry
│   ├── Core identity data with cryptographic hashes
│   ├── Credential associations
│   ├── Reputation scoring
│   └── Recovery mechanisms
├── Credential Management
│   ├── Verifiable credential issuance
│   ├── Metadata storage and validation
│   ├── Expiration handling
│   └── Revocation capabilities
└── Zero-Knowledge Proof Registry
    ├── Privacy-preserving verification
    ├── Proof data storage
    └── Verification status tracking
```

### Data Structures

#### Identity Registry

```clarity
{
  hash: (buff 32),                    ; Cryptographic identity hash
  credentials: (list 10 principal),   ; Associated credentials
  reputation-score: uint,             ; Current reputation score (0-1000)
  recovery-address: (optional principal), ; Designated recovery address
  last-updated: uint,                 ; Last modification block
  status: (string-ascii 20)           ; Current status (ACTIVE, RECOVERED)
}
```

#### Credential Store

```clarity
{
  subject: principal,                 ; Credential holder
  claim-hash: (buff 32),             ; Hash of the credential claim
  expiration: uint,                  ; Expiration block height
  revoked: bool,                     ; Revocation status
  metadata: (string-utf8 256)        ; Additional credential metadata
}
```

#### Zero-Knowledge Proof Registry

```clarity
{
  prover: principal,                 ; Proof generator
  verified: bool,                    ; Verification status
  timestamp: uint,                   ; Creation timestamp
  proof-data: (buff 1024)           ; ZK proof data
}
```

## Protocol Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MIN-REPUTATION-SCORE` | 0 | Minimum possible reputation score |
| `MAX-REPUTATION-SCORE` | 1000 | Maximum possible reputation score |
| `MIN-EXPIRATION-BLOCKS` | 1 | Minimum blocks until credential expiration |
| `MAX-METADATA-LENGTH` | 256 | Maximum credential metadata length |
| `MINIMUM-PROOF-SIZE` | 64 | Minimum zero-knowledge proof size |
| `MAX-CREDENTIALS` | 10 | Maximum credentials per identity |

## Core Functions

### Identity Management

#### `register-identity`

```clarity
(define-public (register-identity
  (identity-hash (buff 32))
  (recovery-addr (optional principal))
))
```

Registers a new identity in the TrustForge protocol with the provided cryptographic hash and optional recovery address.

**Parameters:**

- `identity-hash`: 32-byte cryptographic hash representing the identity
- `recovery-addr`: Optional principal address for identity recovery

**Returns:** `(ok true)` on success

#### `initiate-recovery`

```clarity
(define-public (initiate-recovery
  (identity principal)
  (new-hash (buff 32))
))
```

Executes identity recovery using the designated recovery address, updating the identity hash.

### Credential Management

#### `issue-credential`

```clarity
(define-public (issue-credential
  (subject principal)
  (claim-hash (buff 32))
  (expiration uint)
  (metadata (string-utf8 256))
))
```

Issues a verifiable credential to a registered identity with specified claims and metadata.

**Parameters:**

- `subject`: The principal receiving the credential
- `claim-hash`: Hash of the credential claim data
- `expiration`: Block height when credential expires
- `metadata`: UTF-8 encoded metadata (max 256 characters)

#### `revoke-credential`

```clarity
(define-public (revoke-credential
  (issuer principal)
  (nonce uint)
))
```

Revokes a previously issued credential. Only the original issuer can revoke their credentials.

### Reputation Management

#### `update-reputation`

```clarity
(define-public (update-reputation
  (subject principal)
  (score-change int)
))
```

Modifies the reputation score for a registered identity. Admin-only function with bounds checking.

### Query Functions

#### `get-identity`

```clarity
(define-read-only (get-identity (identity principal)))
```

Retrieves complete identity data for a given principal.

#### `verify-credential`

```clarity
(define-read-only (verify-credential
  (issuer principal)
  (nonce uint)
))
```

Verifies if a credential is valid, not revoked, and not expired.

#### `get-credential`

```clarity
(define-read-only (get-credential
  (issuer principal)
  (nonce uint)
))
```

Retrieves credential information by issuer and nonce.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 1000 | `ERR-NOT-AUTHORIZED` | Unauthorized access attempt |
| 1001 | `ERR-ALREADY-REGISTERED` | Identity already registered |
| 1002 | `ERR-NOT-REGISTERED` | Identity not found in registry |
| 1003 | `ERR-INVALID-PROOF` | Invalid zero-knowledge proof |
| 1004 | `ERR-INVALID-CREDENTIAL` | Credential not found or invalid |
| 1005 | `ERR-EXPIRED-CREDENTIAL` | Credential has expired |
| 1006 | `ERR-REVOKED-CREDENTIAL` | Credential has been revoked |
| 1007 | `ERR-INVALID-SCORE` | Invalid reputation score operation |
| 1008 | `ERR-INVALID-INPUT` | Invalid input parameters |
| 1009 | `ERR-INVALID-EXPIRATION` | Invalid expiration block height |
| 1010 | `ERR-INVALID-RECOVERY-ADDRESS` | Invalid recovery address |
| 1011 | `ERR-INVALID-PROOF-DATA` | Invalid proof data format |
| 1012 | `ERR-CREDENTIAL-LIMIT` | Maximum credentials limit exceeded |

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development toolkit
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Stacks Wallet](https://wallet.hiro.so/) for testnet interactions

### Installation

1. Clone the repository:

```bash
git clone https://github.com/israel-obadipe/trust-forge.git
cd trust-forge
```

2. Install dependencies:

```bash
npm install
```

3. Check contract syntax:

```bash
clarinet check
```

### Testing

Run the comprehensive test suite:

```bash
npm test
```

Or use Clarinet directly:

```bash
clarinet test
```

### Deployment

#### Testnet Deployment

```bash
clarinet integrate
```

#### Mainnet Deployment

```bash
clarinet deploy --network mainnet
```

## Usage Examples

### Registering an Identity

```javascript
import { makeContractCall, broadcastTransaction } from '@stacks/transactions';

const txOptions = {
  contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  contractName: 'trust-forge',
  functionName: 'register-identity',
  functionArgs: [
    bufferCVFromHex('a1b2c3d4e5f6...'), // identity hash
    someCV(principalCV('ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG')) // recovery address
  ],
  senderKey: privateKey,
  network: new StacksTestnet()
};

const transaction = await makeContractCall(txOptions);
const broadcastResponse = await broadcastTransaction(transaction, network);
```

### Issuing a Credential

```javascript
const credentialTxOptions = {
  contractAddress: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  contractName: 'trust-forge',
  functionName: 'issue-credential',
  functionArgs: [
    principalCV('ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG'), // subject
    bufferCVFromHex('claim-hash-here...'), // claim hash
    uintCV(1000000), // expiration block
    stringUtf8CV('Educational Credential - Computer Science Degree') // metadata
  ],
  senderKey: issuerPrivateKey,
  network: new StacksTestnet()
};
```

## Security Considerations

- **Hash Validation**: All identity hashes are validated to prevent zero-hash attacks
- **Recovery Constraints**: Recovery addresses cannot be the same as the identity owner or admin
- **Expiration Enforcement**: Credentials must have future expiration dates
- **Authorization Checks**: Admin functions are properly protected
- **Input Validation**: All user inputs are validated against defined constraints
- **Overflow Protection**: Reputation score calculations include overflow protection

## Contributing

We welcome contributions to TrustForge! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to:

- Report bugs
- Suggest enhancements
- Submit pull requests
- Follow our coding standards

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Run the test suite: `npm test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a pull request

## Roadmap

- [ ] **Phase 1**: Core identity and credential management ✅
- [ ] **Phase 2**: Advanced zero-knowledge proof integration
- [ ] **Phase 3**: Multi-signature recovery mechanisms
- [ ] **Phase 4**: Governance token integration
- [ ] **Phase 5**: Cross-chain identity bridging
- [ ] **Phase 6**: Mobile SDK development

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
