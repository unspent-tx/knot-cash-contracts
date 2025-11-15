use cardano/transaction.{Transaction}
use cocktail.{valid_before}

pub fn check_game_mode(
  tx: Transaction,
  slot_start: Int,
  slot_increase: Int,
  count: Int,
  mode: Int,
) -> Bool {
  when mode is {
    1 ->
      // easy mode
      valid_before(
        tx.validity_range,
        // tx.uppper < d.upper
        slot_start + slot_increase * count,
      )
    // hard mode
    0 -> True
    _ -> False
  }
}

pub type MintPolarity {
  RMint
  RBurn
}
