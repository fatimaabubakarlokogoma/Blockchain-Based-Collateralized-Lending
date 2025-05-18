;; Liquidation Contract
;; This contract handles default resolution

(define-data-var admin principal tx-sender)

;; Liquidation data structure
(define-map liquidations
  uint  ;; loan-id
  {
    liquidator: principal,
    liquidation-price: uint,
    liquidation-block: uint,
    status: uint  ;; 0: pending, 1: completed, 2: canceled
  }
)

;; Constants for liquidation status
(define-constant STATUS-PENDING u0)
(define-constant STATUS-COMPLETED u1)
(define-constant STATUS-CANCELED u2)

;; Liquidation fee percentage (in basis points, 500 = 5%)
(define-data-var liquidation-fee uint u500)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-liquidation-not-found (err u101))
(define-constant err-invalid-status (err u102))
(define-constant err-not-liquidator (err u103))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set admin new-admin))))

;; Set liquidation fee
(define-public (set-liquidation-fee (fee uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set liquidation-fee fee))))

;; Initiate liquidation process
(define-public (initiate-liquidation (loan-id uint) (liquidation-price uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (map-set liquidations loan-id {
      liquidator: tx-sender,
      liquidation-price: liquidation-price,
      liquidation-block: block-height,
      status: STATUS-PENDING
    })
    (ok true)))

;; Complete liquidation
(define-public (complete-liquidation (loan-id uint))
  (let ((liquidation (unwrap! (map-get? liquidations loan-id) err-liquidation-not-found)))
    (begin
      (asserts! (is-admin) err-not-admin)
      (asserts! (is-eq (get status liquidation) STATUS-PENDING) err-invalid-status)
      (map-set liquidations loan-id (merge liquidation {status: STATUS-COMPLETED}))
      (ok true))))

;; Cancel liquidation
(define-public (cancel-liquidation (loan-id uint))
  (let ((liquidation (unwrap! (map-get? liquidations loan-id) err-liquidation-not-found)))
    (begin
      (asserts! (is-admin) err-not-admin)
      (asserts! (is-eq (get status liquidation) STATUS-PENDING) err-invalid-status)
      (map-set liquidations loan-id (merge liquidation {status: STATUS-CANCELED}))
      (ok true))))

;; Get liquidation details
(define-read-only (get-liquidation (loan-id uint))
  (map-get? liquidations loan-id))

;; Calculate liquidation fee
(define-read-only (calculate-liquidation-fee (amount uint))
  (/ (* amount (var-get liquidation-fee)) u10000))
