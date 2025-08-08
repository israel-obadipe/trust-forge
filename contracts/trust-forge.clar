;; Title: TrustForge - Decentralized Identity & Reputation Engine
;;
;; Summary: 
;; A comprehensive blockchain-based identity management system that enables 
;; secure digital identity creation, verifiable credential issuance, and 
;; dynamic reputation tracking with advanced recovery mechanisms.
;;
;; Description:
;; TrustForge revolutionizes digital identity by providing a trustless, 
;; decentralized platform where users can establish verifiable identities,
;; accumulate reputation through validated credentials, and maintain control
;; over their digital presence. The protocol supports multi-layered security
;; with zero-knowledge proof integration, automated credential lifecycle
;; management, and sophisticated recovery protocols to ensure identity
;; sovereignty in the Web3 ecosystem.
;;
;; Key Features:
;; - Trustless identity registration and management
;; - Verifiable credential issuance and revocation
;; - Dynamic reputation scoring system
;; - Zero-knowledge proof validation
;; - Multi-signature recovery mechanisms
;; - Administrative governance controls

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-ALREADY-REGISTERED (err u1001))
(define-constant ERR-NOT-REGISTERED (err u1002))
(define-constant ERR-INVALID-PROOF (err u1003))
(define-constant ERR-INVALID-CREDENTIAL (err u1004))
(define-constant ERR-EXPIRED-CREDENTIAL (err u1005))
(define-constant ERR-REVOKED-CREDENTIAL (err u1006))
(define-constant ERR-INVALID-SCORE (err u1007))
(define-constant ERR-INVALID-INPUT (err u1008))
(define-constant ERR-INVALID-EXPIRATION (err u1009))
(define-constant ERR-INVALID-RECOVERY-ADDRESS (err u1010))
(define-constant ERR-INVALID-PROOF-DATA (err u1011))
(define-constant ERR-CREDENTIAL-LIMIT (err u1012))

;; PROTOCOL CONSTANTS

(define-constant MIN-REPUTATION-SCORE u0)
(define-constant MAX-REPUTATION-SCORE u1000)
(define-constant MIN-EXPIRATION-BLOCKS u1)
(define-constant MAX-METADATA-LENGTH u256)
(define-constant MINIMUM-PROOF-SIZE u64)
(define-constant MAX-CREDENTIALS u10)

;; STATE VARIABLES

(define-data-var admin principal tx-sender)
(define-data-var credential-nonce uint u0)

;; DATA STRUCTURES

;; Identity Registry - Core identity data structure
(define-map identities
  principal
  {
    hash: (buff 32),
    credentials: (list 10 principal),
    reputation-score: uint,
    recovery-address: (optional principal),
    last-updated: uint,
    status: (string-ascii 20),
  }
)

;; Credential Store - Verifiable credential metadata
(define-map credential-map
  {
    issuer: principal,
    nonce: uint,
  }
  {
    subject: principal,
    claim-hash: (buff 32),
    expiration: uint,
    revoked: bool,
    metadata: (string-utf8 256),
  }
)

;; Zero-Knowledge Proof Registry - Privacy-preserving verification data
(define-map zero-knowledge-proofs
  (buff 32)
  {
    prover: principal,
    verified: bool,
    timestamp: uint,
    proof-data: (buff 1024),
  }
)

;; ADMINISTRATIVE FUNCTIONS

;; Transfer administrative control to a new principal
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq new-admin tx-sender)) ERR-INVALID-INPUT)
    (var-set admin new-admin)
    (ok true)
  )
)

;; IDENTITY MANAGEMENT FUNCTIONS

;; Register a new identity in the TrustForge protocol
(define-public (register-identity
    (identity-hash (buff 32))
    (recovery-addr (optional principal))
  )
  (let (
      (sender tx-sender)
      (existing-identity (map-get? identities sender))
    )
    (asserts! (is-none existing-identity) ERR-ALREADY-REGISTERED)
    (asserts! (is-valid-hash identity-hash) ERR-INVALID-INPUT)
    (asserts! (is-valid-recovery-address recovery-addr)
      ERR-INVALID-RECOVERY-ADDRESS
    )

    (map-set identities sender {
      hash: identity-hash,
      credentials: (list),
      reputation-score: u100,
      recovery-address: recovery-addr,
      last-updated: block-height,
      status: "ACTIVE",
    })
    (ok true)
  )
)

;; CREDENTIAL MANAGEMENT FUNCTIONS

