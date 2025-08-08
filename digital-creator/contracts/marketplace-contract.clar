;; Digital Asset Studio - Creator Economy Platform
;; A decentralized marketplace for digital tools and services

;; Constants
(define-constant contract-creator tx-sender)
(define-constant err-creator-only (err u200))
(define-constant err-asset-not-found (err u201))
(define-constant err-access-denied (err u202))
(define-constant err-payment-failed (err u203))
(define-constant err-asset-exists (err u204))
(define-constant err-invalid-tier (err u205))

;; Data Variables
(define-data-var platform-commission uint u300) ;; 3% platform fee

;; Data Maps
(define-map digital-assets
  { asset-key: (string-ascii 48) }
  {
    creator: principal,
    title: (string-utf8 80),
    summary: (string-utf8 300),
    tier: (string-ascii 20), ;; "basic", "premium", "enterprise"
    one-time-cost: uint,
    subscription-cost: uint,
    downloads: uint,
    earnings: uint,
    is-live: bool,
    content-hash: (string-ascii 48)
  }
)

(define-map user-licenses
  { owner: principal, asset-key: (string-ascii 48) }
  {
    license-type: (string-ascii 12), ;; "subscription" or "permanent"
    valid-until: uint,
    access-count: uint,
    amount-spent: uint
  }
)

(define-map asset-ratings
  { asset-key: (string-ascii 48), rater: principal }
  {
    stars: uint, ;; 1-5 rating system
    comment: (string-utf8 400),
    timestamp: uint
  }
)

(define-map creator-balances principal uint)

;; Read-only functions
(define-read-only (get-asset (asset-key (string-ascii 48)))
  (map-get? digital-assets { asset-key: asset-key })
)

(define-read-only (get-license (owner principal) (asset-key (string-ascii 48)))
  (map-get? user-licenses { owner: owner, asset-key: asset-key })
)

(define-read-only (get-rating (asset-key (string-ascii 48)) (rater principal))
  (map-get? asset-ratings { asset-key: asset-key, rater: rater })
)

(define-read-only (get-creator-balance (creator principal))
  (default-to u0 (map-get? creator-balances creator))
)

(define-read-only (has-access (owner principal) (asset-key (string-ascii 48)))
  (let (
    (license (get-license owner asset-key))
  )
    (match license
      license-data
        (or 
          (> (get access-count license-data) u0)
          (> (get valid-until license-data) block-height)
        )
      false
    )
  )
)

;; Public functions

;; Publish a new digital asset
(define-public (publish-asset
    (asset-key (string-ascii 48))
    (title (string-utf8 80))
    (summary (string-utf8 300))
    (tier (string-ascii 20))
    (one-time-cost uint)
    (subscription-cost uint)
    (content-hash (string-ascii 48))
  )
  (let (
    (existing-asset (get-asset asset-key))
  )
    (asserts! (is-none existing-asset) err-asset-exists)
    (ok (map-set digital-assets
      { asset-key: asset-key }
      {
        creator: tx-sender,
        title: title,
        summary: summary,
        tier: tier,
        one-time-cost: one-time-cost,
        subscription-cost: subscription-cost,
        downloads: u0,
        earnings: u0,
        is-live: true,
        content-hash: content-hash
      }
    ))
  )
)

;; Purchase permanent license
(define-public (buy-permanent-license (asset-key (string-ascii 48)))
  (let (
    (asset (unwrap! (get-asset asset-key) err-asset-not-found))
    (price (get one-time-cost asset))
    (commission (/ (* price (var-get platform-commission)) u10000))
    (creator-share (- price commission))
  )
    (asserts! (get is-live asset) err-asset-not-found)
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
    
    ;; Update asset metrics
    (map-set digital-assets
      { asset-key: asset-key }
      (merge asset {
        downloads: (+ (get downloads asset) u1),
        earnings: (+ (get earnings asset) price)
      })
    )
    
    ;; Grant license
    (map-set user-licenses
      { owner: tx-sender, asset-key: asset-key }
      {
        license-type: "permanent",
        valid-until: u0,
        access-count: u999999, ;; Unlimited access
        amount-spent: price
      }
    )
    
    ;; Credit creator
    (map-set creator-balances
      (get creator asset)
      (+ (get-creator-balance (get creator asset)) creator-share)
    )
    
    (ok true)
  )
)

