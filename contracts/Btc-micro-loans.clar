;; title: Btc-micro-loans
;; version: 1.0
;; summary: Collateral-free micro-loans for the unbanked, repaid via future Bitcoin earnings
;; description: Smart contract enabling micro-loans backed by future Bitcoin earnings predictions

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_LOAN_NOT_FOUND (err u102))
(define-constant ERR_LOAN_ALREADY_EXISTS (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))
(define-constant ERR_LOAN_EXPIRED (err u105))
(define-constant ERR_LOAN_ALREADY_REPAID (err u106))
(define-constant ERR_UNAUTHORIZED (err u107))
(define-constant ERR_INVALID_DURATION (err u108))
(define-constant ERR_MINIMUM_AMOUNT (err u109))
(define-constant ERR_MAXIMUM_AMOUNT (err u110))
(define-constant ERR_INVALID_PAYMENT_AMOUNT (err u111))
(define-constant ERR_PAYMENT_EXCEEDS_BALANCE (err u112))
(define-constant ERR_INSURANCE_NOT_FOUND (err u113))
(define-constant ERR_INSURANCE_EXPIRED (err u114))
(define-constant ERR_CLAIM_NOT_FOUND (err u115))
(define-constant ERR_CLAIM_ALREADY_PROCESSED (err u116))
(define-constant ERR_INVALID_RISK_SCORE (err u117))
(define-constant ERR_INSUFFICIENT_INSURANCE_FUNDS (err u118))
(define-constant ERR_REFINANCE_NOT_ELIGIBLE (err u119))
(define-constant ERR_REFINANCE_TOO_EARLY (err u120))
(define-constant ERR_REFINANCE_ALREADY_EXISTS (err u121))
(define-constant ERR_NO_OUTSTANDING_BALANCE (err u122))
(define-constant ERR_GRACE_PERIOD_ACTIVE (err u123))
(define-constant ERR_MAX_EXTENSIONS_REACHED (err u124))
(define-constant ERR_LOAN_NOT_ELIGIBLE (err u125))
(define-constant ERR_EXTENSION_NOT_FOUND (err u126))

(define-constant MIN_LOAN_AMOUNT u1000)
(define-constant MAX_LOAN_AMOUNT u100000)
(define-constant MIN_DURATION_BLOCKS u144)
(define-constant MAX_DURATION_BLOCKS u52560)
(define-constant INTEREST_RATE_BASIS_POINTS u500)
(define-constant PLATFORM_FEE_BASIS_POINTS u100)
(define-constant GRACE_PERIOD_BLOCKS u1440)
(define-constant MAX_GRACE_EXTENSIONS u2)
(define-constant GRACE_EXTENSION_FEE_BASIS_POINTS u50)

(define-data-var contract-active bool true)
(define-data-var total-loans-issued uint u0)
(define-data-var total-amount-lent uint u0)
(define-data-var total-amount-repaid uint u0)
(define-data-var next-loan-id uint u1)
(define-data-var next-insurance-id uint u1)
(define-data-var next-claim-id uint u1)
(define-data-var insurance-pool-balance uint u0)
(define-data-var next-refinance-id uint u1)
(define-data-var total-refinanced-loans uint u0)
(define-data-var next-extension-id uint u1)
(define-data-var total-extensions-granted uint u0)

(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    amount: uint,
    interest-rate: uint,
    duration-blocks: uint,
    issue-block: uint,
    repayment-due-block: uint,
    amount-due: uint,
    amount-paid: uint,
    remaining-balance: uint,
    status: (string-ascii 20),
    btc-address: (string-ascii 62),
    earning-history: uint
  }
)

(define-map borrower-profiles
  { borrower: principal }
  {
    total-borrowed: uint,
    total-repaid: uint,
    loans-count: uint,
    reputation-score: uint,
    btc-earnings-last-month: uint,
    registration-block: uint
  }
)

(define-map lender-pool
  { lender: principal }
  {
    total-contributed: uint,
    total-earned: uint,
    active-contributions: uint
  }
)

(define-map borrower-loan-index
  { borrower: principal, index: uint }
  { loan-id: uint }
)

(define-map borrower-loan-count
  { borrower: principal }
  { count: uint }
)

