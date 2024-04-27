defprotocol PointQuest.Quests.Objectives.Questable do
  alias PointQuest.Quests.Objectives.Objective

  @spec to_objective(any()) :: Objective.t()
  def to_objective(issue)
end
