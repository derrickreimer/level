defmodule Level.Groups.CreateInvitations do
  @moduledoc false

  alias Level.Levelbot
  alias Level.Posts
  alias Level.Repo
  alias Level.Schemas.GroupInvitation
  alias Level.Schemas.SpaceUser

  def perform(group, invitor, invitees) do
    invitees
    |> Enum.map(fn invitee -> create_invitation(group, invitor, invitee) end)
    |> Enum.reject(&is_nil/1)
    |> to_ok_tuple()
  end

  defp create_invitation(group, invitor, invitee) do
    case insert_record(group, invitor, invitee) do
      {:ok, invitation} ->
        _ = send_message(group, invitor, invitee, invitation)
        invitation

      _ ->
        nil
    end
  end

  defp insert_record(group, invitor, invitee) do
    params = %{
      space_id: invitor.space_id,
      group_id: group.id,
      invitee_id: invitee.id,
      invitor_id: invitor.id
    }

    %GroupInvitation{}
    |> GroupInvitation.create_changeset(params)
    |> Repo.insert()
  end

  defp send_message(group, invitor, invitee, _invitation) do
    levelbot = Levelbot.get_space_bot!(invitee)

    body = """
    #{SpaceUser.display_name(invitor)} invited you to join the #{group.name} group.
    """

    Posts.create_post(levelbot, invitee, %{body: body})
  end

  defp to_ok_tuple(value), do: {:ok, value}
end