(define-map refinanced-loans
  { refinance-id: uint }
  {
    original-loan-id: uint,
    new-loan-id: uint,
    borrower: principal,
    original-balance: uint,
    new-interest-rate: uint,
    refinance-block: uint,
    new-duration-blocks: uint,
    new-amount-due: uint,
    interest-saved: uint
  }
)

(define-map loan-refinance-history
  { loan-id: uint }
  { refinance-id: uint, is-refinanced: bool }
)

(define-map grace-period-extensions
  { extension-id: uint }
  {
    loan-id: uint,
    borrower: principal,
    extension-block: uint,
    original-due-block: uint,
    new-due-block: uint,
    extension-fee: uint,
    extension-number: uint
  }
)

(define-map loan-extension-count
  { loan-id: uint }
  { count: uint }
)

(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (var-set contract-active true)
    (ok true)
  )
)

(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

(define-public (register-borrower (btc-address (string-ascii 62)) (monthly-earnings uint))
  (let
    (
      (borrower tx-sender)
      (current-block u0)
    )
    (asserts! (var-get contract-active) ERR_OWNER_ONLY)
    (map-set borrower-profiles
      { borrower: borrower }
      {
        total-borrowed: u0,
        total-repaid: u0,
        loans-count: u0,
        reputation-score: u100,
        btc-earnings-last-month: monthly-earnings,
        registration-block: current-block
      }
    )
    (ok true)
  )
)

(define-public (contribute-to-pool (amount uint))
  (let
    (
      (lender tx-sender)
      (current-contribution (default-to 
        {
          total-contributed: u0,
          total-earned: u0,
          active-contributions: u0
        }
        (map-get? lender-pool { lender: lender })
      ))
    )
    (asserts! (var-get contract-active) ERR_OWNER_ONLY)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount lender (as-contract tx-sender)))
    (map-set lender-pool
      { lender: lender }
      {
        total-contributed: (+ (get total-contributed current-contribution) amount),
        total-earned: (get total-earned current-contribution),
        active-contributions: (+ (get active-contributions current-contribution) amount)
      }
    )
    (ok true)
  )
)

(define-public (request-loan (amount uint) (duration-blocks uint) (btc-address (string-ascii 62)))
  (let
    (
      (borrower tx-sender)
      (loan-id (var-get next-loan-id))
      (current-block u0)
      (interest-amount (/ (* amount INTEREST_RATE_BASIS_POINTS) u10000))
      (platform-fee (/ (* amount PLATFORM_FEE_BASIS_POINTS) u10000))
      (total-due (+ amount interest-amount platform-fee))
      (borrower-profile (map-get? borrower-profiles { borrower: borrower }))
    )
    (asserts! (var-get contract-active) ERR_OWNER_ONLY)
    (asserts! (>= amount MIN_LOAN_AMOUNT) ERR_MINIMUM_AMOUNT)
    (asserts! (<= amount MAX_LOAN_AMOUNT) ERR_MAXIMUM_AMOUNT)
    (asserts! (>= duration-blocks MIN_DURATION_BLOCKS) ERR_INVALID_DURATION)
    (asserts! (<= duration-blocks MAX_DURATION_BLOCKS) ERR_INVALID_DURATION)
    (asserts! (is-some borrower-profile) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? loans { loan-id: loan-id })) ERR_LOAN_ALREADY_EXISTS)
    
    (map-set loans
      { loan-id: loan-id }
      {
        borrower: borrower,
        amount: amount,
        interest-rate: INTEREST_RATE_BASIS_POINTS,
        duration-blocks: duration-blocks,
        issue-block: current-block,
        repayment-due-block: (+ current-block duration-blocks),
        amount-due: total-due,
        amount-paid: u0,
        remaining-balance: total-due,
        status: "active",
        btc-address: btc-address,
        earning-history: (get btc-earnings-last-month (unwrap-panic borrower-profile))
      }
    )

    (let
      (
        (count-entry (default-to { count: u0 } (map-get? borrower-loan-count { borrower: borrower })))
        (idx (get count count-entry))
      )
      (map-set borrower-loan-index { borrower: borrower, index: idx } { loan-id: loan-id })
      (map-set borrower-loan-count { borrower: borrower } { count: (+ idx u1) })
    )
    
    (try! (as-contract (stx-transfer? amount tx-sender borrower)))
    
    (var-set next-loan-id (+ loan-id u1))
    (var-set total-loans-issued (+ (var-get total-loans-issued) u1))
    (var-set total-amount-lent (+ (var-get total-amount-lent) amount))
    
    (match borrower-profile
      profile (map-set borrower-profiles
        { borrower: borrower }
        (merge profile {
          total-borrowed: (+ (get total-borrowed profile) amount),
          loans-count: (+ (get loans-count profile) u1)
        })
      )
      true
    )
    
    (ok loan-id)
  )
)

