defmodule Infra.Linear.Records.Field do
  @moduledoc """
  Handles cases where the underlying ecto type was not loaded in the query
  """

  use Ecto.ParameterizedType

  @impl Ecto.ParameterizedType
  def type(params) do
    params.type
  end

  @impl Ecto.ParameterizedType
  def init(opts) do
    # throw if type not present, TODO validate schema
    Map.new(opts)
  end

  @impl Ecto.ParameterizedType
  def load(data, _loader, _params) do
    # this doesn't actually matter with our model
    {:ok, data}
  end

  @impl Ecto.ParameterizedType
  def dump(data, _dumper, _params) do
    # also don't care
    {:ok, data}
  end

  @impl Ecto.ParameterizedType
  def cast(:not_loaded, _params), do: {:ok, :not_loaded}

  def cast(data, params) do
    Ecto.Type.cast(params.type, data)
  end
end