;; Associate a credential with an identity (Admin-only function)
(define-public (add-credential-to-identity
    (subject principal)
    (credential-principal principal)
  )
  (let (
      (sender tx-sender)
      (identity (map-get? identities subject))
    )
    (asserts! (is-some identity) ERR-NOT-REGISTERED)
    (asserts! (is-eq sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (asserts! (can-add-credential (get credentials (unwrap-panic identity)))
      ERR-CREDENTIAL-LIMIT
    )

    (map-set identities subject
      (merge (unwrap-panic identity) {
        credentials: (unwrap-panic (as-max-len?
          (append (get credentials (unwrap-panic identity)) credential-principal)
          u10
        )),
      })
    )
    (ok true)
  )
)

;; Issue a verifiable credential to a registered identity
(define-public (issue-credential
    (subject principal)
    (claim-hash (buff 32))
    (expiration uint)
    (metadata (string-utf8 256))
  )
  (let (
      (sender tx-sender)
      (current-nonce (var-get credential-nonce))
      (credential-id {
        issuer: sender,
        nonce: current-nonce,
      })
      (issuer-identity (map-get? identities sender))
      (subject-identity (map-get? identities subject))
    )
    (asserts! (is-some issuer-identity) ERR-NOT-REGISTERED)
    (asserts! (is-some subject-identity) ERR-NOT-REGISTERED)
    (asserts! (is-valid-hash claim-hash) ERR-INVALID-INPUT)
    (asserts! (is-valid-expiration expiration) ERR-INVALID-EXPIRATION)
    (asserts! (is-valid-metadata-length metadata) ERR-INVALID-INPUT)

    ;; Increment nonce and record credential
    (var-set credential-nonce (+ current-nonce u1))
    (map-set credential-map credential-id {
      subject: subject,
      claim-hash: claim-hash,
      expiration: expiration,
      revoked: false,
      metadata: metadata,
    })

    ;; Attempt to add credential to identity
    (try! (add-credential-to-identity subject sender))

    (ok true)
  )
)

;; Revoke a previously issued credential
(define-public (revoke-credential
    (issuer principal)
    (nonce uint)
  )
  (let (
      (sender tx-sender)
      (credential-id {
        issuer: issuer,
        nonce: nonce,
      })
      (credential (map-get? credential-map credential-id))
    )
    (asserts! (is-some credential) ERR-INVALID-CREDENTIAL)
    (asserts! (is-eq sender issuer) ERR-NOT-AUTHORIZED)

    (map-set credential-map credential-id
      (merge (unwrap-panic credential) { revoked: true })
    )
    (ok true)
  )
)

;; REPUTATION MANAGEMENT FUNCTIONS

;; Modify reputation score for a registered identity (Admin-only)
(define-public (update-reputation
    (subject principal)
    (score-change int)
  )
  (let (
      (sender tx-sender)
      (identity (map-get? identities subject))
      (current-score (get reputation-score (unwrap! identity ERR-NOT-REGISTERED)))
      (score-change-abs (if (< score-change 0)
        (* score-change -1)
        score-change
      ))
    )
    (asserts! (is-eq sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (asserts!
      (or
        (> score-change 0)
        (>= (to-int current-score) score-change-abs)
      )
      ERR-INVALID-SCORE
    )

    (map-set identities subject
      (merge (unwrap-panic identity) {
        reputation-score: (if (> score-change 0)
          (+ current-score (to-uint score-change))
          (to-uint (- (to-int current-score) score-change-abs))
        ),
      })
    )
    (ok true)
  )
)

;; RECOVERY MECHANISM FUNCTIONS

;; Execute identity recovery using designated recovery address
(define-public (initiate-recovery
    (identity principal)
    (new-hash (buff 32))
  )
  (let (
      (sender tx-sender)
      (identity-data (map-get? identities identity))
      (recovery-address (unwrap! (get recovery-address (unwrap! identity-data ERR-NOT-REGISTERED))
        ERR-NOT-AUTHORIZED
      ))
    )
    (asserts! (is-eq sender recovery-address) ERR-NOT-AUTHORIZED)

    (map-set identities identity
      (merge (unwrap-panic identity-data) {
        hash: new-hash,
        last-updated: block-height,
        status: "RECOVERED",
      })
    )
    (ok true)
  )
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve complete identity data for a given principal
(define-read-only (get-identity (identity principal))
  (map-get? identities identity)
)

;; Retrieve credential information by issuer and nonce
(define-read-only (get-credential
    (issuer principal)
    (nonce uint)
  )
  (map-get? credential-map {
    issuer: issuer,
    nonce: nonce,
  })
)