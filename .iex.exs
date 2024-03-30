alias PointQuest.Quests.Commands

{:ok, jeffs_special_quest_event} =
  Commands.StartQuest.execute(
    Commands.StartQuest.new!(%{
      name: "Just let me have this one"
    })
  )

{:ok, lying_quest_leader_event} =
  Commands.StartQuest.execute(
    Commands.StartQuest.new!(%{
      name: "I'm a filthy",
      party_leaders_adventurer: %{name: "JSON Noonan"}
    })
  )

{:ok, multi_party_quest} =
  Commands.StartQuest.execute(
    Commands.StartQuest.new!(%{
      name: "Multi-party Quest",
      party_leaders_adventurer: %{name: "Proto Leilani"}
    })
  )

{:ok, multi_party_quest_event} =
  Commands.AddAdventurer.execute(
    Commands.AddAdventurer.new!(%{
      quest_id: multi_party_quest.id,
      name: "Stevey Beevey",
      class: :mage
    })
  )

{:ok, multi_party_quest_event} =
  Commands.AddAdventurer.execute(
    Commands.AddAdventurer.new!(%{
      quest_id: multi_party_quest.id,
      name: "JSON Noonan",
      class: :knight
    })
  )
