use cardano/address.{Address}

pub type OracleDatum {
  count: Int,
  // collection count, gets incremented each mint
  treasury_address: Address,
  // treasury address
  pot_address: Address,
  // pot address
  fee_address: Address,
  // developer's wallet
  winner: ByteArray,
  // pub key hash of last nft purchaser, the wallet who can claim the prize pool
  treasury_price: Int,
  // lovelace to lock in treasury upon mint
  pot_price: Int,
  // lovelace to lock in the pot upon mint
  fee_price: Int,
  // lovelace that leaves the protocol upon mint and pays devs
  slot_start: Int,
  // timer: slot of oracle deployment ( includes arbitrary offset like + 6 months  )
  slot_increase: Int,
  // timer: slot increase for each new mint
  divisor: Int,
  // label of the game
  name: ByteArray,
  // game mode 0 is hard, 1 is easy
  mode: Int,
}
