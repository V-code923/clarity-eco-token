;; Define token
(define-fungible-token eco-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-verified (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-metrics (err u103))

;; Data vars
(define-map projects 
  { project-id: uint } 
  { 
    owner: principal,
    name: (string-ascii 64),
    description: (string-ascii 256),
    verified: bool,
    impact-score: uint,
    creation-time: uint
  }
)

(define-map project-metrics
  { project-id: uint }
  {
    carbon-offset: uint,
    trees-planted: uint,
    waste-recycled: uint
  }
)

(define-data-var project-counter uint u0)

;; Public functions
(define-public (register-project (name (string-ascii 64)) (description (string-ascii 256)))
  (let ((project-id (+ (var-get project-counter) u1)))
    (map-insert projects 
      { project-id: project-id }
      {
        owner: tx-sender,
        name: name,
        description: description,
        verified: false,
        impact-score: u0,
        creation-time: block-height
      }
    )
    (var-set project-counter project-id)
    (ok project-id))
)

(define-public (update-metrics 
  (project-id uint)
  (carbon-offset uint)
  (trees-planted uint)
  (waste-recycled uint)
)
  (let ((project (unwrap! (map-get? projects { project-id: project-id }) (err err-not-verified))))
    (asserts! (is-eq (get owner project) tx-sender) err-owner-only)
    (ok (map-set project-metrics
      { project-id: project-id }
      {
        carbon-offset: carbon-offset,
        trees-planted: trees-planted,
        waste-recycled: waste-recycled
      }
    ))
  )
)

(define-public (verify-project (project-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set projects 
      { project-id: project-id }
      (merge (unwrap! (map-get? projects { project-id: project-id }) err-already-registered)
        { verified: true })
    )
    (ok true))
)

(define-public (mint-rewards (project-id uint) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let ((project (unwrap! (map-get? projects { project-id: project-id }) (err err-not-verified))))
      (asserts! (get verified project) err-not-verified)
      (ft-mint? eco-token amount (get owner project))
    )
  )
)