(define-public (make-partial-payment (loan-id uint) (payment-amount uint))
  (let
    (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_LOAN_NOT_FOUND))
      (borrower tx-sender)
      (current-paid (get amount-paid loan))
      (remaining (get remaining-balance loan))
      (new-paid (+ current-paid payment-amount))
      (new-remaining (- remaining payment-amount))
    )
    (asserts! (var-get contract-active) ERR_OWNER_ONLY)
    (asserts! (is-eq borrower (get borrower loan)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status loan) "active") ERR_LOAN_ALREADY_REPAID)
    (asserts! (> payment-amount u0) ERR_INVALID_PAYMENT_AMOUNT)
    (asserts! (<= payment-amount remaining) ERR_PAYMENT_EXCEEDS_BALANCE)
    
    (try! (stx-transfer? payment-amount borrower (as-contract tx-sender)))
    
    (map-set loans
      { loan-id: loan-id }
      (merge loan {
        amount-paid: new-paid,
        remaining-balance: new-remaining,
        status: (if (is-eq new-remaining u0) "repaid" "active")
      })
    )
    
    (var-set total-amount-repaid (+ (var-get total-amount-repaid) payment-amount))
    
    (if (is-eq new-remaining u0)
      (let
        (
          (borrower-profile (unwrap-panic (map-get? borrower-profiles { borrower: borrower })))
        )
        (map-set borrower-profiles
          { borrower: borrower }
          (merge borrower-profile {
            total-repaid: (+ (get total-repaid borrower-profile) (get amount-due loan)),
            reputation-score: (if (> (+ (get reputation-score borrower-profile) u10) u1000) 
                               u1000 
                               (+ (get reputation-score borrower-profile) u10))
          })
        )
      )
      true
    )
    
    (ok { 
      amount-paid: new-paid, 
      remaining-balance: new-remaining, 
      fully-repaid: (is-eq new-remaining u0)
    })
  )
)

(define-public (repay-loan (loan-id uint))
  (let
    (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_LOAN_NOT_FOUND))
      (borrower tx-sender)
      (current-block u0)
      (amount-due (get amount-due loan))
    )
    (asserts! (var-get contract-active) ERR_OWNER_ONLY)
    (asserts! (is-eq borrower (get borrower loan)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status loan) "active") ERR_LOAN_ALREADY_REPAID)
    
    (try! (stx-transfer? (get remaining-balance loan) borrower (as-contract tx-sender)))
    
    (map-set loans
      { loan-id: loan-id }
      (merge loan { 
        status: "repaid",
        amount-paid: amount-due,
        remaining-balance: u0
      })
    )
    
    (var-set total-amount-repaid (+ (var-get total-amount-repaid) (get remaining-balance loan)))
    
    (let
      (
        (borrower-profile (unwrap-panic (map-get? borrower-profiles { borrower: borrower })))
      )
      (map-set borrower-profiles
        { borrower: borrower }
        (merge borrower-profile {
          total-repaid: (+ (get total-repaid borrower-profile) amount-due),
          reputation-score: (if (> (+ (get reputation-score borrower-profile) u10) u1000) 
                             u1000 
                             (+ (get reputation-score borrower-profile) u10))
        })
      )
    )
    
    (ok true)
  )
)

