;; Melody Vault - Music Streaming Royalty Platform
;; A decentralized music streaming platform with royalty distribution and fan engagement

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-invalid-percentage (err u106))

;; Fan Engagement Token (FET) 
(define-fungible-token fan-engagement-token)

;; Data Variables
(define-data-var total-songs uint u0)
(define-data-var platform-fee-percentage uint u10) ;; 10% platform fee
(define-data-var min-reputation-score uint u0)

;; Data Maps
;; Artist information
(define-map artists
    { artist-address: principal }
    {
        name: (string-ascii 50),
        total-earnings: uint,
        song-count: uint,
        reputation-score: uint,
        verified: bool,
        join-date: uint
    }
)

;; Song metadata and royalty info
(define-map songs
    { song-id: uint }
    {
        title: (string-ascii 100),
        artist: principal,
        royalty-rate: uint, ;; per stream in micro-STX
        total-streams: uint,
        total-earnings: uint,
        upload-date: uint,
        active: bool
    }
)

;; Fan profiles and engagement
(define-map fans
    { fan-address: principal }
    {
        name: (string-ascii 50),
        total-spent: uint,
        fan-tokens: uint,
        reputation-score: uint,
        favorite-genre: (string-ascii 30),
        join-date: uint
    }
)

;; Streaming records
(define-map streams
    { fan: principal, song-id: uint, stream-date: uint }
    {
        payment-amount: uint,
        fan-tokens-earned: uint
    }
)

;; Artist-Fan relationships for engagement tracking
(define-map fan-artist-engagement
    { fan: principal, artist: principal }
    {
        total-streams: uint,
        total-spent: uint,
        fan-tokens-used: uint,
        last-interaction: uint
    }
)

;; Reputation tracking
(define-map reputation-actions
    { user: principal, action-type: (string-ascii 20), timestamp: uint }
    {
        points-earned: int,
        description: (string-ascii 100)
    }
)

;; Public Functions

;; Artist Registration
(define-public (register-artist (name (string-ascii 50)))
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? artists { artist-address: caller })) err-already-exists)
        (map-set artists
            { artist-address: caller }
            {
                name: name,
                total-earnings: u0,
                song-count: u0,
                reputation-score: u100, ;; Starting reputation
                verified: false,
                join-date: stacks-block-height
            }
        )
        (update-reputation caller "artist-registration" 10)
        (ok true)
    )
)

;; Fan Registration
(define-public (register-fan (name (string-ascii 50)) (favorite-genre (string-ascii 30)))
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? fans { fan-address: caller })) err-already-exists)
        (map-set fans
            { fan-address: caller }
            {
                name: name,
                total-spent: u0,
                fan-tokens: u0,
                reputation-score: u50, ;; Starting reputation for fans
                favorite-genre: favorite-genre,
                join-date: stacks-block-height
            }
        )
        (try! (ft-mint? fan-engagement-token u100 caller)) ;; Welcome bonus
        (update-reputation caller "fan-registration" 5)
        (ok true)
    )
)

;; Upload Song
(define-public (upload-song (title (string-ascii 100)) (royalty-rate uint))
    (let (
        (caller tx-sender)
        (song-id (+ (var-get total-songs) u1))
        (artist-data (unwrap! (map-get? artists { artist-address: caller }) err-not-found))
    )
        (asserts! (> royalty-rate u0) err-invalid-amount)
        (asserts! (<= royalty-rate u10000) err-invalid-amount) ;; Max 0.01 STX per stream
        
        (map-set songs
            { song-id: song-id }
            {
                title: title,
                artist: caller,
                royalty-rate: royalty-rate,
                total-streams: u0,
                total-earnings: u0,
                upload-date: stacks-block-height,
                active: true
            }
        )
        
        ;; Update artist stats
        (map-set artists
            { artist-address: caller }
            (merge artist-data { song-count: (+ (get song-count artist-data) u1) })
        )
        
        (var-set total-songs song-id)
        (update-reputation caller "song-upload" 15)
        (ok song-id)
    )
)

;; Stream Song (Main revenue function)
(define-public (stream-song (song-id uint))
    (let (
        (caller tx-sender)
        (song-data (unwrap! (map-get? songs { song-id: song-id }) err-not-found))
        (artist-address (get artist song-data))
        (royalty-amount (get royalty-rate song-data))
        (platform-fee (/ (* royalty-amount (var-get platform-fee-percentage)) u100))
        (artist-earnings (- royalty-amount platform-fee))
        (fan-tokens-earned (/ royalty-amount u100)) ;; 1 token per 100 micro-STX spent
        (fan-data (unwrap! (map-get? fans { fan-address: caller }) err-not-found))
        (artist-data (unwrap! (map-get? artists { artist-address: artist-address }) err-not-found))
    )
        (asserts! (get active song-data) err-not-found)
        
        ;; Transfer payment
        (try! (stx-transfer? royalty-amount caller artist-address))
        
        ;; Update song stats
        (map-set songs
            { song-id: song-id }
            (merge song-data {
                total-streams: (+ (get total-streams song-data) u1),
                total-earnings: (+ (get total-earnings song-data) royalty-amount)
            })
        )
        
        ;; Update artist earnings
        (map-set artists
            { artist-address: artist-address }
            (merge artist-data {
                total-earnings: (+ (get total-earnings artist-data) artist-earnings)
            })
        )
        
        ;; Update fan stats and award tokens
        (map-set fans
            { fan-address: caller }
            (merge fan-data {
                total-spent: (+ (get total-spent fan-data) royalty-amount),
                fan-tokens: (+ (get fan-tokens fan-data) fan-tokens-earned)
            })
        )
        
        ;; Mint fan engagement tokens
        (try! (ft-mint? fan-engagement-token fan-tokens-earned caller))
        
        ;; Record stream
        (map-set streams
            { fan: caller, song-id: song-id, stream-date: stacks-block-height }
            {
                payment-amount: royalty-amount,
                fan-tokens-earned: fan-tokens-earned
            }
        )
        
        ;; Update fan-artist engagement
        (match (map-get? fan-artist-engagement { fan: caller, artist: artist-address })
            existing-engagement
            (map-set fan-artist-engagement
                { fan: caller, artist: artist-address }
                {
                    total-streams: (+ (get total-streams existing-engagement) u1),
                    total-spent: (+ (get total-spent existing-engagement) royalty-amount),
                    fan-tokens-used: (get fan-tokens-used existing-engagement),
                    last-interaction: stacks-block-height
                }
            )
            (map-set fan-artist-engagement
                { fan: caller, artist: artist-address }
                {
                    total-streams: u1,
                    total-spent: royalty-amount,
                    fan-tokens-used: u0,
                    last-interaction: stacks-block-height
                }
            )
        )
        
        ;; Update reputation for both fan and artist
        (update-reputation caller "stream-song" 1)
        (update-reputation artist-address "receive-stream" 2)
        
        (ok true)
    )
)

