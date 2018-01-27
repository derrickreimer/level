defmodule Level.SpacesTest do
  use Level.DataCase
  use Bamboo.Test

  alias Level.Spaces
  alias Level.Rooms

  describe "get_space_by_slug(!)/1" do
    setup do
      insert_signup()
    end

    test "returns the space if found", %{space: space} do
      assert Spaces.get_space_by_slug(space.slug).id == space.id
      assert Spaces.get_space_by_slug!(space.slug).id == space.id
    end

    test "handles when the space is not found" do
      assert Spaces.get_space_by_slug("doesnotexist") == nil

      assert_raise(Ecto.NoResultsError, fn ->
        Spaces.get_space_by_slug!("doesnotexist")
      end)
    end
  end

  describe "get_user/1" do
    setup do
      insert_signup()
    end

    test "returns the user if found", %{user: user} do
      assert Spaces.get_user(user.id).id == user.id
    end

    test "handles when the user is not found" do
      assert Spaces.get_user(99_999) == nil
    end
  end

  describe "get_user_by_identifier/1" do
    setup do
      insert_signup()
    end

    test "looks up user by email address", %{space: space, user: user} do
      assert Spaces.get_user_by_identifier(space, user.email).id == user.id
    end

    test "looks up user by username", %{space: space, user: user} do
      assert Spaces.get_user_by_identifier(space, user.username).id == user.id
    end

    test "handles when the user is not found", %{space: space} do
      assert Spaces.get_user_by_identifier(space, "doesnotexist") == nil
    end
  end

  describe "register/1" do
    setup do
      params = valid_signup_params()
      changeset = Spaces.registration_changeset(%{}, params)
      {:ok, %{changeset: changeset}}
    end

    test "inserts a new user", %{changeset: changeset} do
      {:ok, %{user: user}} = Spaces.register(changeset)
      assert user.email == changeset.changes.email
      assert user.role == "OWNER"
    end

    test "inserts a new space", %{changeset: changeset} do
      {:ok, %{user: user, space: space}} = Spaces.register(changeset)
      assert space.slug == changeset.changes.slug
      assert user.space_id == space.id
    end

    test "inserts a new 'Everyone' room", %{changeset: changeset} do
      {:ok, %{default_room: %{room: room}, space: space, user: user}} = Spaces.register(changeset)

      assert room.name == "Everyone"
      assert room.space_id == space.id
      assert room.subscriber_policy == "MANDATORY"

      user_with_subscriptions = Repo.preload(user, :room_subscriptions)
      [subscription | _] = user_with_subscriptions.room_subscriptions
      assert subscription.room_id == room.id
    end
  end

  describe "create_invitation/3" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup()
      params = valid_invitation_params()
      {:ok, %{space: space, user: user, params: params}}
    end

    test "sends an invitation email", %{user: user, params: params} do
      {:ok, invitation} = Spaces.create_invitation(user, params)
      assert_delivered_email LevelWeb.Email.invitation_email(invitation)
    end

    test "returns error when params are invalid", %{user: user, params: params} do
      params = Map.put(params, :email, "invalid")
      {:error, error_changeset} = Spaces.create_invitation(user, params)
      assert {:email, {"is invalid", validation: :format}}
        in error_changeset.errors
    end
  end

  describe "get_pending_invitation!/2" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup()
      params = valid_invitation_params()
      {:ok, invitation} = Spaces.create_invitation(user, params)
      {:ok, %{space: space, invitation: invitation}}
    end

    test "returns pending invitation with a matching token",
      %{invitation: invitation, space: space} do
      assert Spaces.get_pending_invitation!(space, invitation.token).id ==
        invitation.id
    end

    test "raises a not found error if invitation is already accepted",
      %{invitation: invitation, space: space} do

      invitation
      |> Ecto.Changeset.change(state: "ACCEPTED")
      |> Repo.update()

      assert_raise(Ecto.NoResultsError, fn ->
        Spaces.get_pending_invitation!(space, invitation.token)
      end)
    end
  end

  describe "get_pending_invitation/2" do
    setup do
      {:ok, %{space: space, user: user}} = insert_signup()
      params = valid_invitation_params()
      {:ok, invitation} = Spaces.create_invitation(user, params)
      {:ok, %{space: space, invitation: invitation}}
    end

    test "returns pending invitation with a matching id",
      %{invitation: invitation, space: space} do
      assert Spaces.get_pending_invitation(space, invitation.id).id ==
        invitation.id
    end

    test "returns nil if invitation is already accepted",
      %{invitation: invitation, space: space} do

      invitation
      |> Ecto.Changeset.change(state: "ACCEPTED")
      |> Repo.update()

      assert Spaces.get_pending_invitation(space, invitation.id) == nil
    end

    test "returns nil if invitation does not exist", %{space: space} do
      assert Spaces.get_pending_invitation(space, "99999") == nil
    end
  end

  describe "accept_invitation/2" do
    setup do
      {:ok, %{
        user: invitor,
        default_room: %{room: room}
      }} = insert_signup()

      params = valid_invitation_params()
      {:ok, invitation} = Spaces.create_invitation(invitor, params)

      {:ok, %{invitation: invitation, default_room: room}}
    end

    test "creates a user and flag invitation as accepted",
      %{invitation: invitation} do
      params = valid_user_params()

      {:ok, %{user: user, invitation: invitation}} =
        Spaces.accept_invitation(invitation, params)

      assert user.email == params.email
      assert invitation.state == "ACCEPTED"
      assert invitation.acceptor_id == user.id
    end

    test "subscribes the user to all mandatory rooms",
      %{invitation: invitation, default_room: room} do
      params = valid_user_params()

      {:ok, %{user: user}} =
        Spaces.accept_invitation(invitation, params)

      assert {:ok, _} = Rooms.get_room_subscription(room, user)
    end

    test "handles invalid params", %{invitation: invitation} do
      params =
        valid_user_params()
        |> Map.put(:username, "i am not valid")

      {:error, failed_operation, _, _} =
        Spaces.accept_invitation(invitation, params)

      assert failed_operation == :user
    end
  end
end