(define-public (mark-loan-defaulted (loan-id uint))
  (let
    (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_LOAN_NOT_FOUND))
      (current-block u0)
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (is-eq (get status loan) "active") ERR_LOAN_ALREADY_REPAID)
    (asserts! (> current-block (get repayment-due-block loan)) ERR_LOAN_EXPIRED)
    
    (map-set loans
      { loan-id: loan-id }
      (merge loan { status: "defaulted" })
    )
    
    (let
      (
        (borrower (get borrower loan))
        (borrower-profile (unwrap-panic (map-get? borrower-profiles { borrower: borrower })))
      )
      (map-set borrower-profiles
        { borrower: borrower }
        (merge borrower-profile {
          reputation-score: (if (> (get reputation-score borrower-profile) u50) 
                             (- (get reputation-score borrower-profile) u50) 
                             u0)
        })
      )
    )
    
    (ok true)
  )
)

(define-public (withdraw-earnings (amount uint))
  (let
    (
      (lender tx-sender)
      (lender-data (unwrap! (map-get? lender-pool { lender: lender }) ERR_UNAUTHORIZED))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (>= (get total-earned lender-data) amount) ERR_INSUFFICIENT_FUNDS)
    
    (try! (as-contract (stx-transfer? amount tx-sender lender)))
    
    (map-set lender-pool
      { lender: lender }
      (merge lender-data {
        total-earned: (- (get total-earned lender-data) amount)
      })
    )
    
    (ok true)
  )
)

(define-read-only (get-loan-details (loan-id uint))
  (map-get? loans { loan-id: loan-id })
)

(define-read-only (get-borrower-profile (borrower principal))
  (map-get? borrower-profiles { borrower: borrower })
)

(define-read-only (get-lender-profile (lender principal))
  (map-get? lender-pool { lender: lender })
)

(define-read-only (get-contract-stats)
  {
    total-loans-issued: (var-get total-loans-issued),
    total-amount-lent: (var-get total-amount-lent),
    total-amount-repaid: (var-get total-amount-repaid),
    next-loan-id: (var-get next-loan-id),
    contract-active: (var-get contract-active)
  }
)

(define-read-only (calculate-loan-health (loan-id uint))
  (match (map-get? loans { loan-id: loan-id })
    loan (let
      (
        (current-block u0)
        (blocks-remaining (if (> (get repayment-due-block loan) current-block)
                           (- (get repayment-due-block loan) current-block)
                           u0))
        (blocks-elapsed (- current-block (get issue-block loan)))
        (duration (get duration-blocks loan))
      )
      (if (is-eq (get status loan) "repaid")
        { health-score: u100, status: "repaid", blocks-remaining: u0 }
        (if (is-eq (get status loan) "defaulted")
          { health-score: u0, status: "defaulted", blocks-remaining: u0 }
          {
            health-score: (/ (* blocks-remaining u100) duration),
            status: "active",
            blocks-remaining: blocks-remaining
          }
        )
      )
    )
    { health-score: u0, status: "not-found", blocks-remaining: u0 }
  )
)

(define-read-only (get-borrower-eligibility (borrower principal))
  (let
    (
      (profile (map-get? borrower-profiles { borrower: borrower }))
    )
    (match profile
      borrower-data
      {
        eligible: (and 
          (>= (get reputation-score borrower-data) u50)
          (> (get btc-earnings-last-month borrower-data) u0)
        ),
        max-loan-amount: (if (> (* (get btc-earnings-last-month borrower-data) u10) MAX_LOAN_AMOUNT) 
                          MAX_LOAN_AMOUNT 
                          (* (get btc-earnings-last-month borrower-data) u10)),
        reputation-score: (get reputation-score borrower-data)
      }
      { eligible: false, max-loan-amount: u0, reputation-score: u0 }
    )
  )
)

(define-read-only (estimate-loan-cost (amount uint) (duration-blocks uint))
  (let
    (
      (interest-amount (/ (* amount INTEREST_RATE_BASIS_POINTS) u10000))
      (platform-fee (/ (* amount PLATFORM_FEE_BASIS_POINTS) u10000))
      (total-due (+ amount interest-amount platform-fee))
    )
    {
      principal: amount,
      interest: interest-amount,
      platform-fee: platform-fee,
      total-due: total-due,
      daily-payment: (/ total-due (/ duration-blocks u144))
    }
  )
)

