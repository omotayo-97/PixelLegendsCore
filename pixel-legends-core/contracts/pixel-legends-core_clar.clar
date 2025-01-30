;; Constants for game configuration
(define-constant MAX-GUILD-NAME-LENGTH u24)
(define-constant MAX-ADVENTURER-NAME-LENGTH u24)
(define-constant MIN-GUILD-LEVEL-REQUIREMENT u10)
(define-constant MAX-GUILD-MEMBERS u100)
(define-constant MIN-CONTRIBUTION-AMOUNT u1)
(define-constant GUILD-CREATION-COST u1000)
(define-constant XP-PER-LEVEL u1000)
(define-constant COOLDOWN-BLOCKS u10)
(define-constant MAX-INVENTORY-SLOTS u50)
(define-constant MAX-CRAFTING-LEVEL u100)

;; Error Constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-ADVENTURER-EXISTS (err u102))
(define-constant ERR-ADVENTURER-NOT-FOUND (err u103))
(define-constant ERR-ARTIFACT-NOT-FOUND (err u104))
(define-constant ERR-INSUFFICIENT-LEVEL (err u105))
(define-constant ERR-COOLDOWN-ACTIVE (err u106))
(define-constant ERR-INSUFFICIENT-GOLD-COINS (err u107))
(define-constant ERR-GUILD-EXISTS (err u108))
(define-constant ERR-GUILD-NOT-FOUND (err u109))
(define-constant ERR-NOT-GUILD-MASTER (err u110))
(define-constant ERR-ALREADY-IN-GUILD (err u111))
(define-constant ERR-GUILD-FULL (err u112))
(define-constant ERR-INVALID-NAME (err u113))
(define-constant ERR-INVALID-AMOUNT (err u114))
(define-constant ERR-INACTIVE-ADVENTURER (err u115))
(define-constant ERR-INACTIVE-GUILD (err u116))
(define-constant ERR-INSUFFICIENT-STATS (err u117))
(define-constant ERR-INVENTORY-FULL (err u118))
(define-constant ERR-INSUFFICIENT-MATERIALS (err u119))
(define-constant ERR-CRAFTING-FAILED (err u120))

;; Principal Variables with Access Control
(define-data-var game-master principal tx-sender)
(define-map game-moderators principal bool)

;; Adventurer Profile Structure
(define-map adventurer-profiles principal 
  {
    adventurer-name: (string-ascii 24),
    adventurer-class: (string-ascii 16),
    level: uint,
    strength: uint,
    vitality: uint,
    magic: uint,
    agility: uint,
    xp: uint,
    skill-points: uint,
    achievement-score: uint,
    last-quest-timestamp: uint,
    creation-timestamp: uint,
    last-active-timestamp: uint,
    is-active: bool,
    gold-coins: uint,
    crafting-level: uint
  }
)

;; Artifact System
(define-map artifact-inventory 
  { owner: principal, artifact-id: uint }
  {
    artifact-name: (string-ascii 24),
    artifact-type: (string-ascii 16),
    rarity: (string-ascii 12),
    attack-bonus: uint,
    defense-bonus: uint,
    magic-bonus: uint,
    durability: uint,
    max-durability: uint,
    level-requirement: uint,
    class-requirement: (optional (string-ascii 16)),
    is-tradeable: bool,
    is-bound: bool,
    creation-timestamp: uint,
    last-modified-timestamp: uint
  }
)

;; Guild System
(define-map guild-data (string-ascii 24)
  {
    guild-master: principal,
    guild-officers: (list 5 principal),
    guild-level: uint,
    guild-xp: uint,
    member-count: uint,
    max-members: uint,
    guild-treasury: uint,
    minimum-level-requirement: uint,
    creation-time: uint,
    last-active-time: uint,
    guild-banner: (string-ascii 24),
    is-active: bool,
    guild-achievement-score: uint,
    guild-description: (string-ascii 256)
  }
)

;; Guild Members Map
(define-map guild-members principal
  {
    guild-name: (string-ascii 24),
    contribution-points: uint,
    last-contribution-time: uint
  }
)

;; Crafting Recipe System
(define-map crafting-recipes uint
  {
    recipe-name: (string-ascii 24),
    ingredients: (list 5 { artifact-type: (string-ascii 16), quantity: uint }),
    result-artifact-type: (string-ascii 16),
    crafting-level-required: uint,
    success-rate: uint
  }
)

;; Private Functions for Input Validation
(define-private (validate-name (name (string-ascii 24)))
  (and
    (> (len name) u0)
    (<= (len name) MAX-ADVENTURER-NAME-LENGTH)
    (is-eq (index-of name " ") none)  ;; No spaces allowed
  )
)

(define-private (validate-amount (amount uint))
  (and
    (>= amount MIN-CONTRIBUTION-AMOUNT)
    (<= amount u1000000000)  ;; Reasonable upper limit
  )
)

(define-private (validate-guild-name (name (string-ascii 24)))
  (and
    (validate-name name)
    (is-none (map-get? guild-data name))
  )
)

