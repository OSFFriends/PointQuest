defmodule CouchDB.DocumentCodec.Metadata do
  @type t :: %__MODULE__{
          type: :ecto,
          properties: map
        }

  @derive Jason.Encoder
  @enforce_keys [:type, :properties]
  defstruct [:type, :properties]
end