(define-read-only (get-payment-progress (loan-id uint))
  (match (map-get? loans { loan-id: loan-id })
    loan
    {
      loan-id: loan-id,
      amount-due: (get amount-due loan),
      amount-paid: (get amount-paid loan),
      remaining-balance: (get remaining-balance loan),
      payment-percentage: (/ (* (get amount-paid loan) u100) (get amount-due loan)),
      status: (get status loan)
    }
    { loan-id: loan-id, amount-due: u0, amount-paid: u0, remaining-balance: u0, payment-percentage: u0, status: "not-found" }
  )
)

(define-read-only (get-borrower-loan-count (borrower principal))
  (match (map-get? borrower-loan-count { borrower: borrower })
    entry (get count entry)
    u0
  )
)

(define-read-only (get-borrower-loan-id-at (borrower principal) (index uint))
  (match (map-get? borrower-loan-index { borrower: borrower, index: index })
    entry (some (get loan-id entry))
    none
  )
)

(define-public (refinance-loan (loan-id uint) (new-duration-blocks uint))
  (let
    (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_LOAN_NOT_FOUND))
      (borrower tx-sender)
      (current-block u0)
      (borrower-profile (unwrap! (map-get? borrower-profiles { borrower: borrower }) ERR_UNAUTHORIZED))
      (remaining-balance (get remaining-balance loan))
      (blocks-elapsed (- current-block (get issue-block loan)))
      (reputation (get reputation-score borrower-profile))
      (refinance-id (var-get next-refinance-id))
      (new-loan-id (var-get next-loan-id))
      (existing-refinance (map-get? loan-refinance-history { loan-id: loan-id }))
    )
    (asserts! (var-get contract-active) ERR_OWNER_ONLY)
    (asserts! (is-eq borrower (get borrower loan)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status loan) "active") ERR_LOAN_ALREADY_REPAID)
    (asserts! (> remaining-balance u0) ERR_NO_OUTSTANDING_BALANCE)
    (asserts! (>= reputation u200) ERR_REFINANCE_NOT_ELIGIBLE)
    (asserts! (>= blocks-elapsed u1440) ERR_REFINANCE_TOO_EARLY)
    (asserts! (is-none existing-refinance) ERR_REFINANCE_ALREADY_EXISTS)
    (asserts! (>= new-duration-blocks MIN_DURATION_BLOCKS) ERR_INVALID_DURATION)
    (asserts! (<= new-duration-blocks MAX_DURATION_BLOCKS) ERR_INVALID_DURATION)
    
    (let
      (
        (new-interest-rate (if (>= reputation u500)
                             u250
                             (if (>= reputation u300)
                               u350
                               u400)))
        (new-interest-amount (/ (* remaining-balance new-interest-rate) u10000))
        (platform-fee (/ (* remaining-balance PLATFORM_FEE_BASIS_POINTS) u10000))
        (new-total-due (+ remaining-balance new-interest-amount platform-fee))
        (old-interest (/ (* remaining-balance INTEREST_RATE_BASIS_POINTS) u10000))
        (interest-saved (- old-interest new-interest-amount))
      )
      
      (map-set loans
        { loan-id: loan-id }
        (merge loan { 
          status: "refinanced",
          remaining-balance: u0
        })
      )
      
      (map-set loans
        { loan-id: new-loan-id }
        {
          borrower: borrower,
          amount: remaining-balance,
          interest-rate: new-interest-rate,
          duration-blocks: new-duration-blocks,
          issue-block: current-block,
          repayment-due-block: (+ current-block new-duration-blocks),
          amount-due: new-total-due,
          amount-paid: u0,
          remaining-balance: new-total-due,
          status: "active",
          btc-address: (get btc-address loan),
          earning-history: (get btc-earnings-last-month borrower-profile)
        }
      )
      
      (map-set refinanced-loans
        { refinance-id: refinance-id }
        {
          original-loan-id: loan-id,
          new-loan-id: new-loan-id,
          borrower: borrower,
          original-balance: remaining-balance,
          new-interest-rate: new-interest-rate,
          refinance-block: current-block,
          new-duration-blocks: new-duration-blocks,
          new-amount-due: new-total-due,
          interest-saved: interest-saved
        }
      )
      
      (map-set loan-refinance-history
        { loan-id: loan-id }
        { refinance-id: refinance-id, is-refinanced: true }
      )
      
      (let
        (
          (count-entry (default-to { count: u0 } (map-get? borrower-loan-count { borrower: borrower })))
          (idx (get count count-entry))
        )
        (map-set borrower-loan-index { borrower: borrower, index: idx } { loan-id: new-loan-id })
        (map-set borrower-loan-count { borrower: borrower } { count: (+ idx u1) })
      )
      
      (var-set next-loan-id (+ new-loan-id u1))
      (var-set next-refinance-id (+ refinance-id u1))
      (var-set total-refinanced-loans (+ (var-get total-refinanced-loans) u1))
      
      (ok { 
        refinance-id: refinance-id,
        new-loan-id: new-loan-id, 
        new-interest-rate: new-interest-rate,
        new-amount-due: new-total-due,
        interest-saved: interest-saved
      })
    )
  )
)

