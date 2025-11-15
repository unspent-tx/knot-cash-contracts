// 💰 burn a ds_nft to unlock utxos length of divisor
use aiken/builtin.{divide_integer, less_than_integer}
use aiken/collection/list
use aiken/primitive/int.{from_utf8}
use cardano/assets.{PolicyId}
use cardano/transaction.{
  InlineDatum, Output, OutputReference, Transaction, find_input,
}
use cocktail.{inputs_at, inputs_with_policy, only_minted_token}
use utils/datum_oracle.{OracleDatum}
use utils/redeemer_treasury.{TreasuryRedeemer, Withdraw}

pub fn treasury_spend(
  oracle_nft: PolicyId,
  nft_policy: PolicyId,
  redeemer: TreasuryRedeemer,
  input: OutputReference,
  tx: Transaction,
) {
  when
    (
      redeemer,
      inputs_with_policy(tx.reference_inputs, oracle_nft),
      find_input(tx.inputs, input),
    )
  is {
    (
      // when redeemer has asset name
      Withdraw { asset_name },
      // when 1 input reference with oracle nft is present
      [oracle_input_ref],
      // when we are spending our own input
      Some(own_input),
    ) ->
      when (oracle_input_ref.output.datum, from_utf8(asset_name)) is {
        (
          // when oracle utxo has some inline datum
          InlineDatum(oracle_datum),
          // when the redeemer's asset name converts to an integer from utf8
          Some(asset_name_int),
        ) -> {
          // oracle datum is valid
          expect OracleDatum { count, divisor, .. } = oracle_datum
          // use asset_name to check for burn
          let is_burned = only_minted_token(tx.mint, nft_policy, asset_name, -1)
          // use asset_name_int to check if less than count divided by divisor
          let under_threshold =
            less_than_integer(asset_name_int, divide_integer(count, divisor))
          // use divisor to check amount of inputs being spent
          let is_correct_input_count =
            list.length(inputs_at(tx.inputs, own_input.output.address)) == divisor
          is_burned? && under_threshold? && is_correct_input_count?
        }
        _ -> {
          trace @"Invalid oracle datum or nft name integer"
          False
        }
      }
    _ -> {
      trace @"Invalid redeemer, oracle input reference, or own input"
      False
    }
  }
}

validator treasury(oracle_nft: PolicyId, nft_policy: PolicyId) {
  spend(
    _datum_opt: Option<Data>,
    redeemer: TreasuryRedeemer,
    input: OutputReference,
    tx: Transaction,
  ) {
    treasury_spend(oracle_nft, nft_policy, redeemer, input, tx)
  }

  else(_) {
    fail
  }
}
