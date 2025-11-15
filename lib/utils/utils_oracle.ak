use aiken/collection/list
use cardano/address.{Address}
use cardano/assets.{flatten, lovelace_of}
use cardano/transaction.{InlineDatum, Output, Transaction}
use utils/datum_oracle.{OracleDatum}

pub fn is_value_paid(tx: Transaction, input_datum: OracleDatum) -> Bool {
  let OracleDatum {
    treasury_address,
    pot_address,
    fee_address,
    treasury_price,
    pot_price,
    fee_price,
    ..
  } = input_datum
  tag_outputs_values(
    tx.outputs,
    treasury_address,
    treasury_price,
    pot_address,
    pot_price,
    fee_address,
    fee_price,
  )
}

pub fn tag_outputs_values(
  outputs: List<Output>,
  ad_1: Address,
  p_1: Int,
  ad_2: Address,
  p_2: Int,
  ad_3: Address,
  p_3: Int,
) -> Bool {
  // map over the outputs once to calculate the values going to each address
  let output_values =
    list.foldr(
      outputs,
      (0, 0, 0),
      fn(output, acc) {
        if output.address == ad_1 {
          (acc.1st + lovelace_of(output.value), acc.2nd, acc.3rd)
        } else if output.address == ad_2 {
          (acc.1st, acc.2nd + lovelace_of(output.value), acc.3rd)
        } else if output.address == ad_3 {
          (acc.1st, acc.2nd, acc.3rd + lovelace_of(output.value))
        } else {
          acc
        }
      },
    )

  and {
    output_values.1st >= p_1,
    output_values.2nd >= p_2,
    output_values.3rd >= p_3,
  }
}

pub fn is_output_value_clean(output: Output) -> Bool {
  list.length(flatten(output.value)) == 2
}

pub fn is_datum_updated(
  input_datum: OracleDatum,
  output: Output,
  new_winner: ByteArray,
) -> Bool {
  let OracleDatum {
    count,
    treasury_address,
    pot_address,
    fee_address,
    winner: _winner,
    treasury_price,
    pot_price,
    fee_price,
    slot_start,
    slot_increase,
    divisor,
    name,
    mode,
  } = input_datum

  output.datum == InlineDatum(
    OracleDatum {
      // update count by 1
      count: count + 1,
      treasury_address,
      pot_address,
      fee_address,
      // update winner to new_winner
      winner: new_winner,
      treasury_price,
      pot_price,
      fee_price,
      slot_start,
      slot_increase,
      divisor,
      name,
      mode,
    },
  )
}
