defmodule Infra.Couch.Client do
  alias Infra.Couch

  @type page_opts :: %{
          end_key: String.t() | nil,
          limit: non_neg_integer() | nil,
          start_key: String.t() | nil
        }

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

  @spec paginate_view(String.t(), page_opts(), Keyword.t()) :: Stream.t()
  def paginate_view(view_name, page_opts, _opts \\ []) do
    page_opts =
      page_opts
      |> Map.put_new(:end_key, "\ufff0")
      |> Map.put_new(:limit, 100)
      |> Map.put_new(:start_key, "")
      |> Map.put(:inclusive_end, true)
      |> Map.put(:include_docs, true)
      |> Map.put(:sorted, true)

    Stream.resource(
      fn -> page_opts end,
      fn page_opts ->
        case post(view_name, page_opts) do
          {:ok, %{"rows" => [_has_row | _rest] = rows}} ->
            page_opts =
              page_opts
              |> Map.put(:start_key, List.last(rows)["id"] <> "\ufff0")

            rows = Enum.map(rows, &Couch.Document.from_doc(&1["doc"]))

            {rows, page_opts}

          {:ok, %{"rows" => []}} ->
            {:halt, nil}
        end
      end,
      fn _after -> nil end
    )
  end

  defp client() do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, Application.get_env(:point_quest, __MODULE__)[:base_url]},
      {Tesla.Middleware.BasicAuth,
       username: Application.get_env(:point_quest, __MODULE__)[:username],
       password: Application.get_env(:point_quest, __MODULE__)[:password]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ])
  end
end
