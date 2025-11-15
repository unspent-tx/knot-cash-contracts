use aiken/collection/list
use cardano/address.{Address}
use cardano/assets.{PolicyId, Value, flatten, from_lovelace}
use cardano/transaction.{Input, Output, OutputReference}
use cocktail.{get_all_value_to, outputs_at_with, token_minted, value_geq}
use utils/config.{config_receipt_name}

pub fn oracle_is_sent(
  outputs: List<Output>,
  policy_id: PolicyId,
  address: Address,
  name: ByteArray,
) -> Bool {
  when outputs_at_with(outputs, address, policy_id, name) is {
    [_] -> True
    _ -> False
  }
}

pub fn listing_is_sent(
  outputs: List<Output>,
  address: Address,
  fee: Int,
) -> Bool {
  get_all_value_to(outputs, address)
    |> value_geq(from_lovelace(fee))
}

pub fn one_time(inputs: List<Input>, utxo_ref: OutputReference) -> Bool {
  when list.find(inputs, fn(input) { input.output_reference == utxo_ref }) is {
    Some(_) -> True
    _ -> False
  }
}

pub fn only_two_minted(mint: Value, policy: PolicyId) {
  // Todo: should be able to filter out for all the names in a single pass
  when flatten(mint) |> list.filter(fn(asset) { asset.1st == policy }) is {
    [(_, _, minted_quantity), (_, _, minted_quantity3)] -> and {
        // Just 'True' is enough since token_minted already checks this in token_are_minted function
        minted_quantity == 1,
        minted_quantity3 == 1,
      }
    _ -> False
  }
}

pub fn tokens_are_minted(
  mint: Value,
  policy_id: PolicyId,
  name1: ByteArray,
  name3: ByteArray,
  _amount: Int,
) -> Bool {
  and {
    token_minted(mint, policy_id, name1, 1),
    token_minted(mint, policy_id, name3, 1),
    only_two_minted(mint, policy_id),
  }
}

pub fn nft_names(utxo: OutputReference) -> List<ByteArray> {
  [utxo.transaction_id, config_receipt_name]
}
