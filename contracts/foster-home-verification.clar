;; Foster Home Verification Contract - Ultra Simplified
;; Validates suitability of foster families

;; Error codes
(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_ALREADY_EXISTS u409)

;; Data maps
(define-map foster-homes
  { id: uint }
  {
    owner: principal,
    capacity: uint,
    verification-status: uint,  ;; 1=pending, 2=approved, 3=provisional, 4=denied, 5=revoked
    verification-date: uint,
    expiration-date: uint,
    verifier: principal
  }
)

;; Initialize contract admin
(define-data-var contract-admin principal tx-sender)

;; Register a new foster home
(define-public (register-foster-home
    (id uint)
    (capacity uint))
  (begin
    (asserts! (is-none (map-get? foster-homes {id: id})) (err ERR_ALREADY_EXISTS))
    (ok (map-set foster-homes
      {id: id}
      {
        owner: tx-sender,
        capacity: capacity,
        verification-status: u1,
        verification-date: u0,
        expiration-date: u0,
        verifier: tx-sender
      }
    ))
  )
)

;; Verify foster home
(define-public (verify-foster-home
    (id uint)
    (status uint)
    (expiration-date uint))
  (let ((home (unwrap! (map-get? foster-homes {id: id}) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-admin)) (err ERR_UNAUTHORIZED))
      (ok (map-set foster-homes
        {id: id}
        {
          owner: (get owner home),
          capacity: (get capacity home),
          verification-status: status,
          verification-date: block-height,
          expiration-date: expiration-date,
          verifier: tx-sender
        }
      ))
    )
  )
)

;; Get foster home details (read-only)
(define-read-only (get-foster-home (id uint))
  (map-get? foster-homes {id: id})
)

;; Check if home is currently verified (read-only)
(define-read-only (is-home-verified (id uint))
  (let ((home (default-to
                {
                  owner: tx-sender,
                  capacity: u0,
                  verification-status: u0,
                  verification-date: u0,
                  expiration-date: u0,
                  verifier: tx-sender
                }
                (map-get? foster-homes {id: id}))))
    (and
      (is-eq (get verification-status home) u2)
      (< block-height (get expiration-date home))
    )
  )
)

