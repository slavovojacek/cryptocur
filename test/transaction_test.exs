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

    {:ok, txId} = Cryptocur.Transaction.get_transaction_id(tx)

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
      %Cryptocur.Transaction.UnspentTxOut{},
      %Cryptocur.Transaction.UnspentTxOut{
        out_id: transaction_id,
        out_index: index,
        address: address,
        amount: amount
      },
      %Cryptocur.Transaction.UnspentTxOut{}
    ]

    unspent_tx_out =
      Cryptocur.Transaction.find_unspent_tx_out(transaction_id, index, unspent_tx_outs)

    assert unspent_tx_out.out_id == transaction_id
    assert unspent_tx_out.out_index == index
    assert unspent_tx_out.address == address
    assert unspent_tx_out.amount == amount
  end
end
