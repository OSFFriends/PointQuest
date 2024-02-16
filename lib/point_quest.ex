defmodule PointQuest do
  @moduledoc """
  PointQuest keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @spec quest_service() :: module()
  def quest_service(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests)
  def ticket_service(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Ticket)
end
