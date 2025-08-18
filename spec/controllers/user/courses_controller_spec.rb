let!(:admin) { create(:user, role: "admin") }
let!(:regular_user) { create(:user, role: "user") }

context "when current user is not a regular user" do
  before do
    session[:user_id] = admin.id
    get :index
  end

  it "redirects to the root path" do
    expect(response).to redirect_to(root_path)
  end

  it "sets a flash message" do
    expect(flash[:danger]).to eq(I18n.t("flash.not_authenticated"))
  end
end
