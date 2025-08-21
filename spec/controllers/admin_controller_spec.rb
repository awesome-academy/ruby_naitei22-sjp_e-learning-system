context "when a user is not logged in" do
  before do
    session[:user_id] = nil
    get :index
  end

  it "redirects to the login page" do
    expect(response).to redirect_to(login_url)
  end

  it "sets a flash message" do
    expect(flash[:danger]).to eq(I18n.t("flash.please_log_in"))
  end
end
