;; Collateral Valuation Contract
;; This contract assesses asset values for collateral

(define-data-var admin principal tx-sender)

;; Data map to store asset types and their price oracles
(define-map asset-oracles (string-ascii 32) principal)

;; Data map to store asset values
(define-map asset-values (tuple (asset-type (string-ascii 32)) (asset-id uint)) uint)

;; Minimum collateralization ratio (in basis points, 15000 = 150%)
(define-data-var min-collateral-ratio uint u15000)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-oracle-not-found (err u101))
(define-constant err-asset-not-found (err u102))
(define-constant err-insufficient-collateral (err u103))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set admin new-admin))))

;; Set minimum collateralization ratio
(define-public (set-min-collateral-ratio (ratio uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set min-collateral-ratio ratio))))

;; Register a price oracle for an asset type
(define-public (register-oracle (asset-type (string-ascii 32)) (oracle principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (map-set asset-oracles asset-type oracle))))

;; Update asset value (only callable by registered oracle)
(define-public (update-asset-value (asset-type (string-ascii 32)) (asset-id uint) (value uint))
  (let ((oracle (default-to tx-sender (map-get? asset-oracles asset-type))))
    (begin
      (asserts! (is-eq tx-sender oracle) err-not-admin)
      (ok (map-set asset-values (tuple (asset-type asset-type) (asset-id asset-id)) value)))))

;; Get asset value
(define-read-only (get-asset-value (asset-type (string-ascii 32)) (asset-id uint))
  (default-to u0 (map-get? asset-values (tuple (asset-type asset-type) (asset-id asset-id)))))

;; Check if collateral is sufficient for a loan
(define-read-only (is-collateral-sufficient (asset-type (string-ascii 32)) (asset-id uint) (loan-amount uint))
  (let (
    (asset-value (get-asset-value asset-type asset-id))
    (required-value (/ (* loan-amount (var-get min-collateral-ratio)) u10000))
  )
    (>= asset-value required-value)))
