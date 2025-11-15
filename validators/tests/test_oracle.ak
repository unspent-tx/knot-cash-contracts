// 🖲️ store and spend the state thread game logic

use cardano/address.{Address}
use cardano/assets.{add, from_asset, from_lovelace}
use cardano/transaction.{Transaction}
use mocktail.{
  complete, mint, mock_policy_id, mock_pub_key_address, mock_pub_key_hash,
  mock_script_address, mock_tx_hash, mock_utxo_ref, mocktail_tx, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
}
use oracle.{oracle_spend}
use utils/datum_oracle.{OracleDatum}
use utils/redeemer_oracle.{MintDsNFT}

// tests

const count_standard = 0

// standard game logic
const treasury_address_standard = mock_script_address(0, None)

const pot_address_standard = mock_script_address(1, None)

const fee_address_standard = mock_pub_key_address(2, None)

const winner_standard = mock_pub_key_hash(3)

const treasury_price_standard = 100_000_000

const pot_price_standard = 4_000_000

const fee_price_standard = 2_000_000

const slot_start_standard = 0

const slot_increase_standard = 1200

const divisor_standard = 2

const name_standard = "A Knot"

const mode_standard = 0

// hard mode

pub type DatumTestCase {
  //  type for datum_with_updates
  count: Option<Int>,
  treasury_address: Option<Address>,
  pot_address: Option<Address>,
  fee_address: Option<Address>,
  winner: Option<ByteArray>,
  treasury_price: Option<Int>,
  pot_price: Option<Int>,
  fee_price: Option<Int>,
  slot_start: Option<Int>,
  slot_increase: Option<Int>,
  divisor: Option<Int>,
  name: Option<ByteArray>,
  mode: Option<Int>,
}

pub fn datum_with_updates(test_case: DatumTestCase) -> OracleDatum {
  // reuseable helper function to create a datum with updates or use a standard value by passing None
  let DatumTestCase {
    count,
    treasury_address,
    pot_address,
    fee_address,
    winner,
    treasury_price,
    pot_price,
    fee_price,
    slot_start,
    slot_increase,
    divisor,
    name,
    mode,
  } = test_case
  OracleDatum {
    count: when count is {
      Some(x) -> x
      // if count is provided, use it
      None -> count_standard
    },
    // else use a standard value
    treasury_address: when treasury_address is {
      Some(x) -> x
      // if treasury address is provided, use it
      None -> treasury_address_standard
    },
    // else use a standard value
    pot_address: when pot_address is {
      Some(x) -> x
      // etc
      None -> pot_address_standard
    },
    fee_address: when fee_address is {
      Some(x) -> x
      None -> fee_address_standard
    },
    winner: when winner is {
      Some(x) -> x
      None -> winner_standard
    },
    treasury_price: when treasury_price is {
      Some(x) -> x
      None -> treasury_price_standard
    },
    pot_price: when pot_price is {
      Some(x) -> x
      None -> pot_price_standard
    },
    fee_price: when fee_price is {
      Some(x) -> x
      None -> fee_price_standard
    },
    slot_start: when slot_start is {
      Some(x) -> x
      None -> slot_start_standard
    },
    slot_increase: when slot_increase is {
      Some(x) -> x
      None -> slot_increase_standard
    },
    divisor: when divisor is {
      Some(x) -> x
      None -> divisor_standard
    },
    name: when name is {
      Some(x) -> x
      None -> name_standard
    },
    mode: when mode is {
      Some(x) -> x
      None -> mode_standard
    },
  }
}

const oracle_utxo_input_standard =
  from_asset(mock_policy_id(0), "", 1) |> add("", "", 2_000_000)

// standard oracle utxo input
const redeemer_standard = MintDsNFT { winner: mock_pub_key_hash(3) }

