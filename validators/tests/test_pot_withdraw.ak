// 🪺 be the winner and wait for timer to expire to withdraw the pot utxos
use cardano/address.{Script}
use cardano/assets.{from_asset, from_lovelace}
use mocktail.{
  complete, invalid_before, mock_policy_id, mock_pub_key_address,
  mock_pub_key_hash, mock_script_address, mock_script_hash, mock_tx_hash,
  mocktail_tx, ref_tx_in, ref_tx_in_inline_datum, required_signer_hash,
  script_withdrawal, tx_in, tx_out,
}
use pot_withdraw.{pot_withdraw_withdraw}
use tests/test_oracle.{DatumTestCase, datum_with_updates}

// tests

const oracle_nft = mock_policy_id(1)

const oracle_script_address = mock_script_address(2, None)

const knot_fee_address = mock_pub_key_address(3, None)

const pot_withdraw_script_hash = mock_script_hash(1)

const pot_address = mock_script_address(1, None)

const winner = mock_pub_key_hash(2)

const winner_address = mock_pub_key_address(2, None)

const oracle_utxo_standard = from_asset(oracle_nft, "", 1)

const input_lovelace = 120000

const one_percent = input_lovelace / 100

const output_lovelace = input_lovelace - one_percent

const output_knot = one_percent

const datum_standard =
  datum_with_updates(
    DatumTestCase {
      count: None,
      treasury_address: None,
      pot_address: None,
      fee_address: None,
      winner: Some(winner),
      treasury_price: None,
      pot_price: None,
      fee_price: None,
      slot_start: Some(0),
      slot_increase: Some(1200),
      divisor: None,
      name: None,
      mode: None,
    },
  )

test success_withdraw_pot() {
  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(3),
          0,
          oracle_utxo_standard,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> script_withdrawal(True, pot_withdraw_script_hash, 0)
      // Zero-amount withdrawal
      |> required_signer_hash(True, winner)
      |> invalid_before(True, 1201)
      // After game end 0 + 1 * 1200 = 1200
      |> tx_in(
          True,
          mock_tx_hash(4),
          0,
          from_lovelace(input_lovelace),
          pot_address,
        )
      |> tx_out(True, winner_address, from_lovelace(output_lovelace))
      |> tx_out(True, knot_fee_address, from_lovelace(output_knot))
      |> complete()
  pot_withdraw_withdraw(oracle_nft, Script(pot_withdraw_script_hash), tx)
}

test fail_withdraw_pot_not_winner() {
  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(3),
          0,
          oracle_utxo_standard,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(True, datum_standard)
      |> script_withdrawal(True, pot_withdraw_script_hash, 0)
      |> required_signer_hash(True, mock_pub_key_hash(4))
      // Not the winner
      |> invalid_before(True, 1201)
      |> complete()
  !pot_withdraw_withdraw(oracle_nft, Script(pot_withdraw_script_hash), tx)
}

test fail_withdraw_pot_before_game_end() {
  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(3),
          0,
          oracle_utxo_standard,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(
          True,
          datum_with_updates(
            DatumTestCase {
              count: Some(20),
              // count 
              treasury_address: None,
              pot_address: None,
              fee_address: None,
              winner: Some(winner),
              // winner
              treasury_price: None,
              pot_price: None,
              fee_price: None,
              slot_start: Some(1000),
              // slot_start
              slot_increase: Some(1200),
              // slot_increase
              divisor: None,
              name: None,
              mode: None,
            },
          ),
        )
      |> script_withdrawal(True, pot_withdraw_script_hash, 0)
      |> required_signer_hash(True, winner)
      |> invalid_before(True, 24999)
      // 1000 + 20 * 1200 = 25000
      |> complete()
  !pot_withdraw_withdraw(oracle_nft, Script(pot_withdraw_script_hash), tx)
}

test fail_withdraw_pot_invalid_datum() {
  let tx =
    mocktail_tx()
      |> ref_tx_in(
          True,
          mock_tx_hash(3),
          0,
          oracle_utxo_standard,
          oracle_script_address,
        )
      |> ref_tx_in_inline_datum(False, datum_standard)
      // invalid datum
      |> script_withdrawal(True, pot_withdraw_script_hash, 0)
      |> required_signer_hash(True, winner)
      |> invalid_before(True, 1201)
      |> complete()
  !pot_withdraw_withdraw(oracle_nft, Script(pot_withdraw_script_hash), tx)
}
