defmodule PointQuest.Authentication do
  @moduledoc """
  Handles decoding and encoding session tokens and authentication behaviors
  """

  alias PointQuest.Authentication.Actor
  alias PointQuest.Error
  alias PointQuest.Quests
  alias PointQuest.Quests.Commands

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
        adventurer: Ecto.embedded_dump(leader.adventurer, :json)
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

  @spec token_to_actor(token()) ::
          {:ok, Actor.t()} | {:error, :expired | :invalid | :missing | :stale_quest}
  def token_to_actor(token) do
    with {:ok, serializable} <- Phoenix.Token.verify(PointQuestWeb.Endpoint, @salt, token) do
      to_actor(serializable)
    end
  end

  def to_actor(%{type: :adventurer, quest_id: _quest_id, adventurer_id: _adventurer_id} = token) do
    get_adventurer = Commands.GetAdventurer.new!(token)

    case Commands.GetAdventurer.execute(get_adventurer) do
      {:ok, adventurer} -> {:ok, PointQuest.Authentication.create_actor(adventurer)}
      {:error, %Error.NotFound{resource: :quest}} -> {:error, :stale_quest}
    end
  end

  def to_actor(%{type: :party_leader, quest_id: _quest_id, adventurer_id: _adventurer_id} = token) do
    get_leader = Commands.GetPartyLeader.new!(token)

    case Commands.GetPartyLeader.execute(get_leader) do
      {:ok, leader} -> {:ok, PointQuest.Authentication.create_actor(leader)}
      {:error, %Error.NotFound{resource: :quest}} -> {:error, :stale_quest}
    end
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
