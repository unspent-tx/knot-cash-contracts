// 🖲️ one shot nft policy for state thread
use cardano/address.{Address}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use utils/utils_oracle_nft.{
  listing_is_sent, nft_names, one_time, oracle_is_sent, tokens_are_minted,
}

pub fn oracle_nft_mint(
  utxo_ref: OutputReference,
  oracle_address: Address,
  knot_address: Address,
  knot_fee: Int,
  policy_id: PolicyId,
  tx: Transaction,
) {
  // [utxo_ref.transaction_id, "Knot A Receipt"]
  expect [oracle_name, receipt_name] = nft_names(utxo_ref)

  and {
    // Makes sure utxo_ref is a part of the inputs
    one_time(tx.inputs, utxo_ref)?,
    // Checks if only two tokens are minted and their names are orcale_name and receipt_name
    tokens_are_minted(tx.mint, policy_id, oracle_name, receipt_name, 1)?,
    // Checks if oracle_nft is (name and policy) is sent to oracle_address
    oracle_is_sent(tx.outputs, policy_id, oracle_address, oracle_name)?,
    // Checks if correct fee is sent to knot_address. 
    listing_is_sent(tx.outputs, knot_address, knot_fee)?,
  }
}

validator oracle_nft(
  utxo_ref: OutputReference,
  oracle_address: Address,
  knot_address: Address,
  knot_fee: Int,
) {
  mint(_redeemer: Data, policy_id: PolicyId, tx: Transaction) {
    oracle_nft_mint(
      utxo_ref,
      oracle_address,
      knot_address,
      knot_fee,
      policy_id,
      tx,
    )
  }

  else(_) {
    fail
  }
}
