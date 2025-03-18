;; Service Coordination Contract - Ultra Simplified
;; Manages support services for children and families

;; Error codes
(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_ALREADY_EXISTS u409)

;; Data maps
(define-map services
  { id: uint }
  {
    service-type: uint,    ;; 1=counseling, 2=education, 3=medical, 4=transportation, 5=respite
    recipient-id: uint,
    recipient-type: uint,  ;; 1=child, 2=foster home
    provider: principal,
    requester: principal,
    status: uint,          ;; 1=requested, 2=approved, 3=in-progress, 4=completed, 5=cancelled
    request-date: uint,
    completion-date: uint,
    notes: uint
  }
)

;; Track service count
(define-data-var service-count uint u0)

;; Initialize contract admin
(define-data-var contract-admin principal tx-sender)

;; Request a service
(define-public (request-service
    (service-type uint)
    (recipient-id uint)
    (recipient-type uint)
    (provider principal)
    (notes uint))
  (let ((new-id (+ (var-get service-count) u1)))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-admin)) (err ERR_UNAUTHORIZED))
      (var-set service-count new-id)
      (ok (map-set services
        {id: new-id}
        {
          service-type: service-type,
          recipient-id: recipient-id,
          recipient-type: recipient-type,
          provider: provider,
          requester: tx-sender,
          status: u1,
          request-date: block-height,
          completion-date: u0,
          notes: notes
        }
      ))
    )
  )
)

;; Update service status
(define-public (update-service-status
    (id uint)
    (new-status uint))
  (let ((service (unwrap! (map-get? services {id: id}) (err ERR_NOT_FOUND))))
    (begin
      (asserts! (or
                  (is-eq tx-sender (var-get contract-admin))
                  (is-eq tx-sender (get provider service))
                )
                (err ERR_UNAUTHORIZED))
      (ok (map-set services
        {id: id}
        {
          service-type: (get service-type service),
          recipient-id: (get recipient-id service),
          recipient-type: (get recipient-type service),
          provider: (get provider service),
          requester: (get requester service),
          status: new-status,
          request-date: (get request-date service),
          completion-date: (if (is-eq new-status u4) block-height (get completion-date service)),
          notes: (get notes service)
        }
      ))
    )
  )
)

;; Get service details (read-only)
(define-read-only (get-service (id uint))
  (map-get? services {id: id})
)

;; Get service for recipient (read-only)
(define-read-only (get-service-for-recipient (recipient-id uint) (recipient-type uint) (service-id uint))
  (let ((service (map-get? services {id: service-id})))
    (if (and
          (is-some service)
          (is-eq (get recipient-id (unwrap! service none)) recipient-id)
          (is-eq (get recipient-type (unwrap! service none)) recipient-type))
      service
      none
    )
  )
)

