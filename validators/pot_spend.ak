// 🪺 store utxos for winner - spend logic offloaded to pot_withdraw validator
use aiken/crypto.{ScriptHash}
use aiken_design_patterns/stake_validator
use cardano/transaction.{OutputReference, Transaction}

pub fn pot_spend_spend(withdraw_script_hash: ScriptHash, tx: Transaction) {
  stake_validator.spend_minimal(
    withdraw_script_hash: withdraw_script_hash,
    tx: tx,
  )
}

validator pot_spend(withdraw_script_hash: ScriptHash) {
  spend(
    _datum_opt: Option<Data>,
    _redeemer: Void,
    _input: OutputReference,
    tx: Transaction,
  ) {
    pot_spend_spend(withdraw_script_hash, tx)
  }

  else(_) {
    fail
  }
}
