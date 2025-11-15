// 💰 burn a ds_nft to unlock utxos length of divisor

use cardano/assets.{from_asset, from_lovelace}
use mocktail.{
  complete, mint, mock_policy_id, mock_pub_key_address, mock_pub_key_hash,
  mock_script_address, mock_tx_hash, mock_utxo_ref, mocktail_tx, ref_tx_in,
  ref_tx_in_inline_datum, tx_in, tx_out,
}
use tests/test_oracle.{DatumTestCase, datum_with_updates}
use treasury.{treasury_spend}
use utils/redeemer_treasury.{Withdraw}

// tests

const oracle_nft = mock_policy_id(1)

const oracle_script_address = mock_script_address(1, None)

const treasury_price_standard = 100_000_000

const treasury_price_unlock_standard = 200_000_000

const treasury_script_address = mock_script_address(0, None)

const winner = mock_pub_key_hash(2)

const winner_address = mock_pub_key_address(2, None)

const asset_name = #"31"

// Hex version of 1 Where #"34" = 4 and #"3134" = 14.
const policy_id = mock_policy_id(0)

const oracle_input_value = from_asset(oracle_nft, "", 1)

const redeemer_standard = Withdraw { asset_name }

const datum_standard =
  datum_with_updates(
    DatumTestCase {
      count: Some(6),
      treasury_address: Some(treasury_script_address),
      pot_address: None,
      fee_address: None,
      winner: Some(winner),
      treasury_price: Some(treasury_price_standard),
      pot_price: None,
      fee_price: None,
      slot_start: None,
      slot_increase: None,
      divisor: None,
      name: None,
      mode: None,
    },
  )

test success_spend_treasury() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> mint(True, -1, policy_id, asset_name)
      // 1 is less than 6 / 2 
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      // balanced with treasury input values
      |> complete()
  treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test success_spend_treasury_with_divisor_10() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(
          True,
          datum_with_updates(
            DatumTestCase {
              count: Some(60),
              treasury_address: Some(treasury_script_address),
              pot_address: None,
              fee_address: None,
              winner: Some(winner),
              treasury_price: Some(treasury_price_standard),
              pot_price: None,
              fee_price: None,
              slot_start: None,
              slot_increase: None,
              divisor: Some(10),
              name: None,
              mode: None,
            },
          ),
        )
      |> mint(True, -1, policy_id, asset_name)
      // 1 is less than 60 / 10 
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard * 10),
        )
      // balanced with treasury input values
      |> complete()
  treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_treasury_nft_above_threshold() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(
          True,
          datum_with_updates(
            DatumTestCase {
              count: Some(2),
              treasury_address: None,
              pot_address: None,
              fee_address: None,
              winner: None,
              treasury_price: None,
              pot_price: None,
              fee_price: None,
              slot_start: None,
              slot_increase: None,
              divisor: None,
              name: None,
              mode: None,
            },
          ),
        )
      |> mint(True, -1, policy_id, asset_name)
      //  1 is greater than 2 / 2
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_treasury_nft_equal_threshold() {
  let asset_name_14 = #"3134"
  let redeemer_14 = Withdraw { asset_name: asset_name_14 }
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(
          True,
          datum_with_updates(
            DatumTestCase {
              count: Some(29),
              treasury_address: Some(treasury_script_address),
              pot_address: None,
              fee_address: None,
              winner: Some(winner),
              treasury_price: Some(treasury_price_standard),
              pot_price: None,
              fee_price: None,
              slot_start: None,
              slot_increase: None,
              divisor: None,
              name: None,
              mode: None,
            },
          ),
        )
      |> mint(True, -1, policy_id, asset_name_14)
      // 14 is equal to threshold
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(oracle_nft, policy_id, redeemer_14, mock_utxo_ref(0, 0), tx)
}

test fail_spend_treasury_nft_without_burn() {
  let oracle_input_value = from_asset(oracle_nft, "", 1)
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> mint(False, -1, policy_id, asset_name)
      // NFT not burned
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_treasury_nft_with_burn_redeemer_name_mix() {
  let redeemer_2 = Withdraw { asset_name: #"32" }
  // not #"31"
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> mint(True, -1, policy_id, asset_name)
      // NFT asset name does not match redeemer
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(oracle_nft, policy_id, redeemer_2, mock_utxo_ref(0, 0), tx)
}

test fail_spend_treasury_input_count_less_than_divisor() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      // only one input 
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> mint(True, -1, policy_id, asset_name)
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_treasury_input_count_more_than_divisor() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      // 3 inputs
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> mint(True, -1, policy_id, asset_name)
      |> tx_out(True, winner_address, from_lovelace(300_000_000))
      // 300 ada
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_treasury_missing_oracle_reference() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> mint(True, -1, policy_id, asset_name)
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_treasury_wrong_oracle_nft() {
  let orcle_value_wrong = from_asset(mock_policy_id(14), "", 1)
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          orcle_value_wrong,
          oracle_script_address,
        )
      // wrong oracle 
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> mint(True, -1, policy_id, asset_name)
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
  // correct oracle nft
}

test fail_spend_treasury_no_oracle_datum() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(False, datum_standard)
      // no datum
      |> mint(True, -1, policy_id, asset_name)
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_treasury_invalid_asset_name() {
  let asset_name_cant_convert =
    #"f4c9f9c4252d86702c2f4c2e49e6648c7cffe3c8f2b6b7d779788f50"
  let redeemer_cant_convert = Withdraw { asset_name: asset_name_cant_convert }
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(treasury_price_standard),
          treasury_script_address,
        )
      |> ref_tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_input_value,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      // no datum
      |> mint(True, -1, policy_id, asset_name_cant_convert)
      |> tx_out(
          True,
          winner_address,
          from_lovelace(treasury_price_unlock_standard),
        )
      |> complete()
  !treasury_spend(
    oracle_nft,
    policy_id,
    redeemer_cant_convert,
    mock_utxo_ref(0, 0),
    tx,
  )
}
