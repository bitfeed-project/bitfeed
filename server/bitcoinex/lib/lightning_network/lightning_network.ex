defmodule Bitcoinex.LightningNetwork do
  @moduledoc """
    Includes serialization and validation for Lightning Network BOLT#11 invoices.
  """

  alias Bitcoinex.LightningNetwork.Invoice

  # defdelegate encode_invoice(invoice), to: Invoice, as: :encode
  defdelegate decode_invoice(invoice), to: Invoice, as: :decode
end
