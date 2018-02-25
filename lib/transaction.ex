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

  defmodule UnspentTxOutput do
    defstruct out_id: nil, out_index: 0, address: nil, amount: 0
  end

  @coinbase_amount 50.0

  def get_transaction_id(%Tx{inputs: inputs, outputs: outputs}) do
    txInContent =
      inputs
      |> Enum.map(fn input -> input.out_id <> Integer.to_string(input.out_index) end)
      |> Enum.reduce("", fn a, b -> a <> b end)

    txOutContent =
      outputs
      |> Enum.map(fn output -> output.address <> Float.to_string(output.amount) end)
      |> Enum.reduce("", fn a, b -> a <> b end)

    :crypto.hash(:sha, txInContent <> txOutContent)
  end

  def sign_tx_id(transaction, tx_input_index, private_key, unspent_tx_outs) do
    %Tx{id: id, inputs: inputs} = transaction
    %TxInput{out_id: out_id, out_index: out_index} = Enum.at(inputs, tx_input_index)

    address =
      case find_unspent_tx_output(out_id, out_index, unspent_tx_outs) do
        %UnspentTxOutput{address: address} -> address
        _ -> nil
      end

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
  def find_unspent_tx_output(transaction_id, index, unspent_tx_outs)
      when is_list(unspent_tx_outs) do
    unspent_tx_outs
    |> Enum.find(fn utx -> utx.out_id == transaction_id and utx.out_index == index end)
  end

  def update_unspent_tx_outputs(new_transactions, unspent_tx_outputs) do
    new_unspent_tx_outputs =
      new_transactions
      |> Enum.map(fn %Tx{id: tx_id, outputs: tx_outputs} ->
        tx_outputs
        |> Enum.with_index()
        |> Enum.map(fn {output, index} ->
          %UnspentTxOutput{
            out_id: tx_id,
            out_index: index,
            address: output.address,
            amount: output.amount
          }
        end)
      end)
      |> Enum.flat_map(& &1)

    consumed_tx_outputs =
      new_transactions
      |> Enum.map(fn %Tx{inputs: tx_inputs} -> tx_inputs end)
      |> Enum.flat_map(& &1)
      |> Enum.map(fn %TxInput{out_id: out_id, out_index: out_index} ->
        %UnspentTxOutput{out_id: out_id, out_index: out_index}
      end)

    original_unspent_tx_outputs =
      unspent_tx_outputs
      |> Enum.filter(fn %UnspentTxOutput{out_id: out_id, out_index: out_index} ->
        find_unspent_tx_output(out_id, out_index, consumed_tx_outputs) == nil
      end)

    original_unspent_tx_outputs ++ new_unspent_tx_outputs
  end

  def validate_transaction(
        %Tx{id: id, inputs: inputs, outputs: outputs} = transaction,
        unspent_tx_outputs
      ) do
    is_valid_transaction_id = get_transaction_id(transaction) == id

    valid_inputs =
      inputs
      |> Enum.all?(fn input ->
        elem(validate_transaction_input(input, transaction, unspent_tx_outputs), 0) == :ok
      end)

    input_total = get_tx_input_total(inputs, unspent_tx_outputs)
    output_total = get_tx_output_total(outputs)

    case is_valid_transaction_id and valid_inputs and input_total === output_total do
      true -> {:ok, "Valid"}
      _ -> {:err, "Invalid"}
    end
  end

  def validate_transaction_input(
        %TxInput{out_id: out_id, out_index: out_index, signature: signature} = input,
        %Tx{id: tx_id},
        unspent_tx_outputs
      ) do
    case find_unspent_tx_output(out_id, out_index, unspent_tx_outputs) do
      %UnspentTxOutput{address: address} -> RsaEx.verify(tx_id, signature, address)
      _ -> {:err, "Referenced transaction output not found: #{inspect(input)}"}
    end
  end

  def validate_coinbase_transaction(
        %Tx{id: id, inputs: [input], outputs: [output]} = transaction,
        block_index
      ) do
    is_valid_transaction_id = get_transaction_id(transaction) == id
    is_valid_index = input.out_index == block_index
    is_valid_output_amount = output.amount == @coinbase_amount

    case is_valid_transaction_id and is_valid_index and is_valid_output_amount do
      true -> {:ok, "Valid"}
      _ -> {:err, "Invalid"}
    end
  end

  def validate_coinbase_transaction(_, _), do: {:err, "Invalid"}

  def get_tx_input_total(%Tx{inputs: inputs}, unspent_tx_outputs) do
    inputs
    |> Enum.map(fn %TxInput{out_id: out_id, out_index: out_index} ->
      case find_unspent_tx_output(out_id, out_index, unspent_tx_outputs) do
        %UnspentTxOutput{amount: amount} -> amount
        _ -> 0
      end
    end)
    |> Enum.sum()
  end

  def get_tx_output_total(%Tx{outputs: outputs}) do
    outputs
    |> Enum.map(fn %TxOutput{amount: amount} -> amount end)
    |> Enum.sum()
  end
end
