require "test_helper"

class Api::Internal::RevocationsNormalControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @api_key = ApiKey.create!(user: @user, name: "test key")
    ENV["HKA_REVOCATION_KEY"] = "test_rev_key"
  end

  test "revokes normal api key by rotating token" do
    old_token = @api_key.token
    post "/api/internal/revoke_normal", params: { token: old_token }, headers: { "Authorization" => "Token test_rev_key" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_nil ApiKey.find_by(token: old_token)
  end

  test "returns failure when api key not found" do
    post "/api/internal/revoke_normal", params: { token: "nope" }, headers: { "Authorization" => "Token test_rev_key" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
  end
end
