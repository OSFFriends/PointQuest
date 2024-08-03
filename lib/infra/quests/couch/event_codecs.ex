defimpl CouchDB.Document, for: PointQuest.Quests.Event.QuestStarted do
  def to_codec(%PointQuest.Quests.Event.QuestStarted{}), do: :ecto
end

defimpl CouchDB.Document, for: PointQuest.Quests.Event.AdventurerJoinedParty do
  def to_codec(%PointQuest.Quests.Event.AdventurerJoinedParty{}), do: :ecto
end

defimpl CouchDB.Document, for: PointQuest.Quests.Event.RoundStarted do
  def to_codec(%PointQuest.Quests.Event.RoundStarted{}), do: :ecto
end

defimpl CouchDB.Document, for: PointQuest.Quests.Event.AdventurerAttacked do
  def to_codec(%PointQuest.Quests.Event.AdventurerAttacked{}), do: :ecto
end

defimpl CouchDB.Document, for: PointQuest.Quests.Event.RoundEnded do
  def to_codec(%PointQuest.Quests.Event.RoundEnded{}), do: :ecto
end

defimpl CouchDB.Document, for: PointQuest.Quests.Event.ObjectiveAdded do
  def to_codec(%PointQuest.Quests.Event.ObjectiveAdded{}), do: :ecto
end

defimpl CouchDB.Document, for: PointQuest.Quests.Event.ObjectiveSorted do
  def to_codec(%PointQuest.Quests.Event.ObjectiveSorted{}), do: :ecto
end

defimpl CouchDB.Document, for: PointQuest.Quests.Event.AdventurerRemovedFromParty do
  def to_codec(%PointQuest.Quests.Event.AdventurerRemovedFromParty{}), do: :ecto
end
