alias PointQuest.Quests

{:ok, default_quest} =
  Quests.StartQuest.execute(
    Quests.StartQuest.new!(%{
      name: "Default Quest",
      party_leader: %{name: "Stevey Beevey"}
    })
  )

{:ok, lying_quest_leader} =
  Quests.StartQuest.execute(
    Quests.StartQuest.new!(%{
      name: "I'm a filthy",
      party_leader: %{name: "JSON Noonan"}
    })
  )

{:ok, multi_party_quest} =
  Quests.StartQuest.execute(
    Quests.StartQuest.new!(%{
      name: "Multi-party Quest",
      party_leader: %{name: "Proto Leilani"},
      lead_from_the_front: true
    })
  )

{:ok, multi_party_quest} =
  Quests.AddAdventurer.execute(
    Quests.AddAdventurer.new!(%{
      quest_id: multi_party_quest.id,
      name: "Stevey Beevey",
      class: :mage
    })
  )

{:ok, multi_party_quest} =
  Quests.AddAdventurer.execute(
    Quests.AddAdventurer.new!(%{
      quest_id: multi_party_quest.id,
      name: "JSON Noonan",
      class: :knight
    })
  )
