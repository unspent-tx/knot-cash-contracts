// 🖲️ one shot
use cardano/assets.{add, from_asset, from_lovelace}
use mocktail.{
  complete, mint, mock_policy_id, mock_pub_key_address, mock_tx_hash,
  mock_utxo_ref, mocktail_tx, tx_in, tx_out,
}
use oracle_nft.{oracle_nft_mint}
use utils/config.{config_receipt_name}

// Tests
const knot_fee = 50_000_000

const input_num_1 = 1

const input_num_2 = 2

const oracle_address = mock_pub_key_address(0, None)

const knot_address = mock_pub_key_address(1, None)

const input_utxo = mock_utxo_ref(input_num_1, input_num_2)

const policy_id = mock_policy_id(0)

const users_wallet_address = mock_pub_key_address(2, None)

const input_tx_hash = mock_tx_hash(1)

const input_tx_index = 2

const asset_oracle = input_tx_hash

const asset_receipt = config_receipt_name

const oracle_value =
  from_asset(policy_id, asset_oracle, 1) |> add("", "", 1_000_000)

const receipt_value =
  from_asset(policy_id, asset_receipt, 1) |> add("", "", 1_000_000)

test success_mint_oracle() {
  let tx =
    mocktail_tx()
      |> mint(True, 1, policy_id, asset_oracle)
      |> mint(True, 1, policy_id, asset_receipt)
      |> tx_in(
          True,
          input_tx_hash,
          input_tx_index,
          from_lovelace(1000000),
          users_wallet_address,
        )
      |> tx_out(True, oracle_address, oracle_value)
      |> tx_out(True, users_wallet_address, receipt_value)
      |> tx_out(True, knot_address, from_lovelace(knot_fee))
      |> complete()

  oracle_nft_mint(
    input_utxo,
    oracle_address,
    knot_address,
    knot_fee,
    policy_id,
    tx,
  )
}
