defmodule Infra.Couch.DocumentConflict do
  defexception [:document_id, :message]

  def exception(opts) do
    %__MODULE__{
      document_id: Keyword.fetch!(opts, :document_id),
      message: "Document update conflict"
    }
  end
end

defmodule Infra.Couch.Unauthorized do
  defexception [:message]
end

defmodule Infra.Couch.NotFound do
  defexception [:message]
end

defmodule Infra.Couch.BadRequest do
  defexception [:message]
end

defmodule Infra.Couch.PreconditionFailed do
  defexception [:message]
end