;; Subscribe to asset
(define-public (subscribe-to-asset (asset-key (string-ascii 48)))
  (let (
    (asset (unwrap! (get-asset asset-key) err-asset-not-found))
    (price (get subscription-cost asset))
    (commission (/ (* price (var-get platform-commission)) u10000))
    (creator-share (- price commission))
  )
    (asserts! (get is-live asset) err-asset-not-found)
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
    
    ;; Update asset metrics
    (map-set digital-assets
      { asset-key: asset-key }
      (merge asset {
        downloads: (+ (get downloads asset) u1),
        earnings: (+ (get earnings asset) price)
      })
    )
    
    ;; Grant subscription
    (map-set user-licenses
      { owner: tx-sender, asset-key: asset-key }
      {
        license-type: "subscription",
        valid-until: (+ block-height u4320), ;; 30 days
        access-count: u0,
        amount-spent: price
      }
    )
    
    ;; Credit creator
    (map-set creator-balances
      (get creator asset)
      (+ (get-creator-balance (get creator asset)) creator-share)
    )
    
    (ok true)
  )
)

;; Access asset (for usage tracking)
(define-public (access-asset (asset-key (string-ascii 48)))
  (let (
    (asset (unwrap! (get-asset asset-key) err-asset-not-found))
    (license (unwrap! (get-license tx-sender asset-key) err-access-denied))
  )
    (asserts! (get is-live asset) err-asset-not-found)
    (asserts! (has-access tx-sender asset-key) err-access-denied)
    
    (if (is-eq (get license-type license) "permanent")
      (ok true)
      (begin
        (asserts! (> (get valid-until license) block-height) err-access-denied)
        (ok true)
      )
    )
  )
)

;; Rate an asset
(define-public (rate-asset
    (asset-key (string-ascii 48))
    (stars uint)
    (comment (string-utf8 400))
  )
  (let (
    (asset (unwrap! (get-asset asset-key) err-asset-not-found))
  )
    (asserts! (and (>= stars u1) (<= stars u5)) err-invalid-tier)
    (asserts! (has-access tx-sender asset-key) err-access-denied)
    
    (ok (map-set asset-ratings
      { asset-key: asset-key, rater: tx-sender }
      {
        stars: stars,
        comment: comment,
        timestamp: block-height
      }
    ))
  )
)

;; Creator withdraws earnings
(define-public (withdraw-balance)
  (let (
    (balance (get-creator-balance tx-sender))
  )
    (asserts! (> balance u0) err-asset-not-found)
    (try! (as-contract (stx-transfer? balance tx-sender tx-sender)))
    (map-set creator-balances tx-sender u0)
    (ok balance)
  )
)

;; Update asset details
(define-public (modify-asset
    (asset-key (string-ascii 48))
    (title (string-utf8 80))
    (summary (string-utf8 300))
    (one-time-cost uint)
    (subscription-cost uint)
    (content-hash (string-ascii 48))
    (is-live bool)
  )
  (let (
    (asset (unwrap! (get-asset asset-key) err-asset-not-found))
  )
    (asserts! (is-eq (get creator asset) tx-sender) err-access-denied)
    
    (ok (map-set digital-assets
      { asset-key: asset-key }
      (merge asset {
        title: title,
        summary: summary,
        one-time-cost: one-time-cost,
        subscription-cost: subscription-cost,
        content-hash: content-hash,
        is-live: is-live
      })
    ))
  )
)

;; Admin function
(define-public (update-commission (new-commission uint))
  (begin
    (asserts! (is-eq tx-sender contract-creator) err-creator-only)
    (asserts! (<= new-commission u1500) err-invalid-tier) ;; Max 15%
    (ok (var-set platform-commission new-commission))
  )
)