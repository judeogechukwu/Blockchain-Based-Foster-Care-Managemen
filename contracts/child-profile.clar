;; Child Profile Contract - Ultra Simplified
;; Manages information about children in foster care

;; Error codes
(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_ALREADY_EXISTS u409)

;; Data maps
(define-map child-profiles
  { id: uint }
  {
    age: uint,
    special-needs: uint,  ;; 0=none, 1=low, 2=medium, 3=high
    status: uint,         ;; 1=active, 2=placed, 3=reunified, 4=adopted
    case-worker: principal,
    registration-date: uint
  }
)

;; Initialize contract admin
(define-data-var contract-admin principal tx-sender)

;; Register a new child
(define-public (register-child
    (id uint)
    (age uint)
    (special-needs uint)
    (case-worker principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? child-profiles {id: id})) (err ERR_ALREADY_EXISTS))
    (ok (map-set child-profiles
      {id: id}
      {
        age: age,
        special-needs: special-needs,
        status: u1,
        case-worker: case-worker,
        registration-date: block-height
      }
    ))
  )
)

;; Update child status
(define-public (update-child-status (id uint) (new-status uint))
  (let ((profile (unwrap! (map-get? child-profiles {id: id}) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-admin)) (err ERR_UNAUTHORIZED))
      (ok (map-set child-profiles
        {id: id}
        {
          age: (get age profile),
          special-needs: (get special-needs profile),
          status: new-status,
          case-worker: (get case-worker profile),
          registration-date: (get registration-date profile)
        }
      ))
    )
  )
)

;; Get child profile (read-only)
(define-read-only (get-child-profile (id uint))
  (map-get? child-profiles {id: id})
)