(define-read-only (get-refinance-details (refinance-id uint))
  (map-get? refinanced-loans { refinance-id: refinance-id })
)

(define-read-only (get-loan-refinance-status (loan-id uint))
  (map-get? loan-refinance-history { loan-id: loan-id })
)

(define-read-only (check-refinance-eligibility (loan-id uint))
  (match (map-get? loans { loan-id: loan-id })
    loan
    (match (map-get? borrower-profiles { borrower: (get borrower loan) })
      profile
      (let
        (
          (current-block u0)
          (blocks-elapsed (- current-block (get issue-block loan)))
          (reputation (get reputation-score profile))
          (remaining (get remaining-balance loan))
          (is-active (is-eq (get status loan) "active"))
          (not-refinanced (is-none (map-get? loan-refinance-history { loan-id: loan-id })))
          (min-blocks-passed (>= blocks-elapsed u1440))
        )
        {
          eligible: (and 
            is-active
            not-refinanced
            min-blocks-passed
            (>= reputation u200)
            (> remaining u0)
          ),
          reputation-score: reputation,
          blocks-elapsed: blocks-elapsed,
          min-blocks-required: u1440,
          remaining-balance: remaining,
          estimated-new-rate: (if (>= reputation u500)
                                u250
                                (if (>= reputation u300)
                                  u350
                                  u400)),
          current-rate: (get interest-rate loan)
        }
      )
      { 
        eligible: false, 
        reputation-score: u0, 
        blocks-elapsed: u0, 
        min-blocks-required: u1440, 
        remaining-balance: u0,
        estimated-new-rate: u0,
        current-rate: u0
      }
    )
    { 
      eligible: false, 
      reputation-score: u0, 
      blocks-elapsed: u0, 
      min-blocks-required: u1440, 
      remaining-balance: u0,
      estimated-new-rate: u0,
      current-rate: u0
    }
  )
)

(define-read-only (estimate-refinance-savings (loan-id uint) (new-duration-blocks uint))
  (match (map-get? loans { loan-id: loan-id })
    loan
    (match (map-get? borrower-profiles { borrower: (get borrower loan) })
      profile
      (let
        (
          (remaining (get remaining-balance loan))
          (reputation (get reputation-score profile))
          (new-rate (if (>= reputation u500)
                      u250
                      (if (>= reputation u300)
                        u350
                        u400)))
          (old-interest (/ (* remaining INTEREST_RATE_BASIS_POINTS) u10000))
          (new-interest (/ (* remaining new-rate) u10000))
          (interest-saved (- old-interest new-interest))
          (platform-fee (/ (* remaining PLATFORM_FEE_BASIS_POINTS) u10000))
          (new-total-due (+ remaining new-interest platform-fee))
        )
        (some {
          original-balance: remaining,
          old-interest-rate: INTEREST_RATE_BASIS_POINTS,
          new-interest-rate: new-rate,
          old-interest-amount: old-interest,
          new-interest-amount: new-interest,
          interest-saved: interest-saved,
          new-total-due: new-total-due,
          savings-percentage: (/ (* interest-saved u100) old-interest)
        })
      )
      none
    )
    none
  )
)

