alias PointQuest.Quests

{:ok, default_quest} =
  Quests.create(%{
    name: "Default Quest",
    party_leader: %{name: "Stevey Beevey"}
  })

{:ok, front_led_quest} =
  Quests.create(%{
    name: "Led from the front",
    party_leader: %{name: "JSON Noonan"},
    lead_from_the_front: true
  })

{:ok, multi_party_quest} =
  Quests.create(%{
    name: "Multi-party Quest",
    party_leader: %{name: "Proto Leilani"},
    lead_from_the_front: true
  })

{:ok, multi_party_quest} =
  Quests.add_adventurer_to_party(multi_party_quest.id, %{name: "Stevey Beevey", class: :mage})

{:ok, multi_party_quest} =
  Quests.add_adventurer_to_party(multi_party_quest.id, %{name: "JSON Noonan", class: :knight})
