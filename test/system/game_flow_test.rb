require "application_system_test_case"

class GameFlowTest < ApplicationSystemTestCase
  test "visiting the home page" do
    visit root_url
    assert_selector "h1", text: "اذكرو"
    assert_selector "#start", text: "Start Round"
  end
end
