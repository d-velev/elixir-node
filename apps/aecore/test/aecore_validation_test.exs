defmodule AecoreValidationTest do
  @moduledoc """
  Unit tests for the BlockValidation module
  """

  use ExUnit.Case
  doctest Aecore.Chain.BlockValidation

  alias Aecore.Chain.BlockValidation
  alias Aecore.Structures.Block
  alias Aecore.Structures.Header
  alias Aecore.Structures.SignedTx
  alias Aecore.Structures.SpendTx
  alias Aecore.Keys.Worker, as: Keys
  alias Aecore.Chain.Worker, as: Chain

  @tag :validation
  test "validate new block" do
    new_block = get_new_block()
    prev_block = get_prev_block()

    blocks_for_difficulty_calculation = [new_block, prev_block]

    _ =
      BlockValidation.calculate_and_validate_block!(
        new_block,
        prev_block,
        get_chain_state(),
        blocks_for_difficulty_calculation
      )

    wrong_height_block = %Block{
      new_block
      | header: %Header{new_block.header | height: 3}
    }

    assert {:error, "Incorrect height"} ==
             catch_throw(
               BlockValidation.calculate_and_validate_block!(
                 wrong_height_block,
                 prev_block,
                 get_chain_state(),
                 blocks_for_difficulty_calculation
               )
             )
  end

  test "validate transactions in a block" do
    {:ok, to_account} = Keys.pubkey()

    {:ok, tx1} =
      Keys.sign_tx(
        to_account,
        5,
        Map.get(Chain.chain_state(), to_account, %{nonce: 0}).nonce + 1,
        1,
        Chain.top_block().header.height +
          Application.get_env(:aecore, :tx_data)[:lock_time_coinbase] + 1
      )

    {:ok, tx2} =
      Keys.sign_tx(
        to_account,
        10,
        Map.get(Chain.chain_state(), to_account, %{nonce: 0}).nonce + 1,
        1,
        Chain.top_block().header.height +
          Application.get_env(:aecore, :tx_data)[:lock_time_coinbase] + 1
      )

    block = %{Block.genesis_block() | txs: [tx1, tx2]}

    assert block |> BlockValidation.validate_block_transactions()
           |> Enum.all?() == true
  end

  def get_new_block() do
    %Block{
      header: %Header{
        chain_state_hash:
          <<100, 126, 168, 5, 157, 180, 101, 231, 52, 4, 199, 197, 80, 234, 98, 146, 95, 154, 120,
            252, 235, 15, 11, 210, 185, 212, 233, 50, 179, 27, 64, 35>>,
        difficulty_target: 1,
        height: 2,
        nonce: 54,
        pow_evidence: [
          3964,
          316_334,
          366_465,
          376_566,
          386_164,
          623_237,
          633_065,
          643_432,
          643_561,
          653_138,
          653_833,
          31_323_331,
          31_323_834,
          31_373_436,
          31_383_066,
          31_386_335,
          31_613_935,
          32_313_438,
          32_356_432,
          33_303_439,
          33_383_035,
          33_386_236,
          33_393_063,
          33_663_337,
          34_326_534,
          34_333_833,
          34_613_162,
          34_623_533,
          34_663_436,
          35_353_130,
          35_376_262,
          35_656_432,
          36_303_437,
          36_306_330,
          36_313_862,
          36_323_634,
          36_386_134,
          36_623_130,
          36_626_131,
          37_343_836,
          37_353_437,
          37_643_235
        ],
        prev_hash:
          <<55, 64, 192, 115, 139, 134, 169, 4, 34, 58, 167, 7, 162, 142, 37, 211, 18, 226, 50,
            221, 144, 34, 249, 79, 84, 219, 165, 63, 188, 186, 213, 202>>,
        timestamp: 1_518_426_070_901,
        txs_hash:
          <<73, 160, 195, 51, 40, 152, 177, 68, 126, 28, 250, 214, 176, 20, 202, 175, 222, 181,
            108, 11, 106, 182, 80, 122, 179, 208, 233, 75, 222, 83, 102, 160>>,
        version: 1
      },
      txs: [
        %SignedTx{
          data: %SpendTx{
            fee: 0,
            from_acc: nil,
            lock_time_block: 12,
            nonce: 0,
            to_acc:
              <<4, 189, 182, 95, 56, 124, 178, 175, 226, 223, 46, 184, 93, 2, 93, 202, 223, 118,
                74, 222, 92, 242, 192, 92, 157, 35, 13, 93, 231, 74, 52, 96, 19, 203, 81, 87, 85,
                42, 30, 111, 104, 8, 98, 177, 233, 236, 157, 118, 30, 223, 11, 32, 118, 9, 122,
                57, 7, 143, 127, 1, 103, 242, 116, 234, 47>>,
            value: 100
          },
          signature: nil
        }
      ]
    }
  end

  def get_prev_block() do
    %Block{
      header: %Header{
        chain_state_hash:
          <<230, 129, 113, 45, 47, 180, 171, 8, 15, 55, 74, 106, 150, 170, 190, 220, 32, 87, 30,
            102, 106, 67, 131, 247, 17, 56, 115, 147, 17, 115, 143, 196>>,
        difficulty_target: 1,
        height: 1,
        nonce: 20,
        pow_evidence: [
          323_237,
          333_766,
          346_430,
          363_463,
          366_336,
          383_965,
          653_638,
          663_034,
          31_313_230,
          31_316_539,
          31_326_462,
          31_383_531,
          31_636_130,
          32_343_435,
          32_346_663,
          32_363_234,
          32_613_339,
          32_626_666,
          32_636_335,
          32_656_637,
          32_663_432,
          33_356_639,
          33_363_166,
          33_366_138,
          33_393_033,
          33_613_465,
          34_316_561,
          34_353_064,
          35_303_264,
          35_356_635,
          35_373_439,
          35_613_039,
          35_616_266,
          35_663_939,
          36_336_334,
          36_376_631,
          36_396_432,
          36_613_239,
          36_613_539,
          36_626_364,
          36_643_466,
          37_343_266
        ],
        prev_hash:
          <<188, 84, 93, 222, 212, 45, 228, 224, 165, 111, 167, 218, 25, 31, 60, 159, 14, 163,
            105, 206, 162, 32, 65, 127, 128, 188, 162, 75, 124, 8, 229, 131>>,
        timestamp: 1_518_426_067_973,
        txs_hash:
          <<170, 58, 122, 219, 147, 41, 59, 140, 28, 127, 153, 68, 245, 18, 205, 22, 147, 124,
            157, 182, 123, 24, 41, 71, 132, 6, 162, 20, 227, 255, 25, 25>>,
        version: 1
      },
      txs: [
        %SignedTx{
          data: %SpendTx{
            fee: 0,
            from_acc: nil,
            lock_time_block: 11,
            nonce: 0,
            to_acc:
              <<4, 189, 182, 95, 56, 124, 178, 175, 226, 223, 46, 184, 93, 2, 93, 202, 223, 118,
                74, 222, 92, 242, 192, 92, 157, 35, 13, 93, 231, 74, 52, 96, 19, 203, 81, 87, 85,
                42, 30, 111, 104, 8, 98, 177, 233, 236, 157, 118, 30, 223, 11, 32, 118, 9, 122,
                57, 7, 143, 127, 1, 103, 242, 116, 234, 47>>,
            value: 100
          },
          signature: nil
        }
      ]
    }
  end

  def get_chain_state() do
    %{
      <<4, 189, 182, 95, 56, 124, 178, 175, 226, 223, 46, 184, 93, 2, 93, 202, 223, 118, 74, 222,
        92, 242, 192, 92, 157, 35, 13, 93, 231, 74, 52, 96, 19, 203, 81, 87, 85, 42, 30, 111, 104,
        8, 98, 177, 233, 236, 157, 118, 30, 223, 11, 32, 118, 9, 122, 57, 7, 143, 127, 1, 103,
        242, 116, 234, 47>> => %{balance: 0, locked: [%{amount: 100, block: 11}], nonce: 0}
    }
  end
end
