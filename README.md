# Income-Verify Smart Contract

A comprehensive self-sovereign identity and income/employment verification system built on the Stacks blockchain using Clarity.

## Overview

Income-Verify enables users to create and manage their digital identity while maintaining control over their employment and income verification data. The contract implements a trustless system where authorized verifiers can validate user claims without compromising user privacy or data ownership.

## Features

### 🔐 Self-Sovereign Identity
- User-controlled identity creation and management
- Verification tracking and statistics
- Decentralized identity verification by authorized entities

### 💼 Employment Verification
- Add and manage employment history records
- Track employer, position, and employment periods
- Third-party verification system for employment claims

### 💰 Income Verification
- Record income information with amount, currency, and period
- Time-based validity with expiration handling
- Secure verification by authorized financial institutions

### 🛡️ Security & Authorization
- Role-based access control for verifiers
- Contract owner manages verifier authorization
- Comprehensive error handling and data validation

## Getting Started

### Prerequisites

- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for transaction fees
- Basic understanding of Clarity smart contracts

### Deployment

1. Deploy the contract to the Stacks blockchain
2. The deployer becomes the contract owner with full administrative privileges
3. Authorize trusted verifiers using the `authorize-verifier` function

## Usage Guide

### For Users

#### 1. Create Your Identity
```clarity
(contract-call? .income-verify create-identity)
```

#### 2. Add Employment Record
```clarity
(contract-call? .income-verify add-employment-record 
  "Acme Corporation" 
  "Software Engineer" 
  u1640995200  ;; Start date (block height)
  (some u1672531200))  ;; End date (optional)
```

#### 3. Add Income Record
```clarity
(contract-call? .income-verify add-income-record 
  u75000        ;; Amount
  "USD"         ;; Currency
  "yearly"      ;; Period
  "Salary"      ;; Source
  u52560)       ;; Valid for ~1 year (blocks)
```

#### 4. Check Verification Status
```clarity
(contract-call? .income-verify get-verification-summary 'SP1ABC...XYZ)
```

### For Verifiers

#### Verify Employment
```clarity
(contract-call? .income-verify verify-employment 
  'SP1USER...ADDRESS 
  u1)  ;; Record ID
```

#### Verify Income
```clarity
(contract-call? .income-verify verify-income 
  'SP1USER...ADDRESS 
  u1)  ;; Record ID
```

### For Contract Owner

#### Authorize Verifier
```clarity
(contract-call? .income-verify authorize-verifier 
  'SP1VERIFIER...ADDRESS 
  "Bank of Stacks")
```

#### Revoke Verifier
```clarity
(contract-call? .income-verify revoke-verifier 'SP1VERIFIER...ADDRESS)
```

## Contract Functions

### Public Functions

| Function | Description | Access |
|----------|-------------|---------|
| `create-identity()` | Initialize user identity | Anyone |
| `add-employment-record()` | Add employment history | Identity owners |
| `add-income-record()` | Add income information | Identity owners |
| `verify-employment()` | Verify employment record | Authorized verifiers |
| `verify-income()` | Verify income record | Authorized verifiers |
| `verify-identity()` | Mark identity as verified | Authorized verifiers |
| `authorize-verifier()` | Add trusted verifier | Contract owner |
| `revoke-verifier()` | Remove verifier access | Contract owner |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-identity(user)` | Get user identity data | Identity record |
| `get-employment-record(user, id)` | Get employment record | Employment data |
| `get-income-record(user, id)` | Get income record | Income data |
| `is-identity-verified(user)` | Check identity verification | Boolean |
| `is-employment-verified(user, id)` | Check employment verification | Boolean |
| `is-income-verified(user, id)` | Check income verification | Boolean |
| `get-verification-summary(user)` | Get complete verification status | Summary object |

## Data Structures

### Identity Record
```clarity
{
  verified: bool,
  created-at: uint,
  updated-at: uint,
  verification-count: uint
}
```

### Employment Record
```clarity
{
  employer: (string-ascii 100),
  position: (string-ascii 100),
  start-date: uint,
  end-date: (optional uint),
  verified: bool,
  verifier: (optional principal),
  verified-at: (optional uint)
}
```

### Income Record
```clarity
{
  amount: uint,
  currency: (string-ascii 10),
  period: (string-ascii 20),
  source: (string-ascii 100),
  verified: bool,
  verifier: (optional principal),
  verified-at: (optional uint),
  valid-until: uint
}
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR_UNAUTHORIZED | Caller lacks required permissions |
| u101 | ERR_NOT_FOUND | Record or identity not found |
| u102 | ERR_ALREADY_EXISTS | Identity already exists |
| u103 | ERR_INVALID_DATA | Invalid input data provided |
| u104 | ERR_EXPIRED | Record has expired |
| u105 | ERR_NOT_VERIFIED | Record not verified |

## Use Cases

### Individual Users
- **Job Applications**: Provide verified employment history to potential employers
- **Loan Applications**: Share verified income data with financial institutions
- **Rental Applications**: Demonstrate employment and income stability
- **Identity Verification**: Establish trusted digital identity

### Employers
- **Background Checks**: Verify candidate employment history
- **Employee Verification**: Confirm current employee status for third parties
- **Reference Validation**: Provide trusted employment confirmations

### Financial Institutions
- **Credit Assessment**: Access verified income information
- **Loan Underwriting**: Validate employment and income stability
- **Account Opening**: Perform KYC with verified identity data

## Security Considerations

- **Data Privacy**: Users maintain control over their data
- **Verifier Trust**: Only authorized entities can perform verifications
- **Expiration Handling**: Income records have built-in validity periods
- **Access Control**: Role-based permissions prevent unauthorized access
- **Immutable Records**: Blockchain storage ensures data integrity

## Roadmap

- [ ] Integration with major HR systems
- [ ] Mobile wallet integration
- [ ] Privacy-preserving verification protocols
- [ ] Multi-signature verification requirements
- [ ] Automated verification through APIs
- [ ] Cross-chain identity verification
