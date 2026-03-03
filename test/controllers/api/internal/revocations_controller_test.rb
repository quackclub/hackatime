require "test_helper"

class Api::Internal::RevocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @admin_key = AdminApiKey.create!(user: @user, name: "admin key")
    ENV["HKA_REVOCATION_KEY"] = "test_rev_key"
  end

  test "revokes admin api key with valid token" do
    post "/api/internal/revoke", params: { token: @admin_key.token }, headers: { "Authorization" => "Token test_rev_key" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    @admin_key.reload
    assert_not_nil @admin_key.revoked_at
  end

  test "returns failure when admin key not found" do
    post "/api/internal/revoke", params: { token: "nope" }, headers: { "Authorization" => "Token test_rev_key" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
  end
end
