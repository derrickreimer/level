defmodule Bridge.ThreadsTest do
  use Bridge.DataCase

  alias Bridge.Threads

  describe "create_draft_changeset/1" do
    setup do
      user = %Bridge.Teams.User{id: 999}
      team = %Bridge.Teams.Team{id: 888}
      {:ok, %{team: team, user: user}}
    end

    test "builds a changeset" do
      changeset = Threads.create_draft_changeset(%{"subject" => "Foo"})
      assert %{subject: "Foo"} == changeset.changes
    end

    test "validates given valid data", %{team: team, user: user} do
      params = valid_draft_params(%{user: user, team: team})
      changeset = Threads.create_draft_changeset(params)
      assert changeset.valid?
    end

    test "allows an empty string body", %{team: team, user: user} do
      params =
        %{user: user, team: team}
        |> valid_draft_params()
        |> Map.put(:body, "")

      changeset = Threads.create_draft_changeset(params)
      assert changeset.valid?
    end

    test "validates required params", %{team: team, user: user} do
      for param <- [:user_id, :team_id, :recipient_ids] do
        params =
          %{user: user, team: team}
          |> valid_draft_params()
          |> Map.put(param, nil)

        changeset = Threads.create_draft_changeset(params)
        refute changeset.valid?
        assert changeset.errors ==
          [{param, {"can't be blank", [validation: :required]}}]
      end
    end

    test "requires subject be under 255 chars", %{team: team, user: user} do
      params =
        %{user: user, team: team}
        |> valid_draft_params()
        |> Map.put(:subject, String.duplicate("a", 256))

      changeset = Threads.create_draft_changeset(params)
      refute changeset.valid?
      assert changeset.errors ==
        [subject: {"should be at most %{count} character(s)",
          [count: 255, validation: :length, max: 255]}]
    end
  end

  describe "create_draft/1" do
    setup do
      insert_signup()
    end

    test "inserts a draft if valid", team_and_user do
      params =
        team_and_user
        |> valid_draft_params()

      changeset = Threads.create_draft_changeset(params)
      {:ok, draft} = Threads.create_draft(changeset)
      assert draft.subject == params.subject
    end

    test "returns error tuple if not valid", team_and_user do
      params =
        team_and_user
        |> valid_draft_params()
        |> Map.put(:subject, String.duplicate("a", 256))

      changeset = Threads.create_draft_changeset(params)
      assert {:error, _} = Threads.create_draft(changeset)
    end
  end
end
