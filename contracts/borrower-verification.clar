;; Borrower Verification Contract
;; This contract validates loan recipients by checking their eligibility

(define-data-var admin principal tx-sender)

;; Data map to store verified borrowers
(define-map verified-borrowers principal bool)

;; Data map to store borrower credit scores
(define-map borrower-scores principal uint)

;; Minimum credit score required for verification
(define-data-var min-credit-score uint u650)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-verified (err u102))
(define-constant err-low-credit-score (err u103))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set admin new-admin))))

;; Set minimum credit score
(define-public (set-min-credit-score (score uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set min-credit-score score))))

;; Add a borrower to the verified list
(define-public (verify-borrower (borrower principal) (credit-score uint))
  (begin
    (asserts! (is-admin) err-not-admin)
    (asserts! (>= credit-score (var-get min-credit-score)) err-low-credit-score)
    (asserts! (is-none (map-get? verified-borrowers borrower)) err-already-verified)
    (map-set borrower-scores borrower credit-score)
    (map-set verified-borrowers borrower true)
    (ok true)))

;; Remove a borrower from the verified list
(define-public (revoke-verification (borrower principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (asserts! (is-some (map-get? verified-borrowers borrower)) err-not-verified)
    (map-delete verified-borrowers borrower)
    (ok true)))

;; Check if a borrower is verified
(define-read-only (is-verified (borrower principal))
  (default-to false (map-get? verified-borrowers borrower)))

;; Get borrower's credit score
(define-read-only (get-credit-score (borrower principal))
  (default-to u0 (map-get? borrower-scores borrower)))
