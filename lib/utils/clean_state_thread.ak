use cardano/transaction.{Input, Output, Transaction}
use cocktail.{inputs_at_with_policy, outputs_at_with_policy}
use utils/find_policy_id_of_first_token.{find_policy_id_of_first_token}

// makes sure this is one input and one output that spend the one time minting policy nft

pub fn clean_state_thread(tx: Transaction, input: Input) -> Option<Output> {
  let policy = find_policy_id_of_first_token(input)
  // get the address of the input being spent
  let own_address = input.output.address

  when
    (
      inputs_at_with_policy(tx.inputs, own_address, policy),
      outputs_at_with_policy(tx.outputs, own_address, policy),
    )
  is {
    ([_], [only_output]) ->
      // when 1 output with oracle nft is present
      Some(only_output)
    _ -> None
  }
}
