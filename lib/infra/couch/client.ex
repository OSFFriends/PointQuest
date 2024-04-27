defmodule Infra.Couch.Client do
  alias Infra.Couch

  def put(url, doc, opts \\ []) do
    client()
    |> Tesla.put(url, doc, opts)
    |> case do
      {:ok, %{status: 400, body: %{"reason" => reason}}} ->
        {:error, Couch.BadRequest.exception(reason)}

      {:ok, %{status: 401, body: %{"reason" => reason}}} ->
        {:error, Couch.Unauthorized.exception(reason)}

      {:ok, %{status: 412, body: %{"reason" => reason}}} ->
        {:error, Couch.PreconditionFailed.exception(reason)}

      {:ok, %{body: body}} ->
        {:ok, body}
    end
  end

  def post(url, doc, opts \\ []) do
    client()
    |> Tesla.post(url, doc, opts)
    |> case do
      {:ok, %{status: 400, body: %{"reason" => reason}}} ->
        {:error, Couch.BadRequest.exception(reason)}

      {:ok, %{status: 401, body: %{"reason" => reason}}} ->
        {:error, Couch.Unauthorized.exception(reason)}

      {:ok, %{status: 412, body: %{"reason" => reason}}} ->
        {:error, Couch.PreconditionFailed.exception(reason)}

      {:ok, %{body: body}} ->
        {:ok, body}
    end
  end

  def get(url, opts \\ []) do
    client()
    |> Tesla.get(url, opts)
    |> case do
      {:ok, %{status: 400, body: %{"reason" => reason}}} ->
        {:error, Couch.BadRequest.exception(reason)}

      {:ok, %{status: 401, body: %{"reason" => reason}}} ->
        {:error, Couch.Unauthorized.exception(reason)}

      {:ok, %{status: 404, body: %{"reason" => reason}}} ->
        {:error, Couch.NotFound.exception(reason)}

      {:ok, %{body: body}} ->
        {:ok, body}
    end
  end

  defp client() do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, Application.get_env(:point_quest, __MODULE__)[:base_url]},
      {Tesla.Middleware.BasicAuth,
       username: Application.get_env(:point_quest, __MODULE__)[:username],
       password: Application.get_env(:point_quest, __MODULE__)[:password]},
      Tesla.Middleware.JSON
    ])
  end
end
