// 🪺 be the winner and wait for timer to expire to withdraw the pot utxos
use aiken_design_patterns/stake_validator
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Transaction}
use cocktail.{inputs_with_policy, key_signed, valid_after}
use utils/datum_oracle.{OracleDatum}

pub fn pot_withdraw_withdraw(
  oracle_nft: PolicyId,
  own_credential: Credential,
  tx: Transaction,
) {
  stake_validator.withdraw(
    // This logic runs once per transaction rather than once per utxo
    withdrawal_logic: fn(_own_validator, tx) {
      when inputs_with_policy(tx.reference_inputs, oracle_nft) is {
        [oracle_input_ref] ->
          when oracle_input_ref.output.datum is {
            // some datum is present
            InlineDatum(oracle_datum) -> {
              // oracle datum is valid
              expect OracleDatum {
                count,
                slot_start,
                slot_increase,
                winner,
                ..
              } = oracle_datum
              and {
                // is_winner?,
                key_signed(tx.extra_signatories, winner),
                // is_timer_expired?,
                valid_after(
                  tx.validity_range,
                  slot_start + count * slot_increase,
                ),
              }
            }
            _ -> {
              trace @"Invalid oracle datum"
              False
            }
          }
        _ -> {
          trace @"Invalid redeemer or oracle reference"
          False
        }
      }
    },
    stake_cred: own_credential,
    tx: tx,
  )
}

validator pot_withdraw(oracle_nft: PolicyId) {
  withdraw(_redeemer: Void, own_credential: Credential, tx: Transaction) {
    pot_withdraw_withdraw(oracle_nft, own_credential, tx)
  }

  else(_) {
    fail
  }
}
