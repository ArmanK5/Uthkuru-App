require "test_helper"

class GameControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get root_url
    assert_response :success
  end

  test "should create round" do
    post "/round"
    assert_response :success
  end
end