(define-read-only (get-refinance-stats)
  {
    total-refinanced-loans: (var-get total-refinanced-loans),
    next-refinance-id: (var-get next-refinance-id)
  }
)

(define-public (request-grace-period-extension (loan-id uint))
  (let
    (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR_LOAN_NOT_FOUND))
      (borrower tx-sender)
      (current-block u0)
      (extension-id (var-get next-extension-id))
      (current-extensions (default-to { count: u0 } (map-get? loan-extension-count { loan-id: loan-id })))
      (extension-count (get count current-extensions))
      (remaining-balance (get remaining-balance loan))
      (extension-fee (/ (* remaining-balance GRACE_EXTENSION_FEE_BASIS_POINTS) u10000))
      (current-due-block (get repayment-due-block loan))
      (new-due-block (+ current-due-block GRACE_PERIOD_BLOCKS))
    )
    (asserts! (var-get contract-active) ERR_OWNER_ONLY)
    (asserts! (is-eq borrower (get borrower loan)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status loan) "active") ERR_LOAN_ALREADY_REPAID)
    (asserts! (> remaining-balance u0) ERR_NO_OUTSTANDING_BALANCE)
    (asserts! (< extension-count MAX_GRACE_EXTENSIONS) ERR_MAX_EXTENSIONS_REACHED)

    (try! (stx-transfer? extension-fee borrower (as-contract tx-sender)))

    (map-set loans
      { loan-id: loan-id }
      (merge loan {
        repayment-due-block: new-due-block,
        amount-due: (+ (get amount-due loan) extension-fee),
        remaining-balance: (+ remaining-balance extension-fee)
      })
    )

    (map-set grace-period-extensions
      { extension-id: extension-id }
      {
        loan-id: loan-id,
        borrower: borrower,
        extension-block: current-block,
        original-due-block: current-due-block,
        new-due-block: new-due-block,
        extension-fee: extension-fee,
        extension-number: (+ extension-count u1)
      }
    )

    (map-set loan-extension-count
      { loan-id: loan-id }
      { count: (+ extension-count u1) }
    )

    (var-set next-extension-id (+ extension-id u1))
    (var-set total-extensions-granted (+ (var-get total-extensions-granted) u1))

    (ok {
      extension-id: extension-id,
      new-due-block: new-due-block,
      extension-fee: extension-fee,
      extensions-remaining: (- MAX_GRACE_EXTENSIONS (+ extension-count u1))
    })
  )
)

(define-read-only (get-extension-details (extension-id uint))
  (map-get? grace-period-extensions { extension-id: extension-id })
)

(define-read-only (get-loan-extension-count (loan-id uint))
  (match (map-get? loan-extension-count { loan-id: loan-id })
    entry (get count entry)
    u0
  )
)

(define-read-only (check-extension-eligibility (loan-id uint))
  (match (map-get? loans { loan-id: loan-id })
    loan
    (let
      (
        (extension-count (get-loan-extension-count loan-id))
        (remaining (get remaining-balance loan))
        (is-active (is-eq (get status loan) "active"))
        (has-balance (> remaining u0))
        (extensions-available (< extension-count MAX_GRACE_EXTENSIONS))
        (extension-fee (/ (* remaining GRACE_EXTENSION_FEE_BASIS_POINTS) u10000))
      )
      {
        eligible: (and is-active has-balance extensions-available),
        current-extensions: extension-count,
        max-extensions: MAX_GRACE_EXTENSIONS,
        extensions-remaining: (- MAX_GRACE_EXTENSIONS extension-count),
        estimated-fee: extension-fee,
        extension-duration-blocks: GRACE_PERIOD_BLOCKS
      }
    )
    {
      eligible: false,
      current-extensions: u0,
      max-extensions: MAX_GRACE_EXTENSIONS,
      extensions-remaining: u0,
      estimated-fee: u0,
      extension-duration-blocks: GRACE_PERIOD_BLOCKS
    }
  )
)

(define-read-only (get-extension-stats)
  {
    total-extensions-granted: (var-get total-extensions-granted),
    next-extension-id: (var-get next-extension-id)
  }
)
