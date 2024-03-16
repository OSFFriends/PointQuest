alias PointQuest.Quests

{:ok, jeffs_special_quest} =
  Quests.StartQuest.execute(
    Quests.StartQuest.new!(%{
      name: "Default Quest"
    })
  )

{:ok, lying_quest_leader} =
  Quests.StartQuest.execute(
    Quests.StartQuest.new!(%{
      name: "I'm a filthy",
      party_leaders_adventurer: %{name: "JSON Noonan"}
    })
  )

{:ok, multi_party_quest} =
  Quests.StartQuest.execute(
    Quests.StartQuest.new!(%{
      name: "Multi-party Quest",
      party_leaders_adventurer: %{name: "Proto Leilani"}
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
