// 🫀 mint and burn ds_nft 
use cardano/assets.{add, from_asset}
use cocktail.{only_minted_token}
use ds_nft.{ds_nft_mint}
use mocktail.{
  complete, invalid_hereafter, mint, mock_policy_id, mock_script_address,
  mock_tx_hash, mocktail_tx, tx_in, tx_in_inline_datum,
}
use tests/test_oracle.{DatumTestCase, datum_with_updates}
use utils/utils_ds_nft.{RBurn, RMint}
use utils/config.{config_receipt_name}

const redeemer_standard = RMint

const redeemer_burn_standard = RBurn

const policy_id_standard = mock_policy_id(0)

const oracle_utxo_input_standard =
  from_asset(mock_policy_id(0), "", 1) |> add("", "", 2_000_000)
const oracle_utxo_input_wrong =
  from_asset(mock_policy_id(0), config_receipt_name, 1) |> add("", "", 2_000_000)

const datum_standard =
  datum_with_updates(
    DatumTestCase {
      count: Some(1),
      treasury_address: None,
      pot_address: None,
      fee_address: None,
      winner: None,
      treasury_price: None,
      pot_price: None,
      fee_price: None,
      slot_start: Some(1),
      slot_increase: None,
      divisor: None,
      name: None,
      mode: Some(0),
    },
  )

const datum_standard_easy_mode =
  datum_with_updates(
    DatumTestCase {
      count: Some(1),
      treasury_address: None,
      pot_address: None,
      fee_address: None,
      winner: None,
      treasury_price: None,
      pot_price: None,
      fee_price: None,
      slot_start: Some(1),
      slot_increase: Some(5),
      divisor: None,
      name: None,
      mode: Some(1),
    },
  )

test success_mint_ds() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_utxo_input_standard,
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, datum_standard)
      |> mint(True, 1, policy_id_standard, "1")
      |> complete()
  ds_nft_mint(mock_policy_id(0), redeemer_standard, policy_id_standard, tx)
}

test fail_mint_ds_with_receipt() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_utxo_input_wrong,
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, datum_standard)
      |> mint(True, 1, policy_id_standard, "1")
      |> complete()
  !ds_nft_mint(mock_policy_id(0), redeemer_standard, policy_id_standard, tx)
}

test success_mint_ds_easy_mode() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_utxo_input_standard,
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, datum_standard_easy_mode)
      |> mint(True, 1, policy_id_standard, "1")
      |> invalid_hereafter(True, 5)
      // asset name is same as count
      |> complete()
  ds_nft_mint(mock_policy_id(0), redeemer_standard, policy_id_standard, tx)
}

test fail_mint_ds_with_incorrect_name() {
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_utxo_input_standard,
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, datum_standard)
      |> mint(True, 1, policy_id_standard, "2")
      // asset name is different from count
      |> complete()
  !ds_nft_mint(mock_policy_id(0), redeemer_standard, policy_id_standard, tx)
}

test fail_mint_ds_with_multiple_mint() {
  let policy_id_different = mock_policy_id(14)
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          oracle_utxo_input_standard,
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, datum_standard)
      |> mint(True, 1, policy_id_standard, "0")
      |> mint(True, 1, policy_id_different, "0")
      // cannot have multiple mints with any policy
      |> complete()
  !ds_nft_mint(mock_policy_id(0), redeemer_standard, policy_id_standard, tx)
}

test success_burn_ds() {
  let tx =
    mocktail_tx()
      |> mint(True, -1, policy_id_standard, "")
      |> complete()
  ds_nft_mint(mock_policy_id(0), redeemer_burn_standard, policy_id_standard, tx)
}

test success_burn_ds_with_other_policy_also_burning_edge_case() {
  let tx =
    mocktail_tx()
      |> mint(True, -1, policy_id_standard, "")
      |> mint(True, -1, mock_policy_id(1), "")
      // edge case we can burn other policies too
      |> complete()
  ds_nft_mint(mock_policy_id(0), redeemer_burn_standard, policy_id_standard, tx)
}

test fail_burn_ds_with_mint() {
  let tx =
    mocktail_tx()
      |> mint(True, 1, policy_id_standard, "")
      |> complete()
  !ds_nft_mint(
    mock_policy_id(0),
    redeemer_burn_standard,
    policy_id_standard,
    tx,
  )
}

test fail_burn_ds_with_mint_and_burn() {
  let tx =
    mocktail_tx()
      |> mint(True, -1, policy_id_standard, "")
      // cannot burn and mint at the same time
      |> mint(True, 1, policy_id_standard, "1")
      |> complete()
  !ds_nft_mint(
    mock_policy_id(0),
    redeemer_burn_standard,
    policy_id_standard,
    tx,
  )
}

test success_vodka_only_minted_token_test() {
  let mint = from_asset(policy_id_standard, "", 1)
  only_minted_token(mint, policy_id_standard, "", 1)
}

test fail_vodka_only_minted_token_test() {
  let mint = from_asset(policy_id_standard, "", 2)
  // try to mint 2 tokens
  !only_minted_token(mint, policy_id_standard, "", 1)
}
