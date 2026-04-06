require "test_helper"

class TranscribeControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get transcribe_create_url
    assert_response :success
  end
end