// standard redeemer to reuse
const datum_standard =
  datum_with_updates(
    DatumTestCase {
      // standard input datum to resuse
      count: None,
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
  )

const datum_standard_output =
  datum_with_updates(
    DatumTestCase {
      // standard output datum to resuse with count + 1 and new winner
      count: Some(1),
      // count + 1
      treasury_address: None,
      pot_address: None,
      fee_address: None,
      winner: Some(mock_pub_key_hash(3)),
      // new winner
      treasury_price: None,
      pot_price: None,
      fee_price: None,
      slot_start: None,
      slot_increase: None,
      divisor: None,
      name: None,
      mode: None,
    },
  )

type MintTestCase {
  // type for mock_mint_tx
  is_oracle_output_clean: Bool,
  is_fee_paid: Bool,
  is_count_updated: Bool,
  is_treasury_paid: Bool,
  is_pot_paid: Bool,
}

fn mock_mint_tx(test_case: MintTestCase) -> Transaction {
  // main reuseable tx return function
  let MintTestCase {
    is_oracle_output_clean,
    is_fee_paid,
    is_count_updated,
    is_treasury_paid,
    is_pot_paid,
  } = test_case
  mocktail_tx()
    // return a tx
    |> tx_in(
        True,
        mock_tx_hash(0),
        0,
        oracle_utxo_input_standard,
        mock_script_address(0, None),
      )
    // oracle nft input
    |> tx_in_inline_datum(True, datum_standard)
    // oracle input datum
    |> tx_out(
        is_oracle_output_clean,
        mock_script_address(0, None),
        oracle_utxo_input_standard,
      )
    // oracle nft output
    |> tx_out(
        // optional additional (malicious) oracle nft output adding mock 1
        !is_oracle_output_clean,
        mock_script_address(0, None),
        oracle_utxo_input_standard |> add(mock_policy_id(1), "", 1),
      )
    |> tx_out_inline_datum(is_count_updated, datum_standard_output)
    // standard output datum with count + 1 and new winner 
    |> tx_out_inline_datum(
        // optional additional (malicious) output datum with count + 10 
        !is_count_updated,
        datum_with_updates(
          DatumTestCase {
            count: Some(10),
            // count + 10
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
    |> mint(True, 1, mock_policy_id(1), "0")
    |> tx_out(
        is_treasury_paid,
        mock_script_address(0, None),
        from_lovelace(treasury_price_standard),
      )
    // pay treasury
    |> tx_out(
        is_pot_paid,
        mock_script_address(1, None),
        from_lovelace(pot_price_standard),
      )
    // pay pot
    |> tx_out(
        is_fee_paid,
        mock_pub_key_address(2, None),
        from_lovelace(fee_price_standard),
      )
    // pay fee
    |> complete()
}

test success_spend_oracle() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_oracle_output_clean: True,
        is_fee_paid: True,
        is_count_updated: True,
        is_treasury_paid: True,
        is_pot_paid: True,
      },
    )
  oracle_spend(Some(datum_standard), redeemer_standard, mock_utxo_ref(0, 0), tx)
}

test fail_spend_oracle_with_unclean_output() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_oracle_output_clean: False,
        // oracle output is not clean
        is_fee_paid: True,
        is_count_updated: True,
        is_treasury_paid: True,
        is_pot_paid: True,
      },
    )
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_oracle_without_count_updated() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_oracle_output_clean: True,
        is_fee_paid: True,
        is_count_updated: False,
        // count not updated
        is_treasury_paid: True,
        is_pot_paid: True,
      },
    )
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_oracle_without_fee_paid() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_oracle_output_clean: True,
        is_fee_paid: False,
        // fee not paid
        is_count_updated: True,
        is_treasury_paid: True,
        is_pot_paid: True,
      },
    )
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_oracle_without_treasury_paid() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_oracle_output_clean: True,
        is_fee_paid: True,
        is_count_updated: True,
        is_treasury_paid: False,
        // treasury not paid
        is_pot_paid: True,
      },
    )
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_oracle_without_pot_paid() {
  let tx =
    mock_mint_tx(
      MintTestCase {
        is_oracle_output_clean: True,
        is_fee_paid: True,
        is_count_updated: True,
        is_treasury_paid: True,
        is_pot_paid: False,
      },
    )
  // pot not paid
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

// we are no longer using mock_mint_tx, instead showing more granular examples 
test fail_spend_oracle_with_not_enough_treasury_payment() {
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
      |> tx_out(True, mock_script_address(0, None), oracle_utxo_input_standard)
      |> tx_out_inline_datum(True, datum_standard_output)
      |> mint(True, 1, mock_policy_id(1), "0")
      |> tx_out(
          True,
          mock_pub_key_address(2, None),
          from_lovelace(fee_price_standard),
        )
      |> tx_out(True, mock_script_address(0, None), from_lovelace(50_000_000))
      // Insufficient treasury payment
      |> tx_out(
          True,
          mock_script_address(1, None),
          from_lovelace(pot_price_standard),
        )
      |> complete()
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_oracle_with_not_enough_pot_payment() {
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
      |> tx_out(True, mock_script_address(0, None), oracle_utxo_input_standard)
      |> tx_out_inline_datum(True, datum_standard_output)
      |> mint(True, 1, mock_policy_id(1), "0")
      |> tx_out(
          True,
          mock_pub_key_address(2, None),
          from_lovelace(fee_price_standard),
        )
      |> tx_out(
          True,
          mock_script_address(0, None),
          from_lovelace(treasury_price_standard),
        )
      |> tx_out(True, mock_script_address(1, None), from_lovelace(3_000_000))
      // Insufficient pot payment
      |> complete()
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_oracle_with_malicious_output_datum() {
  let malicious_output_datum =
    datum_with_updates(
      DatumTestCase {
        // create a bad output datum by changing any of the fields 
        count: Some(1),
        treasury_address: None,
        pot_address: Some(mock_script_address(13, None)),
        // example changing the pot address to mock 13
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
    )
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
      // normal datum input
      |> tx_out(True, mock_script_address(0, None), oracle_utxo_input_standard)
      |> tx_out_inline_datum(True, malicious_output_datum)
      // malicious datum output
      |> mint(True, 1, mock_policy_id(1), "0")
      |> tx_out(
          True,
          mock_pub_key_address(2, None),
          from_lovelace(fee_price_standard),
        )
      |> tx_out(
          True,
          mock_script_address(0, None),
          from_lovelace(treasury_price_standard),
        )
      |> tx_out(
          True,
          mock_script_address(1, None),
          from_lovelace(pot_price_standard),
        )
      |> complete()
  !oracle_spend(
    Some(datum_standard),
    redeemer_standard,
    mock_utxo_ref(0, 0),
    tx,
  )
}

test fail_spend_oracle_with_wrong_redeemer() {
  let redeemer_wrong = MintDsNFT { winner: mock_pub_key_hash(14) }
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
      |> tx_out(True, mock_script_address(0, None), oracle_utxo_input_standard)
      |> tx_out_inline_datum(
          True,
          datum_with_updates(
            DatumTestCase {
              count: Some(1),
              treasury_address: None,
              pot_address: None,
              fee_address: None,
              winner: Some(mock_pub_key_hash(4)),
              // winner               
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
      |> mint(True, 1, mock_policy_id(1), "0")
      |> tx_out(
          True,
          mock_pub_key_address(2, None),
          from_lovelace(fee_price_standard),
        )
      |> tx_out(
          True,
          mock_script_address(0, None),
          from_lovelace(treasury_price_standard),
        )
      |> tx_out(
          True,
          mock_script_address(1, None),
          from_lovelace(pot_price_standard),
        )
      |> complete()
  !oracle_spend(Some(datum_standard), redeemer_wrong, mock_utxo_ref(0, 0), tx)
  // wrong redeemer
}
