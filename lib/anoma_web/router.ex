defmodule AnomaWeb.Router do
  use AnomaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug OpenApiSpex.Plug.PutApiSpec, module: AnomaWeb.ApiSpec
  end

  # Authenticated API pipeline
  pipeline :authenticated_api do
    plug :accepts, ["json"]
    plug AnomaWeb.Plugs.AuthPlug
  end

  scope "/" do
    pipe_through :api
    get "/", AnomaWeb.HomeController, :index

    scope "/openapi" do
      # serve the spec
      get "/", OpenApiSpex.Plug.RenderSpec, []
      # allow openapi to be rendered in the browser
      get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/openapi"
    end
  end

  # unauthenticated api routes
  # /api/v1
  scope "/api/v1", AnomaWeb.Api do
    pipe_through :api
    # authenticate with MetaMask signature
    post "/user/metamask-auth", UserController, :metamask_auth
  end

  # authenticated api routes
  scope "/api/v1", AnomaWeb.Api do
    pipe_through :authenticated_api

    # /api/v1/user
    scope "/user" do
      # get "/daily-points", UserController, :daily_points
      # post "/claim-daily-point", UserController, :claim_point
      get "/", UserController, :profile
    end

    # /api/v1/fitcoin
    scope "/fitcoin" do
      post "/", FitcoinController, :add
      get "/balance", FitcoinController, :balance
    end

    # /api/v1/coupons
    scope "/coupons" do
      get "/", CouponController, :list
      put "/use", CouponController, :use
    end

    # /api/v1/invite
    scope "/invite" do
      get "/", InviteController, :list_invites
      put "/redeem", InviteController, :redeem_invite
    end

    # /api/v1/bet
    scope "/bet" do
      post "/place", BetController, :place
      get "/", BetController, :list
      get "/:id", BetController, :get
    end
  end

  if Mix.env() == :dev do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard"
    end
  end
end
