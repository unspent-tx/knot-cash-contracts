// 🫀 mint and burn ds_nft (ds is a nod to the original contract I called Double Spent)
use aiken/primitive/bytearray.{from_string}
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Transaction}
use cocktail.{
  check_policy_only_burn, convert_int_to_bytes, inputs_with, inputs_with_policy,
  only_minted_token,
}
use utils/datum_oracle.{OracleDatum}
use utils/utils_ds_nft.{MintPolarity, RBurn, RMint, check_game_mode}
use utils/config.{config_receipt_name_string}

pub fn ds_nft_mint(
  oracle_nft: PolicyId,
  redeemer: MintPolarity,
  policy_id: PolicyId,
  tx: Transaction,
) {
  when redeemer is {
    RMint ->
      when inputs_with_policy(tx.inputs, oracle_nft) is {
        // when 1 oracle input is present
        [oracle_input] ->
          // There are 2 nfts from this policy so we make sure the receipt is not present, and infer the real oracle nft is being spent
          when
            inputs_with(
              [oracle_input],
              oracle_nft,
              from_string(config_receipt_name_string),
            )
          is {
            [_] -> False
            _ -> {
              // Oracle NFT is being spent
              // with inline datum
              expect InlineDatum(input_datum) = oracle_input.output.datum
              expect OracleDatum { count, mode, slot_start, slot_increase, .. } =
                input_datum
              and {
                only_minted_token(
                  tx.mint,
                  policy_id,
                  convert_int_to_bytes(count),
                  1,
                ),
                check_game_mode(tx, slot_start, slot_increase, count, mode),
              }
            }
          }
        _ -> False
      }
    // all minting values are negative 
    RBurn -> check_policy_only_burn(tx.mint, policy_id)
  }
}

validator ds_nft(oracle_nft: PolicyId) {
  mint(redeemer: MintPolarity, policy_id: PolicyId, tx: Transaction) {
    ds_nft_mint(oracle_nft, redeemer, policy_id, tx)
  }

  else(_) {
    fail
  }
}