;; Use Fan Tokens for Premium Features
(define-public (use-fan-tokens (amount uint) (purpose (string-ascii 50)))
    (let (
        (caller tx-sender)
        (fan-data (unwrap! (map-get? fans { fan-address: caller }) err-not-found))
    )
        (asserts! (>= (ft-get-balance fan-engagement-token caller) amount) err-insufficient-balance)
        
        (try! (ft-burn? fan-engagement-token amount caller))
        
        ;; Update fan data
        (map-set fans
            { fan-address: caller }
            (merge fan-data {
                fan-tokens: (- (get fan-tokens fan-data) amount)
            })
        )
        
        (update-reputation caller "use-tokens" (/ (to-int amount) 10))
        (ok true)
    )
)

;; Helper function to ensure reputation doesn't go below 0
(define-private (ensure-positive-reputation (current-reputation uint) (points int))
    (let ((new-reputation (+ (to-int current-reputation) points)))
        (if (< new-reputation 0)
            u0
            (to-uint new-reputation)
        )
    )
)

;; Reputation System Functions
(define-private (update-reputation (user principal) (action-type (string-ascii 20)) (points int))
    (begin
        ;; Record the reputation action
        (map-set reputation-actions
            { user: user, action-type: action-type, timestamp: stacks-block-height }
            {
                points-earned: points,
                description: action-type
            }
        )
        
        ;; Update artist reputation if user is an artist
        (match (map-get? artists { artist-address: user })
            artist-data
            (map-set artists
                { artist-address: user }
                (merge artist-data {
                    reputation-score: (ensure-positive-reputation (get reputation-score artist-data) points)
                })
            )
            false ;; Not an artist, do nothing
        )
        
        ;; Update fan reputation if user is a fan
        (match (map-get? fans { fan-address: user })
            fan-data
            (map-set fans
                { fan-address: user }
                (merge fan-data {
                    reputation-score: (ensure-positive-reputation (get reputation-score fan-data) points)
                })
            )
            false ;; Not a fan, do nothing
        )
        
        true
    )
)

;; Admin Functions
(define-public (verify-artist (artist-address principal))
    (let (
        (artist-data (unwrap! (map-get? artists { artist-address: artist-address }) err-not-found))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (map-set artists
            { artist-address: artist-address }
            (merge artist-data { verified: true })
        )
        
        (update-reputation artist-address "verification" 50)
        (ok true)
    )
)

(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u50) err-invalid-percentage) ;; Max 50%
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

(define-public (deactivate-song (song-id uint))
    (let (
        (song-data (unwrap! (map-get? songs { song-id: song-id }) err-not-found))
    )
        (asserts! (or (is-eq tx-sender contract-owner) 
                     (is-eq tx-sender (get artist song-data))) err-unauthorized)
        
        (map-set songs
            { song-id: song-id }
            (merge song-data { active: false })
        )
        (ok true)
    )
)

;; Read-Only Functions
(define-read-only (get-artist (artist-address principal))
    (map-get? artists { artist-address: artist-address })
)

(define-read-only (get-fan (fan-address principal))
    (map-get? fans { fan-address: fan-address })
)

(define-read-only (get-song (song-id uint))
    (map-get? songs { song-id: song-id })
)

(define-read-only (get-fan-tokens (user principal))
    (ft-get-balance fan-engagement-token user)
)

(define-read-only (get-total-songs)
    (var-get total-songs)
)

(define-read-only (get-platform-fee)
    (var-get platform-fee-percentage)
)

(define-read-only (get-fan-artist-engagement (fan principal) (artist principal))
    (map-get? fan-artist-engagement { fan: fan, artist: artist })
)

(define-read-only (get-reputation-score (user principal))
    (match (map-get? artists { artist-address: user })
        artist-data (some (get reputation-score artist-data))
        (match (map-get? fans { fan-address: user })
            fan-data (some (get reputation-score fan-data))
            none
        )
    )
)

;; Initialize contract
(begin
    (try! (ft-mint? fan-engagement-token u1000000 contract-owner)) ;; Initial supply for platform
)