(define-private (is-game-moderator (user principal))
  (or
    (is-eq user (var-get game-master))
    (default-to false (map-get? game-moderators user))
  )
)

(define-private (check-adventurer-active (adventurer principal))
  (match (map-get? adventurer-profiles adventurer)
    profile-data (get is-active profile-data)
    false
  )
)

;; Enhanced Adventurer Creation with Validation
(define-public (create-adventurer 
    (adventurer-name (string-ascii 24))
    (adventurer-class (string-ascii 16)))
  (let (
    (existing-adventurer (map-get? adventurer-profiles tx-sender))
  )
    (asserts! (validate-name adventurer-name) ERR-INVALID-NAME)
    (asserts! (is-none existing-adventurer) ERR-ADVENTURER-EXISTS)
    
    (ok (map-set adventurer-profiles tx-sender {
      adventurer-name: adventurer-name,
      adventurer-class: adventurer-class,
      level: u1,
      strength: u10,
      vitality: u10,
      magic: u10,
      agility: u10,
      xp: u0,
      skill-points: u0,
      achievement-score: u0,
      last-quest-timestamp: u0,
      creation-timestamp: block-height,
      last-active-timestamp: block-height,
      is-active: true,
      gold-coins: u100,
      crafting-level: u1
    }))
  )
)

;; Enhanced Guild Creation with Validation
(define-public (create-guild
    (guild-name (string-ascii 24))
    (guild-banner (string-ascii 24))
    (guild-description (string-ascii 256)))
  (let (
    (adventurer-data (unwrap! (map-get? adventurer-profiles tx-sender) ERR-ADVENTURER-NOT-FOUND))
  )
    ;; Input validation
    (asserts! (validate-guild-name guild-name) ERR-INVALID-NAME)
    (asserts! (validate-name guild-banner) ERR-INVALID-NAME)
    (asserts! (>= (get level adventurer-data) MIN-GUILD-LEVEL-REQUIREMENT) ERR-INSUFFICIENT-LEVEL)
    (asserts! (check-adventurer-active tx-sender) ERR-INACTIVE-ADVENTURER)
    (asserts! (>= (get gold-coins adventurer-data) GUILD-CREATION-COST) ERR-INSUFFICIENT-GOLD-COINS)
    
    ;; Create guild with enhanced data
    (map-set guild-data guild-name {
      guild-master: tx-sender,
      guild-officers: (list tx-sender),
      guild-level: u1,
      guild-xp: u0,
      member-count: u1,
      max-members: MAX-GUILD-MEMBERS,
      guild-treasury: u0,
      minimum-level-requirement: u5,
      creation-time: block-height,
      last-active-time: block-height,
      guild-banner: guild-banner,
      is-active: true,
      guild-achievement-score: u0,
      guild-description: guild-description
    })
    
    ;; Deduct creation cost
    (map-set adventurer-profiles tx-sender
      (merge adventurer-data { gold-coins: (- (get gold-coins adventurer-data) GUILD-CREATION-COST) })
    )
    
    (ok true)
  )
)

;; Quest System
(define-public (embark-on-quest (quest-id uint))
  (let (
    (adventurer-data (unwrap! (map-get? adventurer-profiles tx-sender) ERR-ADVENTURER-NOT-FOUND))
  )
    ;; Comprehensive validation
    (asserts! (check-adventurer-active tx-sender) ERR-INACTIVE-ADVENTURER)
    (asserts! (> (- block-height (get last-quest-timestamp adventurer-data)) COOLDOWN-BLOCKS) ERR-COOLDOWN-ACTIVE)
    (asserts! (>= (get vitality adventurer-data) u50) ERR-INSUFFICIENT-STATS)
    
    ;; Update quest timestamp and reward adventurer
    (let (
      (quest-reward (+ u50 (* u5 (get level adventurer-data))))
      (xp-gain (* u10 (get level adventurer-data)))
    )
      (map-set adventurer-profiles tx-sender 
        (merge adventurer-data {
          last-quest-timestamp: block-height,
          gold-coins: (+ (get gold-coins adventurer-data) quest-reward),
          xp: (+ (get xp adventurer-data) xp-gain)
        })
      )
      (ok true)
    )
  )
)

;; Safe Guild Contribution System
(define-public (contribute-to-guild (amount uint))
  (let (
    (guild-member-data (unwrap! (map-get? guild-members tx-sender) ERR-ADVENTURER-NOT-FOUND))
    (guild-name (get guild-name guild-member-data))
    (guild-info (unwrap! (map-get? guild-data guild-name) ERR-GUILD-NOT-FOUND))
    (adventurer-data (unwrap! (map-get? adventurer-profiles tx-sender) ERR-ADVENTURER-NOT-FOUND))
  )
    ;; Validation
    (asserts! (validate-amount amount) ERR-INVALID-AMOUNT)
    (asserts! (>= (get gold-coins adventurer-data) amount) ERR-INSUFFICIENT-GOLD-COINS)
    
    ;; Update guild treasury and member contribution
    (map-set guild-data guild-name 
      (merge guild-info {guild-treasury: (+ (get guild-treasury guild-info) amount)})
    )
    (map-set guild-members tx-sender
      (merge guild-member-data {
        contribution-points: (+ (get contribution-points guild-member-data) amount),
        last-contribution-time: block-height
      })
    )
    ;; Deduct gold from adventurer
    (map-set adventurer-profiles tx-sender
      (merge adventurer-data {gold-coins: (- (get gold-coins adventurer-data) amount)})
    )
    (ok true)
  )
)

