defmodule PointQuest.Authentication do
  @moduledoc """
  Handles decoding and encoding session tokens and authentication behaviors
  """

  alias PointQuest.Authentication.Actor
  alias PointQuest.Quests

  @salt "uy+yFunzM0OeFWaGyt3bjFPdeNv6ngzY6kktUXznKOSkQxjKC8uMDsczk2dPbxVu"

  @type token :: String.t()

  @spec create_actor(Quests.Adventurer.t()) :: Actor.Adventurer.t()
  def create_actor(%Quests.Adventurer{} = adventurer) do
    Ecto.embedded_load(
      Actor.Adventurer,
      %{quest_id: adventurer.quest_id, adventurer: Ecto.embedded_dump(adventurer, :json)},
      :json
    )
  end

  @spec create_actor(Quests.PartyLeader.t()) :: Actor.PartyLeader.t()
  def create_actor(%Quests.PartyLeader{adventurer: nil} = leader) do
    Ecto.embedded_load(
      Actor.PartyLeader,
      %{quest_id: leader.quest_id, leader_id: leader.id},
      :json
    )
  end

  def create_actor(%Quests.PartyLeader{} = leader) do
    Ecto.embedded_load(
      Actor.PartyLeader,
      %{
        quest_id: leader.quest_id,
        leader_id: leader.id,
        adventurer: Ecto.embedded_dump(leader, :json)
      },
      :json
    )
  end

  @spec actor_to_token(Actor.t()) :: token()
  def actor_to_token(actor) do
    Phoenix.Token.sign(
      PointQuestWeb.Endpoint,
      @salt,
      from_actor(actor)
    )
  end

  @spec token_to_actor(token()) :: {:ok, Actor.t()} | {:error, :expired | :invalid | :missing}
  def token_to_actor(token) do
    with {:ok, serializable} <- Phoenix.Token.verify(PointQuestWeb.Endpoint, @salt, token) do
      {:ok, to_actor(serializable)}
    end
  end

  def to_actor(%{type: :adventurer, quest_id: _quest_id, adventurer_id: _adventurer_id} = token) do
    {:ok, adventurer} =
      PointQuest.Quests.GetAdventurer.new!(token) |> PointQuest.Quests.GetAdventurer.execute()

    PointQuest.Authentication.create_actor(adventurer)
  end

  def to_actor(%{type: :party_leader, quest_id: _quest_id, adventurer_id: _adventurer_id} = token) do
    dbg(token)

    {:ok, leader} =
      PointQuest.Quests.GetPartyLeader.new!(token)
      |> PointQuest.Quests.GetPartyLeader.execute()

    PointQuest.Authentication.create_actor(leader)
  end

  def from_actor(%Actor.Adventurer{} = adventurer) do
    %{
      type: :adventurer,
      quest_id: adventurer.quest_id,
      adventurer_id: adventurer.adventurer.id
    }
  end

  def from_actor(%Actor.PartyLeader{adventurer: nil} = leader) do
    %{
      type: :party_leader,
      quest_id: leader.quest_id,
      leader_id: leader.leader_id,
      adventurer_id: nil
    }
  end

  def from_actor(%Actor.PartyLeader{} = leader) do
    %{
      type: :party_leader,
      quest_id: leader.quest_id,
      leader_id: leader.leader_id,
      adventurer_id: leader.adventurer.id
    }
  end
end
