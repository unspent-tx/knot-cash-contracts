// 🖲️ store and spend the state thread game logic
use cardano/transaction.{Input,
  Output, OutputReference, Transaction, find_input}
use cocktail.{inputs_at_with_policy, outputs_at_with_policy}
use utils/datum_oracle.{OracleDatum}
use utils/find_policy_id_of_first_token.{find_policy_id_of_first_token}
use utils/redeemer_oracle.{MintDsNFT, OracleRedeemer}
use utils/utils_oracle.{is_datum_updated, is_output_value_clean, is_value_paid}

pub fn oracle_spend(
  datum_opt: Option<OracleDatum>,
  redeemer: OracleRedeemer,
  input: OutputReference,
  tx: Transaction,
) {
  // find the input being spent
  expect Some(own_input) = find_input(tx.inputs, input)
  // find the NFT from its own input
  let oracle_nft_policy = find_policy_id_of_first_token(own_input)
  // find the address of the input being spent
  let own_address = own_input.output.address
  // destructure input datum
  expect Some(input_datum) = datum_opt
  when
    (
      redeemer,
      inputs_at_with_policy(tx.inputs, own_address, oracle_nft_policy),
      outputs_at_with_policy(tx.outputs, own_address, oracle_nft_policy),
    )
  is {
    (
      // when the redeemer includes a new_winner
      MintDsNFT { winner: new_winner },
      // when 1 input with oracle nft is present
      [_],
      // when 1 output with oracle nft is present
      [only_output],
    ) ->
      and {
        is_output_value_clean(only_output),
        is_datum_updated(input_datum, only_output, new_winner),
        is_value_paid(tx, input_datum),
      }
    _ -> False
  }
}

validator oracle {
  spend(
    datum_opt: Option<OracleDatum>,
    redeemer: OracleRedeemer,
    input: OutputReference,
    tx: Transaction,
  ) {
    oracle_spend(datum_opt, redeemer, input, tx)
  }

  else(_) {
    fail
  }
}
