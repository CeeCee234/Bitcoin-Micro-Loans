# ₿ Bitcoin Micro-Loans

> 🚀 **Collateral-free loans for the unbanked, repaid via future Bitcoin earnings**

A decentralized lending platform built on the Stacks blockchain that enables micro-loans without traditional collateral requirements. Instead, loans are backed by borrowers' future Bitcoin earnings potential.

## ✨ Features

- 💰 **Collateral-free loans** - No need to lock up assets
- 🏦 **Decentralized lending pool** - Community-funded loan system
- 📊 **Reputation-based scoring** - Build credit through responsible borrowing
- ⚡ **Quick approvals** - Instant loan processing on-chain
- 🔒 **Secure & transparent** - All transactions recorded on Stacks blockchain
- 📱 **Mobile-responsive UI** - Access from any device

## 🎯 How It Works

### For Borrowers
1. **Register** your profile with Bitcoin address and earnings history
2. **Request a loan** between 1,000 - 100,000 STX
3. **Receive funds** instantly upon approval
4. **Repay** within the agreed timeframe to maintain good standing

### For Lenders
1. **Contribute** to the lending pool with minimum 100 STX
2. **Earn interest** from successful loan repayments
3. **Diversify risk** across multiple borrowers automatically
4. **Withdraw earnings** at any time

## 🛠️ Technical Details

### Smart Contract Features
- **Loan Management**: Create, track, and manage loans with automated repayment
- **Reputation System**: Dynamic scoring based on borrowing history
- **Interest Calculations**: 5% interest rate with 1% platform fee
- **Pool Management**: Automated distribution of lender contributions
- **Default Handling**: Automatic marking of overdue loans

### Contract Functions
- `register-borrower` - Register as a borrower with BTC address
- `request-loan` - Request a loan with specified amount and duration
- `repay-loan` - Repay an active loan
- `contribute-to-pool` - Add funds to the lending pool
- `get-loan-details` - Retrieve loan information
- `get-borrower-profile` - View borrower statistics
- `calculate-loan-health` - Check loan status and health

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) v16 or higher
- Stacks wallet (Hiro Wallet recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/bitcoin-micro-loans.git
   cd bitcoin-micro-loans
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Deploy the contract**
   ```bash
   clarinet deployments generate --devnet
   clarinet deployments apply -p deployments/devnet.devnet-plan.yaml
   ```

4. **Start the web interface**
   ```bash
   # Serve the HTML files locally
   python -m http.server 8000
   # or use any static file server
   ```

5. **Access the app**
   Open `http://localhost:8000` in your browser

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 📋 Usage Examples

### Requesting a Loan
```clarity
(contract-call? .btc-micro-loans request-loan u5000 u30 "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")
```

### Contributing to Pool
```clarity
(contract-call? .btc-micro-loans contribute-to-pool u10000)
```

### Checking Loan Status
```clarity
(contract-call? .btc-micro-loans get-loan-details u1)
```

## 💡 Loan Parameters

| Parameter | Minimum | Maximum | Description |
|-----------|---------|---------|-------------|
| Loan Amount | 1,000 STX | 100,000 STX | Principal amount |
| Duration | 1 day | 365 days | Repayment period |
| Interest Rate | 5% | 5% | Fixed interest rate |
| Platform Fee | 1% | 1% | Service fee |

## 🔐 Security Features

- ✅ **Input validation** on all contract functions
- ✅ **Authorization checks** for sensitive operations
- ✅ **Overflow protection** in calculations
- ✅ **State consistency** maintained across transactions
- ✅ **Emergency controls** for contract management

## 🌐 Web Interface

The included web interface provides:
- 📊 **Dashboard** with lending statistics
- 💰 **Loan request form** with real-time calculations
- 🏦 **Pool contribution** interface
- 👤 **Profile management** for borrowers
- 📱 **Responsive design** for mobile devices

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on [Stacks blockchain](https://stacks.co/)
- Powered by [Clarinet](https://github.com/hirosystems/clarinet)
- UI inspired by modern DeFi interfaces

## 📞 Support

- 📧 Email: support@bitcoinmicroloans.com
- 💬 Discord: [Join our community](https://discord.gg/bitcoinmicroloans)
- 🐦 Twitter: [@BTCMicroLoans](https://twitter.com/BTCMicroLoans)

---

**⚠️ Disclaimer**: This is experimental software. Use at your own risk. Not financial advice.
