;; Income-Verify: Income/Employment Verification Smart Contract
;; Self-sovereign identity verification on Stacks blockchain

;; Contract constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_DATA (err u103))
(define-constant ERR_EXPIRED (err u104))
(define-constant ERR_NOT_VERIFIED (err u105))

;; Data structures
(define-map identities
  { user: principal }
  {
    verified: bool,
    created-at: uint,
    updated-at: uint,
    verification-count: uint
  }
)

(define-map employment-records
  { user: principal, record-id: uint }
  {
    employer: (string-ascii 100),
    position: (string-ascii 100),
    start-date: uint,
    end-date: (optional uint),
    verified: bool,
    verifier: (optional principal),
    verified-at: (optional uint)
  }
)

(define-map income-records
  { user: principal, record-id: uint }
  {
    amount: uint,
    currency: (string-ascii 10),
    period: (string-ascii 20), ;; "monthly", "yearly", "hourly"
    source: (string-ascii 100),
    verified: bool,
    verifier: (optional principal),
    verified-at: (optional uint),
    valid-until: uint
  }
)

(define-map authorized-verifiers
  { verifier: principal }
  {
    name: (string-ascii 100),
    authorized: bool,
    authorized-at: uint,
    verification-count: uint
  }
)

;; Data variables
(define-data-var next-employment-id uint u1)
(define-data-var next-income-id uint u1)

;; Public functions

;; Initialize user identity
(define-public (create-identity)
  (let ((user tx-sender))
    (match (map-get? identities { user: user })
      existing-identity ERR_ALREADY_EXISTS
      (ok (map-set identities
        { user: user }
        {
          verified: false,
          created-at: block-height,
          updated-at: block-height,
          verification-count: u0
        }
      ))
    )
  )
)

