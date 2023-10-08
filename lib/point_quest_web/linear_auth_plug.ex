defmodule PointQuestWeb.LinearAuthPlug do
  @moduledoc false
  use PointQuestWeb, :verified_routes

  alias PointQuest.Linear

  import Phoenix.Controller
  import Plug.Conn

  def handle_linear_code(conn, _opts) do
    code = Map.get(conn.query_params, "code")
    current_user = conn.assigns.current_user

    if is_nil(code) do
      conn
    else
      redirect_uri = build_redirect_path(conn)
      Linear.redeem_code(redirect_uri, code, current_user.id)

      redirect(conn, to: conn.request_path)
    end
  end

  def require_linear_token(conn, _opts) do
    current_user = conn.assigns[:current_user]

    if Linear.has_token?(current_user.email) do
      conn
    else
      client_id = Application.get_env(:point_quest, Infra.Linear)[:client_id]
      redirect_url = build_redirect_path(conn)

      url =
        "https://linear.app/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_url}&scope=read&prompt=consent"

      redirect(conn, external: url)
      |> halt()
    end
  end

  defp build_redirect_path(conn) do
    host = conn.host
    path = conn.request_path
    scheme = conn.scheme
    port = conn.port

    convert_protocol(scheme)
    |> add_host(host)
    |> maybe_add_port(port)
    |> add_path(path)
  end

  defp convert_protocol(scheme) do
    to_string(scheme) <> "://"
  end

  defp add_host(url, host), do: url <> host

  defp maybe_add_port(url, port) do
    if Enum.any?([80, 443], fn p -> p == port end) do
      url
    else
      url <> ":#{port}"
    end
  end

  defp add_path(url, path) do
    url <> path
  end
end
