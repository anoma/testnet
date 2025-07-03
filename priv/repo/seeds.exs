# ----------------------------------------------------------------------------
# Parameters

users = 1
invites = 5
coupons = 5

# ----------------------------------------------------------------------------
# Generator Functions

generate_user = fn ->
  {:ok, user} =
    Anoma.Accounts.create_user(%{points: 1_000_000, fitcoins: 1_000_000})

  user
end

generate_coupon = fn user ->
  {:ok, coupon} =
    Anoma.Garapon.create_coupon(%{
      owner_id: user.id,
      used: false
    })

  coupon
end

generate_invite = fn user ->
  code = Base.encode16(:crypto.strong_rand_bytes(8))
  {:ok, _invite} = Anoma.Invites.create_invite(%{owner_id: user.id, code: code})
end

# ----------------------------------------------------------------------------
# Generate

if Mix.env() == :dev do
  # generate users
  users = for _ <- 1..users, do: generate_user.()

  # generate coupons for all users
  for user <- users do
    for _ <- 1..coupons do
      generate_coupon.(user)
    end
  end

  # generate invites for all users
  for user <- users do
    for _ <- 1..invites do
      generate_invite.(user)
    end
  end
end
