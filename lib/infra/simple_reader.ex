defmodule Infra.SimpleReader do
  @moduledoc """
  A reader to handle in-memory data "persistence"
  """
  defstruct []

  def new() do
    %__MODULE__{}
  end

  defimpl Projectionist.Reader do
    def read(%Infra.SimpleReader{} = _config, _read) do
      []
    end

    def stream(%Infra.SimpleReader{} = _config, _read, callback) do
      callback.([])
    end
  end
end
