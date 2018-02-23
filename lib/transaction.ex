defmodule Cryptocur.Transaction do
  defmodule Tx do
    defstruct id: nil, inputs: [], outputs: []
  end

  defmodule TxOutput do
    defstruct address: nil, amount: 0
  end

  defmodule TxInput do
    defstruct out_id: nil, out_index: 0, signature: nil
  end

  defmodule UnspentTxOut do
    defstruct out_id: nil, out_index: 0, address: nil, amount: 0
  end

  def get_transaction_id(%Tx{inputs: inputs, outputs: outputs}) do
    txInContent =
      inputs
      |> Enum.map(fn input -> input.out_id <> Integer.to_string(input.out_index) end)
      |> Enum.reduce("", fn a, b -> a <> b end)

    txOutContent =
      outputs
      |> Enum.map(fn output -> output.address <> Float.to_string(output.amount) end)
      |> Enum.reduce("", fn a, b -> a <> b end)

    hash = :crypto.hash(:sha, txInContent <> txOutContent)

    {:ok, hash}
  end

  def sign_tx_in(transaction, tx_in_index, private_key, unspent_tx_outs) do
    %Cryptocur.Transaction.Tx{id: id, inputs: inputs} = transaction

    %Cryptocur.Transaction.TxInput{
      out_id: out_id,
      out_index: out_index
    } = Enum.at(inputs, tx_in_index)

    %Cryptocur.Transaction.UnspentTxOut{
      address: address
    } = find_unspent_tx_out(out_id, out_index, unspent_tx_outs)

    case is_valid_address(private_key, address) do
      true -> RsaEx.sign(id, private_key)
      _ -> {:err, "Invalid Address #{inspect(address)}"}
    end
  end

  def is_valid_address(private_key, address) do
    {:ok, public_key} = RsaEx.generate_public_key(private_key)
    address == public_key
  end

  # TODO update type guards
  def find_unspent_tx_out(transaction_id, index, unspent_tx_outs) when is_list(unspent_tx_outs) do
    unspent_tx_outs
    |> Enum.find(fn utx -> utx.out_id == transaction_id and utx.out_index == index end)
  end
end
