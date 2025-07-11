class BitcoinMicroLoans {
    constructor() {
        this.contractAddress = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.btc-micro-loans';
        this.contractName = 'btc-micro-loans';
        this.userSession = null;
        this.userData = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupTabs();
        this.updateLoanCalculator();
        this.loadContractStats();
        this.updateReputationBar();
    }

    setupEventListeners() {
        const borrowForm = document.getElementById('borrowForm');
        const lendForm = document.getElementById('lendForm');
        const registerForm = document.getElementById('registerForm');
        const loanAmount = document.getElementById('loanAmount');
        const loanDuration = document.getElementById('loanDuration');

        borrowForm.addEventListener('submit', (e) => this.handleBorrowSubmit(e));
        lendForm.addEventListener('submit', (e) => this.handleLendSubmit(e));
        registerForm.addEventListener('submit', (e) => this.handleRegisterSubmit(e));
        
        loanAmount.addEventListener('input', () => this.updateLoanCalculator());
        loanDuration.addEventListener('change', () => this.updateLoanCalculator());
    }

    setupTabs() {
        const navButtons = document.querySelectorAll('.nav-btn');
        const tabContents = document.querySelectorAll('.tab-content');

        navButtons.forEach(button => {
            button.addEventListener('click', () => {
                const targetTab = button.dataset.tab;
                
                navButtons.forEach(btn => btn.classList.remove('active'));
                tabContents.forEach(content => content.classList.remove('active'));
                
                button.classList.add('active');
                document.getElementById(targetTab).classList.add('active');
            });
        });
    }

    updateLoanCalculator() {
        const amount = parseFloat(document.getElementById('loanAmount').value) || 0;
        const duration = parseInt(document.getElementById('loanDuration').value) || 30;
        
        const interest = amount * 0.05;
        const platformFee = amount * 0.01;
        const total = amount + interest + platformFee;
        
        document.getElementById('summaryPrincipal').textContent = `${amount.toLocaleString()} STX`;
        document.getElementById('summaryInterest').textContent = `${interest.toLocaleString()} STX`;
        document.getElementById('summaryFee').textContent = `${platformFee.toLocaleString()} STX`;
        document.getElementById('summaryTotal').textContent = `${total.toLocaleString()} STX`;
    }

    updateReputationBar() {
        const score = parseInt(document.getElementById('reputationScore').textContent) || 100;
        const fill = document.getElementById('reputationFill');
        fill.style.width = `${score / 10}%`;
    }

    async loadContractStats() {
        try {
            const mockStats = {
                totalLoans: 147,
                totalLent: 2450000,
                totalRepaid: 1980000,
                activeLoans: 23
            };

            document.getElementById('totalLoans').textContent = mockStats.totalLoans.toLocaleString();
            document.getElementById('totalLent').textContent = `${mockStats.totalLent.toLocaleString()} STX`;
            document.getElementById('totalRepaid').textContent = `${mockStats.totalRepaid.toLocaleString()} STX`;
            document.getElementById('activeLoans').textContent = mockStats.activeLoans.toLocaleString();

            this.updateActivity('📊 Contract statistics loaded', 'Just now');
        } catch (error) {
            console.error('Error loading contract stats:', error);
            this.showNotification('Error loading contract statistics', 'error');
        }
    }

    async handleBorrowSubmit(e) {
        e.preventDefault();
        
        const amount = parseFloat(document.getElementById('loanAmount').value);
        const duration = parseInt(document.getElementById('loanDuration').value);
        const btcAddress = document.getElementById('btcAddress').value;
        
        if (!this.validateBorrowForm(amount, duration, btcAddress)) {
            return;
        }

        try {
            this.showNotification('Processing loan request...', 'info');
            
            setTimeout(() => {
                const loanId = Math.floor(Math.random() * 10000) + 1000;
                this.showNotification(`Loan #${loanId} approved for ${amount.toLocaleString()} STX!`, 'success');
                this.updateActivity('💰 Loan approved', `${amount.toLocaleString()} STX for ${duration} days`);
                document.getElementById('borrowForm').reset();
                this.updateLoanCalculator();
            }, 2000);
            
        } catch (error) {
            console.error('Error requesting loan:', error);
            this.showNotification('Error processing loan request', 'error');
        }
    }

    async handleLendSubmit(e) {
        e.preventDefault();
        
        const amount = parseFloat(document.getElementById('contributionAmount').value);
        
        if (!amount || amount < 100) {
            this.showNotification('Minimum contribution is 100 STX', 'error');
            return;
        }

        try {
            this.showNotification('Processing contribution...', 'info');
            
            setTimeout(() => {
                this.showNotification(`Successfully contributed ${amount.toLocaleString()} STX to the lending pool!`, 'success');
                this.updateActivity('🏦 Pool contribution', `${amount.toLocaleString()} STX added to lending pool`);
                document.getElementById('lendForm').reset();
            }, 1500);
            
        } catch (error) {
            console.error('Error contributing to pool:', error);
            this.showNotification('Error processing contribution', 'error');
        }
    }

    async handleRegisterSubmit(e) {
        e.preventDefault();
        
        const btcAddress = document.getElementById('regBtcAddress').value;
        const monthlyEarnings = parseFloat(document.getElementById('monthlyEarnings').value);
        
        if (!this.validateBtcAddress(btcAddress)) {
            this.showNotification('Invalid Bitcoin address', 'error');
            return;
        }

        if (!monthlyEarnings || monthlyEarnings < 0) {
            this.showNotification('Please enter valid monthly earnings', 'error');
            return;
        }

        try {
            this.showNotification('Registering borrower profile...', 'info');
            
            setTimeout(() => {
                this.showNotification('Successfully registered as borrower!', 'success');
                this.updateActivity('👤 Profile registered', `Monthly earnings: ${monthlyEarnings.toLocaleString()} sats`);
                document.getElementById('registerForm').reset();
            }, 1500);
            
        } catch (error) {
            console.error('Error registering borrower:', error);
            this.showNotification('Error registering borrower', 'error');
        }
    }

    validateBorrowForm(amount, duration, btcAddress) {
        if (!amount || amount < 1000 || amount > 100000) {
            this.showNotification('Loan amount must be between 1,000 and 100,000 STX', 'error');
            return false;
        }

        if (!duration || duration < 1 || duration > 365) {
            this.showNotification('Loan duration must be between 1 and 365 days', 'error');
            return false;
        }

        if (!this.validateBtcAddress(btcAddress)) {
            this.showNotification('Invalid Bitcoin address', 'error');
            return false;
        }

        return true;
    }

    validateBtcAddress(address) {
        const btcRegex = /^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,87}$/;
        return btcRegex.test(address);
    }

    updateActivity(title, description) {
        const activityList = document.getElementById('activityList');
        const activityItem = document.createElement('div');
        activityItem.className = 'activity-item';
        
        const icons = ['💰', '🏦', '📊', '👤', '✅', '⚠️'];
        const randomIcon = icons[Math.floor(Math.random() * icons.length)];
        
        activityItem.innerHTML = `
            <div class="activity-icon">${randomIcon}</div>
            <div class="activity-content">
                <p>${title}</p>
                <span class="activity-time">${description}</span>
            </div>
        `;
        
        activityList.insertBefore(activityItem, activityList.firstChild);
        
        if (activityList.children.length > 5) {
            activityList.removeChild(activityList.lastChild);
        }
    }

    showNotification(message, type = 'success') {
        const notification = document.getElementById('notification');
        notification.textContent = message;
        notification.className = `notification ${type}`;
        notification.classList.add('show');
        
        setTimeout(() => {
            notification.classList.remove('show');
        }, 4000);
    }

    formatNumber(num) {
        return new Intl.NumberFormat('en-US').format(num);
    }

    formatCurrency(amount, currency = 'STX') {
        return `${this.formatNumber(amount)} ${currency}`;
    }

    async connectWallet() {
        try {
            this.showNotification('Connecting to wallet...', 'info');
            
            setTimeout(() => {
                this.showNotification('Wallet connected successfully!', 'success');
                this.updateActivity('🔗 Wallet connected', 'Ready to start lending and borrowing');
            }, 1000);
            
        } catch (error) {
            console.error('Error connecting wallet:', error);
            this.showNotification('Error connecting wallet', 'error');
        }
    }

    async loadUserProfile() {
        try {
            const mockProfile = {
                totalBorrowed: 25000,
                totalRepaid: 20000,
                activeLoans: 2,
                reputationScore: 850
            };

            document.getElementById('totalBorrowed').textContent = `${mockProfile.totalBorrowed.toLocaleString()} STX`;
            document.getElementById('totalRepaidProfile').textContent = `${mockProfile.totalRepaid.toLocaleString()} STX`;
            document.getElementById('activeLoansProfile').textContent = mockProfile.activeLoans.toString();
            document.getElementById('reputationScore').textContent = mockProfile.reputationScore.toString();
            
            this.updateReputationBar();
            
        } catch (error) {
            console.error('Error loading user profile:', error);
        }
    }

    async checkLoanEligibility() {
        try {
            const mockEligibility = {
                eligible: true,
                maxLoanAmount: 50000,
                reputationScore: 850
            };

            if (mockEligibility.eligible) {
                this.showNotification(`You're eligible for loans up to ${mockEligibility.maxLoanAmount.toLocaleString()} STX`, 'success');
            } else {
                this.showNotification('You need to improve your reputation score to be eligible for loans', 'error');
            }
            
        } catch (error) {
            console.error('Error checking loan eligibility:', error);
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const app = new BitcoinMicroLoans();
    
    setTimeout(() => {
        app.loadUserProfile();
    }, 1000);
});

window.addEventListener('load', () => {
    const loadingOverlay = document.createElement('div');
    loadingOverlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(79, 70, 229, 0.9);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 9999;
        transition: opacity 0.5s ease;
    `;
    
    loadingOverlay.innerHTML = `
        <div style="text-align: center; color: white;">
            <div style="font-size: 2rem; margin-bottom: 1rem;">₿</div>
            <div style="font-size: 1.2rem; font-weight: 600;">Bitcoin Micro-Loans</div>
            <div style="font-size: 0.9rem; margin-top: 0.5rem;">Loading...</div>
        </div>
    `;
    
    document.body.appendChild(loadingOverlay);
    
    setTimeout(() => {
        loadingOverlay.style.opacity = '0';
        setTimeout(() => {
            document.body.removeChild(loadingOverlay);
        }, 500);
    }, 1500);
});
