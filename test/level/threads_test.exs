defmodule Level.ThreadsTest do
  use Level.DataCase

  alias Level.Threads

  describe "create_draft_changeset/1" do
    setup do
      user = %Level.Spaces.User{id: 999}
      space = %Level.Spaces.Space{id: 888}
      {:ok, %{space: space, user: user}}
    end

    test "builds a changeset" do
      changeset = Threads.create_draft_changeset(%{"subject" => "Foo"})
      assert %{subject: "Foo"} == changeset.changes
    end

    test "validates given valid data", %{space: space, user: user} do
      params = valid_draft_params(%{user: user, space: space})
      changeset = Threads.create_draft_changeset(params)
      assert changeset.valid?
    end

    test "allows an empty string body", %{space: space, user: user} do
      params =
        %{user: user, space: space}
        |> valid_draft_params()
        |> Map.put(:body, "")

      changeset = Threads.create_draft_changeset(params)
      assert changeset.valid?
    end

    test "validates required params", %{space: space, user: user} do
      for param <- [:user_id, :space_id, :recipient_ids] do
        params =
          %{user: user, space: space}
          |> valid_draft_params()
          |> Map.put(param, nil)

        changeset = Threads.create_draft_changeset(params)
        refute changeset.valid?
        assert changeset.errors ==
          [{param, {"can't be blank", [validation: :required]}}]
      end
    end

    test "requires subject be under 255 chars", %{space: space, user: user} do
      params =
        %{user: user, space: space}
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

    test "inserts a draft if valid", space_and_user do
      params =
        space_and_user
        |> valid_draft_params()

      changeset = Threads.create_draft_changeset(params)
      {:ok, draft} = Threads.create_draft(changeset)
      assert draft.subject == params.subject
    end

    test "returns error tuple if not valid", space_and_user do
      params =
        space_and_user
        |> valid_draft_params()
        |> Map.put(:subject, String.duplicate("a", 256))

      changeset = Threads.create_draft_changeset(params)
      assert {:error, _} = Threads.create_draft(changeset)
    end
  end

  describe "get_draft/1" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup()
      {:ok, draft} = insert_draft(space, user)
      {:ok, %{draft: draft}}
    end

    test "returns the draft if found", %{draft: draft} do
      assert Threads.get_draft(draft.id).id == draft.id
    end

    test "handles when the draft is not found" do
      assert Threads.get_draft(999) == nil
    end
  end

  describe "get_draft_for_user/1" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup()
      {:ok, draft} = insert_draft(space, user)
      {:ok, %{user: user, draft: draft}}
    end

    test "returns the draft if found", %{user: user, draft: draft} do
      assert Threads.get_draft_for_user(user, draft.id).id == draft.id
    end

    test "handles when the draft does not belong to the user", %{draft: draft} do
      assert Threads.get_draft_for_user(%Level.Spaces.User{id: 999}, draft.id) == nil
    end

    test "handles when the draft is not found", %{user: user} do
      assert Threads.get_draft_for_user(user, 999) == nil
    end
  end

  describe "update_draft_changeset/1" do
    setup do
      draft = %Threads.Draft{id: 999}
      {:ok, %{draft: draft}}
    end

    test "builds a changeset", %{draft: draft} do
      changeset = Threads.update_draft_changeset(draft, %{subject: "Foo"})
      assert %{subject: "Foo"} == changeset.changes
      assert changeset.data == draft
    end

    test "validates given valid data", %{draft: draft} do
      changeset = Threads.update_draft_changeset(draft, %{subject: "I'm valid"})
      assert changeset.valid?
    end

    test "allows an empty string body", %{draft: draft} do
      changeset = Threads.update_draft_changeset(draft, %{body: ""})
      assert changeset.valid?
    end

    test "requires subject be under 255 chars", %{draft: draft} do
      subject = String.duplicate("a", 256)
      changeset = Threads.update_draft_changeset(draft, %{subject: subject})
      refute changeset.valid?
      assert changeset.errors ==
        [subject: {"should be at most %{count} character(s)",
          [count: 255, validation: :length, max: 255]}]
    end
  end

  describe "update_draft/1" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup()
      {:ok, draft} = insert_draft(space, user)
      {:ok, %{user: user, draft: draft}}
    end

    test "updates a draft if valid", %{draft: draft} do
      changeset = Threads.update_draft_changeset(draft, %{subject: "The new subject!"})
      {:ok, draft} = Threads.update_draft(changeset)
      assert draft.subject == "The new subject!"
    end

    test "does not update if invalid", %{draft: draft} do
      changeset = Threads.update_draft_changeset(draft, %{subject: String.duplicate("a", 256)})
      {:error, changeset} = Threads.update_draft(changeset)
      assert changeset.errors ==
        [subject: {"should be at most %{count} character(s)",
          [count: 255, validation: :length, max: 255]}]
    end
  end

  describe "update_draft/2" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup()
      {:ok, draft} = insert_draft(space, user)
      {:ok, %{user: user, draft: draft}}
    end

    test "updates a draft if valid", %{draft: draft} do
      {:ok, draft} = Threads.update_draft(draft, %{subject: "The new subject!"})
      assert draft.subject == "The new subject!"
    end

    test "does not update if invalid", %{draft: draft} do
      {:error, changeset} =
        Threads.update_draft(draft, %{subject: String.duplicate("a", 256)})

      assert changeset.errors ==
        [subject: {"should be at most %{count} character(s)",
          [count: 255, validation: :length, max: 255]}]
    end
  end

  describe "get_recipient_id/1" do
    test "generates the ID for users" do
      user = %Level.Spaces.User{id: 999}
      assert Threads.get_recipient_id(user) == "u:999"
    end
  end
end
