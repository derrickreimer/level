defmodule Level.Spaces.CreateSpace do
  @moduledoc false

  alias Ecto.Multi
  alias Level.Billing
  alias Level.Events
  alias Level.Groups
  alias Level.Levelbot
  alias Level.Postbot
  alias Level.Repo
  alias Level.Schemas.Group
  alias Level.Schemas.OpenInvitation
  alias Level.Schemas.Org
  alias Level.Schemas.OrgUser
  alias Level.Schemas.Space
  alias Level.Schemas.SpaceBot
  alias Level.Schemas.SpaceUser
  alias Level.Spaces
  alias Level.Users

  @typedoc "The data returned in a successful result"
  @type success_data :: %{
          org: Org.t(),
          org_user: OrgUser.t(),
          space: Space.t(),
          space_user: SpaceUser.t(),
          open_invitation: OpenInvitation.t(),
          levelbot: SpaceBot.t(),
          postbot: SpaceBot.t(),
          default_group: Group.t()
        }

  @typedoc "The result of creating a space"
  @type result :: {:ok, success_data()} | {:error, atom(), any(), %{optional(atom()) => any()}}

  @billing_config Application.get_env(:level, Level.Billing)

  @spec perform(User.t(), map(), list()) :: result()
  def perform(user, params, opts \\ []) do
    Multi.new()
    |> create_org_if_applicable(user, params, opts)
    |> Multi.run(:space, insert_space(params))
    |> Multi.run(:levelbot, fn %{space: space} -> Levelbot.install_bot(space) end)
    |> Multi.run(:postbot, fn %{space: space} -> Postbot.install_bot(space) end)
    |> Multi.run(:open_invitation, fn %{space: space} -> Spaces.create_open_invitation(space) end)
    |> Repo.transaction()
    |> after_transaction(user, opts)
  end

  defp create_org_if_applicable(multi, _user, %{is_demo: true}, _opts), do: multi

  defp create_org_if_applicable(multi, user, params, opts) do
    multi
    |> Multi.run(:org, fn _ -> insert_org(user, params, opts) end)
    |> Multi.run(:org_user, fn %{org: org} -> insert_org_owner(org, user) end)
  end

  defp insert_org(user, params, opts) do
    %Org{}
    |> Org.create_changeset(%{name: params.name, seat_quantity: 1})
    |> do_insert_org(user, opts)
  end

  defp do_insert_org(%Ecto.Changeset{valid?: true} = changeset, user, opts) do
    billing_enabled = Keyword.get(opts, :billing_enabled) || @billing_config[:enabled]
    plan_id = Keyword.get(opts, :billing_plan_id) || @billing_config[:plan_id]

    if billing_enabled do
      with {:ok, %{"id" => customer_id}} <- Billing.create_customer(user.email),
           {:ok, %{"id" => subscription_id, "status" => subscription_state}} <-
             Billing.create_subscription(customer_id, plan_id, 1) do
        changeset
        |> Ecto.Changeset.put_change(:subscription_state, String.upcase(subscription_state))
        |> Ecto.Changeset.put_change(:stripe_customer_id, customer_id)
        |> Ecto.Changeset.put_change(:stripe_subscription_id, subscription_id)
        |> Repo.insert()
      else
        _ ->
          {:error, nil}
      end
    else
      Repo.insert(changeset)
    end
  end

  defp do_insert_org(changeset, _, _) do
    {:error, changeset}
  end

  defp insert_org_owner(org, user) do
    %OrgUser{}
    |> Ecto.Changeset.change(org_id: org.id, user_id: user.id, role: "OWNER")
    |> Repo.insert()
  end

  defp insert_space(params) do
    fn
      %{org: org} ->
        %Space{}
        |> Space.create_changeset(Map.put(params, :org_id, org.id))
        |> Repo.insert()

      _ ->
        %Space{}
        |> Space.create_changeset(params)
        |> Repo.insert()
    end
  end

  defp after_transaction({:ok, %{space: space} = data}, user, opts) do
    {:ok, owner} = Spaces.create_owner(user, space, opts)
    {:ok, default_group} = create_everyone_group(owner)
    Events.space_joined(user.id, space, owner)

    if !space.is_demo do
      Users.track_analytics_event(user, "Created a team", %{
        team_id: space.id,
        team_name: space.name,
        team_slug: space.slug
      })
    end

    {:ok, Map.merge(data, %{space_user: owner, default_group: default_group})}
  end

  defp after_transaction(err, _, _), do: err

  defp create_everyone_group(space_user) do
    case Groups.create_group(space_user, %{name: "everyone", is_default: true}) do
      {:ok, %{group: group}} ->
        {:ok, group}

      err ->
        err
    end
  end
end