;; Add employment record
(define-public (add-employment-record 
  (employer (string-ascii 100))
  (position (string-ascii 100))
  (start-date uint)
  (end-date (optional uint)))
  (let (
    (user tx-sender)
    (record-id (var-get next-employment-id))
  )
    ;; Ensure user has identity
    (match (map-get? identities { user: user })
      identity-data
      (begin
        (map-set employment-records
          { user: user, record-id: record-id }
          {
            employer: employer,
            position: position,
            start-date: start-date,
            end-date: end-date,
            verified: false,
            verifier: none,
            verified-at: none
          }
        )
        (var-set next-employment-id (+ record-id u1))
        (ok record-id)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Add income record
(define-public (add-income-record
  (amount uint)
  (currency (string-ascii 10))
  (period (string-ascii 20))
  (source (string-ascii 100))
  (valid-duration uint)) ;; blocks until expiry
  (let (
    (user tx-sender)
    (record-id (var-get next-income-id))
    (valid-until (+ block-height valid-duration))
  )
    ;; Ensure user has identity
    (match (map-get? identities { user: user })
      identity-data
      (begin
        (map-set income-records
          { user: user, record-id: record-id }
          {
            amount: amount,
            currency: currency,
            period: period,
            source: source,
            verified: false,
            verifier: none,
            verified-at: none,
            valid-until: valid-until
          }
        )
        (var-set next-income-id (+ record-id u1))
        (ok record-id)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Authorize verifier (only contract owner)
(define-public (authorize-verifier 
  (verifier principal)
  (name (string-ascii 100)))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (map-set authorized-verifiers
        { verifier: verifier }
        {
          name: name,
          authorized: true,
          authorized-at: block-height,
          verification-count: u0
        }
      )
      (ok true)
    )
    ERR_UNAUTHORIZED
  )
)

;; Revoke verifier authorization (only contract owner)
(define-public (revoke-verifier (verifier principal))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (match (map-get? authorized-verifiers { verifier: verifier })
      verifier-data
      (begin
        (map-set authorized-verifiers
          { verifier: verifier }
          (merge verifier-data { authorized: false })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
    ERR_UNAUTHORIZED
  )
)

;; Verify employment record
(define-public (verify-employment
  (user principal)
  (record-id uint))
  (let ((verifier tx-sender))
    ;; Check if verifier is authorized
    (match (map-get? authorized-verifiers { verifier: verifier })
      verifier-data
      (if (get authorized verifier-data)
        ;; Verify the employment record
        (match (map-get? employment-records { user: user, record-id: record-id })
          employment-data
          (begin
            ;; Update employment record
            (map-set employment-records
              { user: user, record-id: record-id }
              (merge employment-data {
                verified: true,
                verifier: (some verifier),
                verified-at: (some block-height)
              })
            )
            ;; Update verifier stats
            (map-set authorized-verifiers
              { verifier: verifier }
              (merge verifier-data {
                verification-count: (+ (get verification-count verifier-data) u1)
              })
            )
            ;; Update user identity stats
            (match (map-get? identities { user: user })
              identity-data
              (map-set identities
                { user: user }
                (merge identity-data {
                  verification-count: (+ (get verification-count identity-data) u1),
                  updated-at: block-height
                })
              )
              false
            )
            (ok true)
          )
          ERR_NOT_FOUND
        )
        ERR_UNAUTHORIZED
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Verify income record
(define-public (verify-income
  (user principal)
  (record-id uint))
  (let ((verifier tx-sender))
    ;; Check if verifier is authorized
    (match (map-get? authorized-verifiers { verifier: verifier })
      verifier-data
      (if (get authorized verifier-data)
        ;; Verify the income record
        (match (map-get? income-records { user: user, record-id: record-id })
          income-data
          (if (> (get valid-until income-data) block-height)
            (begin
              ;; Update income record
              (map-set income-records
                { user: user, record-id: record-id }
                (merge income-data {
                  verified: true,
                  verifier: (some verifier),
                  verified-at: (some block-height)
                })
              )
              ;; Update verifier stats
              (map-set authorized-verifiers
                { verifier: verifier }
                (merge verifier-data {
                  verification-count: (+ (get verification-count verifier-data) u1)
                })
              )
              ;; Update user identity stats
              (match (map-get? identities { user: user })
                identity-data
                (map-set identities
                  { user: user }
                  (merge identity-data {
                    verification-count: (+ (get verification-count identity-data) u1),
                    updated-at: block-height
                  })
                )
                false
              )
              (ok true)
            )
            ERR_EXPIRED
          )
          ERR_NOT_FOUND
        )
        ERR_UNAUTHORIZED
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Mark user identity as verified (only authorized verifiers)
(define-public (verify-identity (user principal))
  (let ((verifier tx-sender))
    (match (map-get? authorized-verifiers { verifier: verifier })
      verifier-data
      (if (get authorized verifier-data)
        (match (map-get? identities { user: user })
          identity-data
          (begin
            (map-set identities
              { user: user }
              (merge identity-data {
                verified: true,
                updated-at: block-height
              })
            )
            (ok true)
          )
          ERR_NOT_FOUND
        )
        ERR_UNAUTHORIZED
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Read-only functions

;; Get user identity
(define-read-only (get-identity (user principal))
  (map-get? identities { user: user })
)

;; Get employment record
(define-read-only (get-employment-record (user principal) (record-id uint))
  (map-get? employment-records { user: user, record-id: record-id })
)

;; Get income record
(define-read-only (get-income-record (user principal) (record-id uint))
  (map-get? income-records { user: user, record-id: record-id })
)

;; Get verifier info
(define-read-only (get-verifier-info (verifier principal))
  (map-get? authorized-verifiers { verifier: verifier })
)

;; Check if user identity is verified
(define-read-only (is-identity-verified (user principal))
  (match (map-get? identities { user: user })
    identity-data (ok (get verified identity-data))
    ERR_NOT_FOUND
  )
)

;; Check if employment record is verified
(define-read-only (is-employment-verified (user principal) (record-id uint))
  (match (map-get? employment-records { user: user, record-id: record-id })
    employment-data (ok (get verified employment-data))
    ERR_NOT_FOUND
  )
)

;; Check if income record is verified and not expired
(define-read-only (is-income-verified (user principal) (record-id uint))
  (match (map-get? income-records { user: user, record-id: record-id })
    income-data 
    (ok (and 
      (get verified income-data) 
      (> (get valid-until income-data) block-height)
    ))
    ERR_NOT_FOUND
  )
)

;; Get verification summary for user
(define-read-only (get-verification-summary (user principal))
  (match (map-get? identities { user: user })
    identity-data
    (ok {
      identity-verified: (get verified identity-data),
      total-verifications: (get verification-count identity-data),
      created-at: (get created-at identity-data),
      updated-at: (get updated-at identity-data)
    })
    ERR_NOT_FOUND
  )
)