;; New Feature: Crafting System
(define-public (craft-artifact (recipe-id uint))
  (let (
    (adventurer-data (unwrap! (map-get? adventurer-profiles tx-sender) ERR-ADVENTURER-NOT-FOUND))
    (recipe (unwrap! (map-get? crafting-recipes recipe-id) ERR-ARTIFACT-NOT-FOUND))
  )
    ;; Validation
    (asserts! (check-adventurer-active tx-sender) ERR-INACTIVE-ADVENTURER)
    (asserts! (>= (get crafting-level adventurer-data) (get crafting-level-required recipe)) ERR-INSUFFICIENT-LEVEL)
    
    ;; Check for required materials
    (asserts! (fold check-ingredients (get ingredients recipe) true) ERR-INSUFFICIENT-MATERIALS)
    
    ;; Attempt crafting
    (if (< (rand u100) (get success-rate recipe))
      (let (
        (new-artifact-id (+ u1 (default-to u0 (get artifact-id (map-get? artifact-inventory {owner: tx-sender, artifact-id: u0})))))
      )
        ;; Craft successful
        (map-set artifact-inventory 
          {owner: tx-sender, artifact-id: new-artifact-id}
          {
            artifact-name: (concat (get recipe-name recipe) " #" (to-ascii (serialize-uint256 new-artifact-id))),
            artifact-type: (get result-artifact-type recipe),
            rarity: "common",
            attack-bonus: u10,
            defense-bonus: u10,
            magic-bonus: u10,
            durability: u100,
            max-durability: u100,
            level-requirement: u1,
            class-requirement: none,
            is-tradeable: true,
            is-bound: false,
            creation-timestamp: block-height,
            last-modified-timestamp: block-height
          }
        )
        ;; Consume materials
        (map consume-ingredient (get ingredients recipe))
        ;; Increase crafting XP
        (map-set adventurer-profiles tx-sender
          (merge adventurer-data {
            crafting-level: (+ u1 (get crafting-level adventurer-data))
          })
        )
        (ok true)
      )
      (err ERR-CRAFTING-FAILED)
    )
  )
)

;; Helper function to check if adventurer has required ingredients
(define-private (check-ingredients (ingredient {artifact-type: (string-ascii 16), quantity: uint}) (acc bool))
  (and 
    acc 
    (>= (default-to u0 (get quantity (map-get? artifact-inventory {owner: tx-sender, artifact-type: (get artifact-type ingredient)}))) 
        (get quantity ingredient))
  )
)

;; Helper function to consume ingredients after successful crafting
(define-private (consume-ingredient (ingredient {artifact-type: (string-ascii 16), quantity: uint}))
  (let (
    (current-quantity (default-to u0 (get quantity (map-get? artifact-inventory {owner: tx-sender, artifact-type: (get artifact-type ingredient)}))))
  )
    (map-set artifact-inventory 
      {owner: tx-sender, artifact-type: (get artifact-type ingredient)}
      {quantity: (- current-quantity (get quantity ingredient))}
    )
  )
)

;; Administrative Functions with Access Control
(define-public (set-game-moderator (mod principal) (status bool))
  (begin
    (asserts! (is-eq tx-sender (var-get game-master)) ERR-UNAUTHORIZED)
    (ok (map-set game-moderators mod status))
  )
)

;; Enhanced Read-only Functions
(define-read-only (get-adventurer-details (player principal))
  (match (map-get? adventurer-profiles player)
    adventurer-data (if (get is-active adventurer-data)
                    (some adventurer-data)
                    none)
    none
  )
)

(define-read-only (get-guild-details (guild-name (string-ascii 24)))
  (map-get? guild-data guild-name)
)

(define-read-only (get-artifact-details (owner principal) (artifact-id uint))
  (map-get? artifact-inventory {owner: owner, artifact-id: artifact-id})
)

(define-read-only (get-crafting-recipe (recipe-id uint))
  (map-get? crafting-recipes recipe-id)
)

;; Contract Initialization
(begin
  ;; Initialize first crafting recipe
  (map-set crafting-recipes u1
    {
      recipe-name: "Basic Sword",
      ingredients: (list 
        {artifact-type: "iron-ingot", quantity: u2}
        {artifact-type: "wood", quantity: u1}
      ),
      result-artifact-type: "sword",
      crafting-level-required: u1,
      success-rate: u80
    }
  )
  
  ;; Set initial game master
  (var-set game-master tx-sender)
  
  (ok true)
)