;; CooperativeChain - Cooperative Member Governance System
;; Version: 1.0.0

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INITIATIVE_EXISTS (err u101))
(define-constant ERR_INITIATIVE_NOT_FOUND (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_INVALID_CHOICE (err u105))
(define-constant ERR_SELF_REPRESENTATION (err u106))
(define-constant ERR_REPRESENTATION_CYCLE (err u107))
(define-constant ERR_INVALID_INPUT (err u108))
(define-constant ERR_NOT_ENOUGH_EQUITY (err u109))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u110))

;; Data Variables
(define-data-var coop-manager principal tx-sender)
(define-data-var fiscal-year uint u0)

;; Maps
(define-map Initiatives
  { initiative-id: uint }
  {
    title: (string-ascii 50),
    alternatives: (list 10 (string-ascii 20)),
    deadline: uint,
    equity-total: uint
  })

(define-map CoopVotes
  { initiative-id: uint, member: principal }
  { alternative: (string-ascii 20), equity: uint })

(define-map MemberEquity
  { member: principal }
  { equity: uint })

(define-map Trustees
  { grantor: principal }
  { trustee: principal })

;; Private Functions
(define-private (is-coop-manager)
  (is-eq tx-sender (var-get coop-manager)))

(define-private (check-initiative-exists (initiative-id uint))
  (is-some (map-get? Initiatives { initiative-id: initiative-id })))

(define-private (check-voting-open (initiative-id uint))
  (match (map-get? Initiatives { initiative-id: initiative-id })
    initiative-data (< (var-get fiscal-year) (get deadline initiative-data))
    false))

(define-private (get-member-equity (member principal))
  (default-to u1 (get equity (map-get? MemberEquity { member: member }))))

(define-private (update-equity-total (initiative-id uint) (equity uint))
  (match (map-get? Initiatives { initiative-id: initiative-id })
    initiative-data (map-set Initiatives
                 { initiative-id: initiative-id }
                (merge initiative-data { equity-total: (+ (get equity-total initiative-data) equity) }))
    false))

(define-private (validate-string (input (string-ascii 50)))
  (and (>= (len input) u1) (<= (len input) u50)))

(define-private (validate-alternatives (alternatives (list 10 (string-ascii 20))))
  (and 
    (>= (len alternatives) u2)
    (<= (len alternatives) u10)
    (fold and (map validate-string alternatives) true)
  ))

(define-private (validate-equity-threshold (member principal))
  (> (get-member-equity member) u0))

;; Public Functions
(define-public (propose-initiative (title (string-ascii 50)) (alternatives (list 10 (string-ascii 20))) (duration uint))
  (begin
    (asserts! (is-coop-manager) ERR_UNAUTHORIZED)
    (asserts! (validate-string title) ERR_INVALID_INPUT)
    (asserts! (validate-alternatives alternatives) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (let 
      (
        (initiative-id (+ u1 (default-to u0 (get equity-total (map-get? Initiatives { initiative-id: u0 })))))
        (current-year (var-get fiscal-year))
      )
      (asserts! (not (check-initiative-exists initiative-id)) ERR_INITIATIVE_EXISTS)
      (ok (map-set Initiatives
            { initiative-id: initiative-id }
            {
              title: title,
              alternatives: alternatives,
              deadline: (+ current-year duration),
              equity-total: u0
            }))
    )
  ))

(define-public (cast-coop-vote (initiative-id uint) (alternative (string-ascii 20)))
  (let 
    (
      (member-equity (get-member-equity tx-sender))
      (initiative (unwrap! (map-get? Initiatives { initiative-id: initiative-id }) ERR_INITIATIVE_NOT_FOUND))
    )
    (asserts! (check-voting-open initiative-id) ERR_VOTING_ENDED)
    (asserts! (is-some (index-of (get alternatives initiative) alternative)) ERR_INVALID_CHOICE)
    (asserts! (is-none (map-get? CoopVotes { initiative-id: initiative-id, member: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (validate-equity-threshold tx-sender) ERR_NOT_ENOUGH_EQUITY)
    (map-set CoopVotes
      { initiative-id: initiative-id, member: tx-sender }
      { alternative: alternative, equity: member-equity })
    (update-equity-total initiative-id member-equity)
    (ok true)
  ))

(define-public (assign-trustee (trustee principal))
  (begin
    (asserts! (not (is-eq tx-sender trustee)) ERR_SELF_REPRESENTATION)
    (asserts! (is-none (map-get? Trustees { grantor: trustee })) ERR_REPRESENTATION_CYCLE)
    (map-set Trustees { grantor: tx-sender } { trustee: trustee })
    (map-set MemberEquity
      { member: trustee }
      { equity: (+ (get-member-equity trustee) (get-member-equity tx-sender)) })
    (map-delete MemberEquity { member: tx-sender })
    (ok true)
  ))

(define-public (close-initiative (initiative-id uint))
  (begin
    (asserts! (is-coop-manager) ERR_UNAUTHORIZED)
    (asserts! (check-initiative-exists initiative-id) ERR_INITIATIVE_NOT_FOUND)
    (let ((initiative (unwrap! (map-get? Initiatives { initiative-id: initiative-id }) ERR_INITIATIVE_NOT_FOUND)))
      (ok (map-set Initiatives
            { initiative-id: initiative-id }
            (merge initiative { deadline: (var-get fiscal-year) })))
    )
  ))

(define-public (advance-fiscal-year)
  (begin
    (asserts! (is-coop-manager) ERR_UNAUTHORIZED)
    (ok (var-set fiscal-year (+ (var-get fiscal-year) u1)))
  ))

;; Read-Only Functions
(define-read-only (get-initiative-equity-total (initiative-id uint))
  (ok (get equity-total (unwrap! (map-get? Initiatives { initiative-id: initiative-id }) ERR_INITIATIVE_NOT_FOUND))))

(define-read-only (get-member-equity-level (member principal))
  (ok (get-member-equity member)))

(define-read-only (get-initiative-status (initiative-id uint))
  (let ((initiative (unwrap! (map-get? Initiatives { initiative-id: initiative-id }) ERR_INITIATIVE_NOT_FOUND)))
    (ok (< (var-get fiscal-year) (get deadline initiative)))
  ))

(define-read-only (get-current-fiscal-year)
  (ok (var-get fiscal-year)))

(define-read-only (get-coop-stats)
  {
    manager: (var-get coop-manager),
    current-year: (var-get fiscal-year)
  })