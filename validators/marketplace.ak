// 🔀 Trade NFTs peer to peer
use cardano/address.{Address}
use cardano/assets.{from_lovelace, lovelace_of}
use cardano/transaction.{Input, OutputReference, Transaction, find_input}
use cocktail.{
  address_pub_key, get_all_value_to, inputs_at, key_signed, value_geq,
}
use utils/datum_marketplace.{MarketplaceDatum}
use utils/redeemer_marketplace.{Buy, Close, MarketplaceRedeemer}

pub fn marketplace_spend(
  owner: Address,
  fee_percentage_basis_point: Int,
  datum_opt: Option<MarketplaceDatum>,
  redeemer: MarketplaceRedeemer,
  input: OutputReference,
  tx: Transaction,
) {
  expect Some(datum) = datum_opt
  when redeemer is {
    Buy -> {
      expect Some(own_input) = find_input(tx.inputs, input)
      let own_address = own_input.output.address
      let is_only_one_input_from_own_address =
        when inputs_at(tx.inputs, own_address) is {
          [_] -> True
          _ -> False
        }
      let is_proceed_paid =
        get_all_value_to(tx.outputs, datum.seller)
          |> value_geq(
              from_lovelace(datum.price + lovelace_of(own_input.output.value)),
            )
      let is_fee_paid =
        get_all_value_to(tx.outputs, owner)
          |> value_geq(
              from_lovelace(datum.price * fee_percentage_basis_point / 10000),
            )
      is_only_one_input_from_own_address && is_fee_paid && is_proceed_paid
    }
    Close -> {
      expect Some(pub_key) = address_pub_key(datum.seller)
      key_signed(tx.extra_signatories, pub_key)
    }
  }
}

validator marketplace(owner: Address, fee_percentage_basis_point: Int) {
  spend(
    datum_opt: Option<MarketplaceDatum>,
    redeemer: MarketplaceRedeemer,
    input: OutputReference,
    tx: Transaction,
  ) {
    marketplace_spend(
      owner,
      fee_percentage_basis_point,
      datum_opt,
      redeemer,
      input,
      tx,
    )
  }

  else(_) {
    fail
  }
}
