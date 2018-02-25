defmodule CryptocurTest.Transaction do
  use ExUnit.Case
  doctest Cryptocur.Transaction

  test "one input and one input yield a correct transaction id hash" do
    input = %Cryptocur.Transaction.TxInput{out_id: "abc", out_index: 0, signature: "def"}
    output = %Cryptocur.Transaction.TxOutput{address: "abc", amount: 4.5}

    tx = %Cryptocur.Transaction.Tx{
      inputs: [input],
      outputs: [output]
    }

    txId = Cryptocur.Transaction.get_transaction_id(tx)

    assert is_binary(txId) == true

    assert txId ==
             <<220, 214, 107, 175, 229, 30, 51, 94, 132, 132, 53, 100, 151, 91, 157, 78, 11, 113,
               253, 129>>
  end

  test "correctly validates an address" do
    {:ok, {private_key, address}} = RsaEx.generate_keypair()

    assert Cryptocur.Transaction.is_valid_address(private_key, address) == true
  end

  test "invalidates an address if private key is invalid" do
    {:ok, private_key} = RsaEx.generate_private_key()
    {:ok, {_, address}} = RsaEx.generate_keypair()

    assert Cryptocur.Transaction.is_valid_address(private_key, address) == false
  end

  test "correctly finds an unspent transaction" do
    transaction_id = "abc"
    index = 42
    address = "def"
    amount = 3.14

    unspent_tx_outs = [
      %Cryptocur.Transaction.UnspentTxOutput{},
      %Cryptocur.Transaction.UnspentTxOutput{
        out_id: transaction_id,
        out_index: index,
        address: address,
        amount: amount
      },
      %Cryptocur.Transaction.UnspentTxOutput{}
    ]

    unspent_tx_out =
      Cryptocur.Transaction.find_unspent_tx_output(transaction_id, index, unspent_tx_outs)

    assert unspent_tx_out.out_id == transaction_id
    assert unspent_tx_out.out_index == index
    assert unspent_tx_out.address == address
    assert unspent_tx_out.amount == amount
  end

  test "updates" do
    new_transactions = [
      %Cryptocur.Transaction.Tx{
        id: "",
        inputs: [
          %Cryptocur.Transaction.TxInput{
            out_id: "id",
            out_index: 42
          }
        ],
        outputs: [
          %Cryptocur.Transaction.TxOutput{
            address: "addr",
            amount: 3.14
          }
        ]
      }
    ]

    Cryptocur.Transaction.update_unspent_tx_outputs(new_transactions, [])
    |> IO.inspect()
  end

  test "correctly sums transaction inputs" do
    unspent_tx_outputs = [
      %Cryptocur.Transaction.UnspentTxOutput{out_id: "a", out_index: 0, amount: 3.14},
      %Cryptocur.Transaction.UnspentTxOutput{out_id: "b", out_index: 1, amount: 42},
      %Cryptocur.Transaction.UnspentTxOutput{out_id: "c", out_index: 2, amount: 0.001592}
    ]

    transaction = %Cryptocur.Transaction.Tx{
      inputs: [
        %Cryptocur.Transaction.TxInput{out_id: "a", out_index: 0},
        %Cryptocur.Transaction.TxInput{out_id: "b", out_index: 1},
        %Cryptocur.Transaction.TxInput{out_id: "c", out_index: 0}
      ]
    }

    assert Cryptocur.Transaction.get_tx_input_total(transaction, unspent_tx_outputs) === 45.14
  end

  test "correctly sums transaction outputs" do
    transaction = %Cryptocur.Transaction.Tx{
      outputs: [
        %Cryptocur.Transaction.TxOutput{amount: 3.14},
        %Cryptocur.Transaction.TxOutput{amount: 42},
        %Cryptocur.Transaction.TxOutput{amount: 0.001592}
      ]
    }

    assert Cryptocur.Transaction.get_tx_output_total(transaction) === 45.141592
  end

  test "validates transaction input" do
    {:ok, {private_key, address}} = RsaEx.generate_keypair()

    input = %Cryptocur.Transaction.TxInput{out_id: "abc", out_index: 42}

    transaction = %Cryptocur.Transaction.Tx{inputs: [input], outputs: []}
    tx_id = Cryptocur.Transaction.get_transaction_id(transaction)
    transaction = %{transaction | id: tx_id}

    unspent_tx_outputs = [
      %Cryptocur.Transaction.UnspentTxOutput{
        out_id: "abc",
        out_index: 42,
        address: address,
        amount: 3.14
      }
    ]

    {:ok, signature} =
      Cryptocur.Transaction.sign_tx_id(transaction, 0, private_key, unspent_tx_outputs)

    input = %{input | signature: signature}

    Cryptocur.Transaction.validate_transaction_input(input, transaction, unspent_tx_outputs)
    |> IO.inspect()
  end

  test "correctly validates a coinbase transaction" do
    block_index = 42
    input = %Cryptocur.Transaction.TxInput{out_id: "abc", out_index: block_index}
    output = %Cryptocur.Transaction.TxOutput{address: "def", amount: 50.0}

    transaction = %Cryptocur.Transaction.Tx{inputs: [input], outputs: [output]}
    tx_id = Cryptocur.Transaction.get_transaction_id(transaction)
    transaction = %{transaction | id: tx_id}

    res = Cryptocur.Transaction.validate_coinbase_transaction(transaction, block_index)

    assert res == {:ok, "Valid"}
  end

  test "correctly invalidates a coinbase transaction" do
    block_index = 42
    input = %Cryptocur.Transaction.TxInput{out_id: "abc", out_index: block_index}
    output = %Cryptocur.Transaction.TxOutput{address: "def", amount: 50.0}

    transaction = %Cryptocur.Transaction.Tx{inputs: [input, input], outputs: [output]}
    tx_id = Cryptocur.Transaction.get_transaction_id(transaction)
    transaction = %{transaction | id: tx_id}

    res = Cryptocur.Transaction.validate_coinbase_transaction(transaction, block_index)

    assert res == {:err, "Invalid"}
  end
end
