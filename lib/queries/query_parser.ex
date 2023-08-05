defmodule PointQuest.QueryParser do
  @moduledoc """
  Glob loading of GraphQL queries
  """
  import Phoenix.Template

  embed_templates("graphql/*")
end
