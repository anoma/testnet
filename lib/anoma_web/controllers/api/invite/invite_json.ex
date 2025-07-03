defmodule AnomaWeb.Api.InviteJSON do
  @doc """
  Success after redeeming an invite.
  """
  def redeem_invite(_) do
    %{}
  end

  @doc """
  Renders a list of invites.
  """
  def list_invites(%{invites: invites}) do
    %{invites: for(invite <- invites, do: invite(invite))}
  end

  @doc """
  Renders a single invite.
  """
  def invite(%{invite: invite}) do
    invite
  end

  def invite(invite) do
    invite
  end

  def tree(%{tree: {id, subtrees}}) do
    %{user_id: id, tree: for(subtree <- subtrees, do: tree(%{tree: subtree}))}
  end
end
